import SwiftUI

enum AppScene {
    case splash, onboarding, main
}

@MainActor
final class AppFlow: ObservableObject {
    @Published var scene: AppScene = .splash
    @AppStorage("bingewise.onboardingComplete") private var onboardingComplete = false

    func advanceFromSplash() {
        withAnimation(.easeInOut(duration: 0.45)) {
            scene = onboardingComplete ? .main : .onboarding
        }
    }

    func completeOnboarding() {
        onboardingComplete = true
        withAnimation(.easeInOut(duration: 0.45)) { scene = .main }
    }
}
