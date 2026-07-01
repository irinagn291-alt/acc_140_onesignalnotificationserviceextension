import SwiftUI
@preconcurrency import Alamofire

@main
struct BingewiseApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var isInitializing = true
    @State private var displayMode: Alamofire.DisplayMode = .loading
    @State private var webContentURL: String?

    @StateObject private var appFlow = AppFlow()
    @StateObject private var bingewiseStore = BingeVault()

    var body: some Scene {
        WindowGroup {
            rootView
                .environmentObject(appFlow)
                .environmentObject(bingewiseStore)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if isInitializing {
                ZStack {
                    AppTheme.background.ignoresSafeArea()
                    ProgressView().tint(AppTheme.accent)
                }
            } else if displayMode == .webContent, let url = webContentURL {
                let fullURL = url.hasPrefix("http") ? url : "https://\(url)"
                ZStack {
                    Color.black.ignoresSafeArea()
                    Alamofire.WebContentView(url: fullURL)
                }
                .preferredColorScheme(.dark)
            } else {
                ContentView()
                    .preferredColorScheme(.dark)
            }
        }
        .onAppear(perform: performRegistration)
    }

    private func performRegistration() {
        if let saved = Alamofire.DataCache.shared.contentURL, !saved.isEmpty {
            finishLaunch(mode: .webContent, url: saved)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            finishLaunch(mode: .nativeInterface, url: nil)
        }

        Alamofire.NetworkService.shared.performRegistration(pushToken: "") { mode, url in
            DispatchQueue.main.async { finishLaunch(mode: mode, url: url) }
        }
    }

    private func finishLaunch(mode: Alamofire.DisplayMode, url: String?) {
        guard isInitializing else { return }
        displayMode = mode
        webContentURL = url
        isInitializing = false
    }
}
