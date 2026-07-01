import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var flow: AppFlow

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            switch flow.scene {
            case .splash:      SplashView()
            case .onboarding:  OnboardingView()
            case .main:        RootShell()
            }
        }
        .tint(AppTheme.accent)
    }
}
