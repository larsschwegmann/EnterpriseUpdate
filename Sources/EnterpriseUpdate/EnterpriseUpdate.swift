import Foundation
import Combine
import UIKit
import SwiftUI
import Version
import os.log

// MARK: - EnterpriseUpdate struct

public class EnterpriseUpdate {

    // MARK: - UpdateError enum

    enum UpdateError: LocalizedError {
        case networkError(urlReponse: URLResponse)
        case httpError(statusCode: Int)

        var localizedDescription: String {
            switch self {
            case .networkError(urlReponse: let resp):
                return "URLResponse was not an HTTP response: \(resp.description)"
            case .httpError(statusCode: let code):
                return "HTTP status code was unacceptable: \(code)"
            }
        }
    }

    // MARK: - Configuration Struct

    public struct Configuration {
        // Basic Config
        /// URL of the Feed that contains the version information
        public let feedURL: URL
        // Decoder to decode the update feed
        public let feedDecoder: JSONDecoder
        /// Time Interval at which automatic checks are performed. Defaults to 1h.
        public var feedUpdateInterval = TimeInterval(60 * 60)
        public var currentVersion = Version(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String) ?? Version(0, 0, 0)


        // UI Settings
        public var alertTitle = "Update available"
        public var alertDetailTextProvider: ((_ oldVersion: Version, _ newVersion: Version, _ displayName: String) -> String) = { (old, new, name) in
            return "Version \(new) of \(name) is available. You have Version \(old). Would you like to update now?"
        }
        public var installUpdateButtonText = "Install Update"
        public var remindLaterButtonText = "Remind me Later"
        public var releaseNotesTitleProvider: ((_ oldVersion: Version, _ newVersion: Version, _ displayName: String) -> String) = { (old, new, name) in
            return "New in Version \(new):"
        }
        public var appDisplayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String

        // MARK: Initializer

        public init(feedURL: URL, decoder: JSONDecoder) {
            self.feedURL = feedURL
            self.feedDecoder = decoder
        }
    }

    // MARK: - FeedItem struct

    struct FeedItem: Decodable, Comparable {
        let title: String
        let version: Version
        let pubDate: String
        let changelog: String
        let manifest: URL
        let deploymentTarget: String

        var deploymentTargetSemantic: Version? {
            return Version(tolerant: self.deploymentTarget)
        }

        static func < (lhs: EnterpriseUpdate.FeedItem, rhs: EnterpriseUpdate.FeedItem) -> Bool {
            return lhs.version < rhs.version
        }
    }

    // MARK: - UserDefaultsKeys struct

    struct UserDefaultsKeys {
        static let lastUpdateCheck = "EnterpriseUpdate.lastUpdateCheck"
    }

    // MARK: - Singleton

    private static var config: Configuration?
    private static var singleton: EnterpriseUpdate?
    public static var shared: EnterpriseUpdate? {
        guard let config = EnterpriseUpdate.config else {
            return nil
        }
        guard let singleton = EnterpriseUpdate.singleton else {
            EnterpriseUpdate.singleton = EnterpriseUpdate(config)
            return EnterpriseUpdate.singleton
        }
        return singleton
    }

    // MARK: - Initializer

    private init(_ config: Configuration) {
        UserDefaults.standard.register(defaults: [UserDefaultsKeys.lastUpdateCheck: Date.init(timeIntervalSinceReferenceDate: 0)])
        self.config = config
    }

    // MARK: - Static Properties

    private static let oslog = OSLog(subsystem: "EnterpriseUpdate", category: "EnterpriseUpdate")

    // MARK: - Properties

    private var updateCancellable: AnyCancellable?
    private var config: Configuration
    private var lastUpdateCheck: Date {
        get {
            return Date(timeIntervalSinceReferenceDate: UserDefaults.standard.double(forKey: UserDefaultsKeys.lastUpdateCheck))
        }
        set {
            UserDefaults.standard.set(newValue.timeIntervalSinceReferenceDate, forKey: UserDefaultsKeys.lastUpdateCheck)
            UserDefaults.standard.synchronize()
        }
    }

    private var timer: Timer?

    // MARK: - Static functions

    public static func setup(_ config: Configuration) {
        EnterpriseUpdate.config = config
        os_log(.info,
               log: EnterpriseUpdate.oslog,
               "EnterpriseUpdate setup!")
    }

