import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var flow: AppFlow

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "film.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.accent)
                Text("Bingewise")
                    .font(AppTheme.display(32))
                    .foregroundStyle(AppTheme.label)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                flow.advanceFromSplash()
            }
        }
    }
}
