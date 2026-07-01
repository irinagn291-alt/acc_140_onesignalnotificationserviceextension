import SwiftUI

private struct OnboardingSlide: Identifiable {
    let id = UUID()
    let icon: String
    let headline: String
    let body: String
}

struct OnboardingView: View {
    @EnvironmentObject private var flow: AppFlow
    @State private var current = 0

    private let slides: [OnboardingSlide] = [
        OnboardingSlide(icon: "sparkles", headline: "Discover your next binge", body: "Search millions of shows and films ready to watch right now."),
        OnboardingSlide(icon: "tray.fill", headline: "Stash it for later", body: "Never lose track of a title again. One tap and it’s saved."),
        OnboardingSlide(icon: "tv.fill", headline: "Log what you’ve binged", body: "Mark episodes, rate seasons and keep your streak alive."),
    ]

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $current) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { i, slide in
                        slidePanel(slide).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: current)

                pageIndicator
                    .padding(.bottom, 20)

                ctaArea
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    private func slidePanel(_ slide: OnboardingSlide) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: slide.icon)
                .font(.system(size: 72))
                .foregroundStyle(AppTheme.accent)
            VStack(spacing: 12) {
                Text(slide.headline)
                    .font(AppTheme.display(26))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.label)
                Text(slide.body)
                    .font(AppTheme.body(16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.sublabel)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<slides.count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? AppTheme.accent : AppTheme.sublabel.opacity(0.3))
                    .frame(width: i == current ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: current)
            }
        }
    }

    @ViewBuilder
    private var ctaArea: some View {
        if current == slides.count - 1 {
            Button {
                flow.completeOnboarding()
            } label: {
                Text("Start Binging")
                    .font(AppTheme.heading(17))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.accent, in: Capsule())
            }
        } else {
            HStack {
                Button("Skip") { flow.completeOnboarding() }
                    .font(AppTheme.body(15))
                    .foregroundStyle(AppTheme.sublabel)
                Spacer()
                Button {
                    withAnimation { current += 1 }
                } label: {
                    Text("Next")
                        .font(AppTheme.heading(15))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppTheme.surface, in: Capsule())
                        .overlay(Capsule().strokeBorder(AppTheme.accent.opacity(0.4), lineWidth: 1))
                }
            }
        }
    }
}
