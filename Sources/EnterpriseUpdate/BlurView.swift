import SwiftUI
import UIKit

struct BlurView: UIViewRepresentable {
    @Binding var visualEffect: UIVisualEffect

    func makeUIView(context: UIViewRepresentableContext<BlurView>) -> UIVisualEffectView {
        return UIVisualEffectView(effect: nil)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<BlurView>) {
        uiView.effect = visualEffect
    }
}
