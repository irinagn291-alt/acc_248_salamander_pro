import SwiftUI

/// Role: Pass. Three to four pages. Skip writes the completion flag. Continue is bottom and full width. Re-runnable from Settings.
struct OnboardingView: View {
    @Environment(PassDesk.self) private var desk
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [(art: String, headline: String, line: String)] = [
        (
            "slm_Onboarding1",
            "Tonight's ticket",
            "Numbered fire walks stay on the counter. This is a kitchen pass, not a recipe blog."
        ),
        (
            "slm_Onboarding2",
            "Walk the fire",
            "Tap the next walk on the open ticket. Retract peels a tap that was wrong."
        ),
        (
            "slm_Onboarding3",
            "Plate the dish",
            "The last walk writes a service mark. The ticket leaves the pass and sleep returns."
        ),
        (
            "slm_TwistHero",
            "Mise, then fire",
            "Bowls file first. The last bowl lights the iron and holds idle sleep until the last walk."
        ),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(pages[page].headline)
                .font(PassType.font(.display, size: typeSize))
                .foregroundStyle(PassInk.ink)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PassSpace.outer)
                .padding(.top, PassSpace.outer)
            Text(pages[page].line)
                .font(PassType.font(.body, size: typeSize))
                .foregroundStyle(PassInk.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, PassSpace.outer)
                .padding(.top, PassSpace.inner)

            Image(pages[page].art)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(PassSpace.outer)
                .accessibilityHidden(true)

            HStack(spacing: PassSpace.inner) {
                ForEach(pages.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: PassRadius.chip, style: .continuous)
                        .fill(index == page ? PassInk.accent : PassInk.muted)
                        .frame(
                            width: index == page ? PassSpace.step(3) : PassSpace.unit,
                            height: PassSpace.unit
                        )
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, PassSpace.card)
            .frame(maxWidth: .infinity)

            Button(page >= pages.count - 1 ? "Continue" : "Next") {
                advance()
            }
            .buttonStyle(PassFireStyle())
            .padding(.horizontal, PassSpace.outer)

            Button("Skip") {
                Task { await desk.finishOnboarding() }
            }
            .buttonStyle(PassQuietStyle())
            .padding(.horizontal, PassSpace.outer)
            .padding(.top, PassSpace.inner)
            .padding(.bottom, PassSpace.outer)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PassInk.background.ignoresSafeArea())
        .animation(PassMotion.crossfade(reduceMotion), value: page)
        .preferredColorScheme(.dark)
    }

    private func advance() {
        if page >= pages.count - 1 {
            Task { await desk.finishOnboarding() }
        } else {
            page += 1
        }
    }
}
