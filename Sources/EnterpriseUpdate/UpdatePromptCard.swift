import SwiftUI
import UIKit

struct UpdatePromptCard: View {
    let title: String
    let detailText: String
    let releaseNotes: String?
    let releaseNotesTitle: String
    let updateButtonText: String
    let remindLaterButtonText: String

    var updateNowCallback: (() -> Void)?
    var remindMeLaterCallback: (() -> Void)?

    var body: some View {
        VStack {
            Text(title)
                .bold()
                .font(.largeTitle)
                .padding(.bottom)


            Text(detailText)
                .font(.body)
                .padding(.bottom)

            releaseNotes.map({ rl in
                VStack {
                    Text(releaseNotesTitle)
                        .bold()
                        .font(.callout)
                        .padding(.bottom, 5)
                    Text(rl)
                }
            })

            HStack(spacing: 20) {
                Button(action: {
                    self.remindMeLaterCallback.map({ $0() })
                }) {
                    Text("Remind me Later")
                        .bold()
                }.buttonStyle(PromptButtonStyle(color: Color(UIColor.systemRed)))

                Button(action: {
                    self.updateNowCallback.map({ $0() })
                }) {
                    Text("Update Now")
                        .bold()
                }.buttonStyle(PromptButtonStyle(color: Color(UIColor.systemBlue)))
            }.padding(.top)

        }
        .padding(.all)
        .frame(maxWidth: 420)
    }
}

#if DEBUG

struct UpdatePromptCard_Previews: PreviewProvider {
    static var previews: some View {
        UpdatePromptCard(title: "Update available",
                         detailText: "Version 2.5.3 of TUMexam is available. You have Version 2.5.2. Would you like to update now?",
                         releaseNotes: "- Bug fixes",
                         releaseNotesTitle: "New in Version 2.5.3:",
                         updateButtonText: "Update now",
                         remindLaterButtonText: "Remind me later")
            .previewLayout(PreviewLayout.sizeThatFits)
    }
}

#endif

