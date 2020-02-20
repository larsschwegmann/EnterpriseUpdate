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
                .foregroundColor(.black)


            Text(detailText)
                .font(.body)
                .padding(.bottom)
                .foregroundColor(.black)

            releaseNotes.map({ rl in
                VStack {
                    Text(releaseNotesTitle)
                        .bold()
                        .font(.callout)
                        .padding(.bottom, 5)
                        .foregroundColor(.black)
                    Text(rl)
                        .foregroundColor(.black)
                }
            })

            HStack(spacing: 20) {
                Button(action: {
                    self.remindMeLaterCallback.map({ $0() })
                }) {
                    Text("Remind me Later")
                        .bold()
                }.buttonStyle(PromptButtonStyle(color: Color(UIColor.systemRed))).cornerRadius(10)

                Button(action: {
                    self.updateNowCallback.map({ $0() })
                }) {
                    Text("Update Now")
                        .bold()
                    }.buttonStyle(PromptButtonStyle(color: Color(UIColor.systemBlue))).cornerRadius(10)
            }.padding(.top)

        }
        .padding(.all)
        .frame(maxWidth: 420)
        .background(Color.white)
        .cornerRadius(20)

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

