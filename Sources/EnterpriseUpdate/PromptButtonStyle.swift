import Foundation
import SwiftUI

struct PromptButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaledToFill()
            .padding()
            .background(color)
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)

    }
}
