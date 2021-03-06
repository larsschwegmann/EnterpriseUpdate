import Foundation
import SwiftUI

//extension AnyTransition {
//    static var moveAndScale: AnyTransition {
//        let insertion = AnyTransition.move(edge: .top).combined(with: .scale(scale: 1.0))
//        return .asymmetric(insertion: <#T##AnyTransition#>, removal: <#T##AnyTransition#>)
//    }
//}

struct UpdatePromptContainer: View {
    let title: String
    let detailText: String
    let releaseNotes: String?
    let releaseNotesTitle: String
    let updateButtonText: String
    let remindLaterButtonText: String

    var updateNowCallback: (() -> Void)?
    var remindMeLaterCallback: (() -> Void)?

    var body: some View {
        ZStack {
            BlurView(visualEffect: Binding.constant(UIBlurEffect(style: .dark)))
            UpdatePromptCard(title: title,
                             detailText: detailText,
                             releaseNotes: releaseNotes,
                             releaseNotesTitle: releaseNotesTitle,
                             updateButtonText: updateButtonText,
                             remindLaterButtonText: remindLaterButtonText,
                             updateNowCallback: updateNowCallback,
                remindMeLaterCallback: remindMeLaterCallback).shadow(radius: 20)
            }.edgesIgnoringSafeArea(.all)
    }
}

#if DEBUG

struct UpdatePromptContainer_Previews: PreviewProvider {
    static var previews: some View {
        UpdatePromptContainer(title: "Update available",
                              detailText: "Version 2.5.3 of TUMexam is available. You have Version 2.5.2. Would you like to update now?",
                              releaseNotes: "- Bug fixes",
                              releaseNotesTitle: "New in Version 2.5.3:",
                              updateButtonText: "Update now",
                              remindLaterButtonText: "Remind me later")
            .previewLayout(PreviewLayout.sizeThatFits)
    }
}

#endif