    // MARK: - Public functions

    public func checkForUpdates(autoCheck: Bool = true) {
        self.updateCancellable = URLSession.shared.dataTaskPublisher(for: self.config.feedURL)
            .tryMap({ data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw UpdateError.networkError(urlReponse: response)
                }

                guard 200..<300 ~= httpResponse.statusCode else {
                    throw UpdateError.httpError(statusCode: httpResponse.statusCode)
                }
                return data
            })
            .decode(type: [FeedItem].self, decoder: config.feedDecoder)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    os_log(.error,
                           log: EnterpriseUpdate.oslog,
                           "Failed to check for updates, underlying error: %@",
                           error.localizedDescription)
                default:
                    break
                }
            }) { feed in
                self.processFeed(feed, autoCheck: autoCheck)
        }
    }

    public func startAutoUpdateChecks() {
        guard self.timer == nil else {
            return
        }

        let timerBlock: ((Timer?) -> ()) = { _ in
            if self.lastUpdateCheck.addingTimeInterval(self.config.feedUpdateInterval) <= Date() {
                self.checkForUpdates()
                self.lastUpdateCheck = Date()
            }
        }
        self.timer = Timer.scheduledTimer(withTimeInterval: config.feedUpdateInterval, repeats: true, block: timerBlock)
        self.checkForUpdates()
    }

    public func stopAutoUpdateChecks() {
        self.timer?.invalidate()
        self.timer = nil
    }

    // MARK: - Private functions

    private func processFeed(_ feed: [FeedItem], autoCheck: Bool) {
        guard !feed.isEmpty else {
            return
        }

        let latestFeedItem = feed.sorted(by: >).first!
        let currentVersion = config.currentVersion

        guard currentVersion < latestFeedItem.version else {
            os_log(.info,
                   log: EnterpriseUpdate.oslog,
                   "No update found, latest version is %@",
                   latestFeedItem.version.description)
            if !autoCheck {
                // Display alert
                DispatchQueue.main.async {
                    let viewController = UIApplication.topmostViewController()
                    let alert = UIAlertController(title: "No Update available",
                                                  message: "You are already running the newest version of \(self.config.appDisplayName)",
                        preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    viewController?.present(alert, animated: true, completion: nil)
                }
            }
            return
        }

        // Application is outdated, prompt to install new version

        let systemVersion = Version(UIDevice.current.systemVersion) ?? Version(13, 0, 0)
        guard let target = latestFeedItem.deploymentTargetSemantic, systemVersion >= target else {
            os_log(.info,
                   log: EnterpriseUpdate.oslog,
                   "Update found, but required system version is %@ and we are running %@. Aborting.",
                   latestFeedItem.deploymentTarget,
                   systemVersion.description)
            return
        }

        os_log(.info,
               log: EnterpriseUpdate.oslog,
               "Update found! New Version is %@, current version is %@, prompting update!",
               latestFeedItem.version.description,
               currentVersion.description)

        DispatchQueue.main.async {
            let config = self.config
            let viewController = UIApplication.topmostViewController()
            let prompt = UpdatePromptContainer(title: config.alertTitle,
                                               detailText: config.alertDetailTextProvider(currentVersion, latestFeedItem.version, config.appDisplayName),
                                               releaseNotes: latestFeedItem.changelog,
                                               releaseNotesTitle: config.releaseNotesTitleProvider(currentVersion, latestFeedItem.version, config.appDisplayName),
                                               updateButtonText: config.installUpdateButtonText,
                                               remindLaterButtonText: config.remindLaterButtonText,
                                               updateNowCallback: {
                                                UIApplication.shared.open(latestFeedItem.manifest)
            }) {
                viewController?.dismiss(animated: true, completion: nil)
            }

            let host = UIHostingController(rootView: prompt)
            host.modalTransitionStyle = .crossDissolve
            host.view.backgroundColor = .clear
            host.modalPresentationStyle = .overFullScreen
            viewController?.present(host, animated: true, completion: nil)
        }
    }
}

// MARK: - UIApplication Extension

fileprivate extension UIApplication {
    private static let window = Array(UIApplication.shared.connectedScenes)
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: { $0.isKeyWindow })

    class func topmostViewController(controller: UIViewController? = window?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topmostViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topmostViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topmostViewController(controller: presented)
        }
        return controller
    }
}
