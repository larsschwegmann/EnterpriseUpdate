import Foundation
import SwiftUI

struct PromptButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(color)
            .cornerRadius(40)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}
