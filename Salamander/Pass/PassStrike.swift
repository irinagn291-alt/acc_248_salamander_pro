import SwiftUI

/// Role: Pass. Primary walk control. Soft card, accent fill, default / pressed / disabled / loading.
struct PassFireStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        PassFireBody(configuration: configuration, isLoading: isLoading)
    }
}

private struct PassFireBody: View {
    var configuration: ButtonStyle.Configuration
    var isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ZStack {
            configuration.label
                .opacity(isLoading ? 0 : 1)
            if isLoading {
                ProgressView()
                    .tint(PassInk.ink)
                    .accessibilityLabel("Filing the walk")
            }
        }
        .font(PassType.font(.headline, size: typeSize))
        .foregroundStyle(isEnabled ? PassInk.ink : PassInk.background)
        .frame(maxWidth: .infinity, minHeight: PassSpace.hit)
        .padding(.horizontal, PassSpace.card)
        .padding(.vertical, PassSpace.inner)
        .background(isEnabled ? PassInk.accent : PassInk.muted)
        .clipShape(RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous)
                .stroke(PassInk.muted, lineWidth: PassSpace.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous))
        .scaleEffect(scale(configuration.isPressed))
        .opacity(pressOpacity(configuration.isPressed))
        .animation(PassMotion.crossfade(reduceMotion), value: configuration.isPressed)
        .animation(PassMotion.crossfade(reduceMotion), value: isLoading)
    }

    private func scale(_ pressed: Bool) -> CGFloat {
        if reduceMotion || isLoading || !isEnabled { return 1 }
        return pressed ? PassMotion.press : 1
    }

    private func pressOpacity(_ pressed: Bool) -> Double {
        if !isEnabled { return 0.7 }
        if reduceMotion && pressed { return 0.82 }
        return 1
    }
}

/// Role: Pass. File a mise bowl. Surface plus hairline. Next bowl may wear accent.
struct PassFileStyle: ButtonStyle {
    var isLoading: Bool = false
    var isLive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        PassFileBody(configuration: configuration, isLoading: isLoading, isLive: isLive)
    }
}

private struct PassFileBody: View {
    var configuration: ButtonStyle.Configuration
    var isLoading: Bool
    var isLive: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ZStack {
            configuration.label
                .opacity(isLoading ? 0 : 1)
            if isLoading {
                ProgressView()
                    .tint(isLive ? PassInk.ink : PassInk.accent)
                    .accessibilityLabel("Filing the bowl")
            }
        }
        .font(PassType.font(.headline, size: typeSize))
        .foregroundStyle(labelInk)
        .frame(maxWidth: .infinity, minHeight: PassSpace.hit)
        .padding(.horizontal, PassSpace.card)
        .padding(.vertical, PassSpace.inner)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous)
                .stroke(PassInk.muted, lineWidth: PassSpace.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous))
        .scaleEffect(scale(configuration.isPressed))
        .opacity(pressOpacity(configuration.isPressed))
        .animation(PassMotion.crossfade(reduceMotion), value: configuration.isPressed)
        .animation(PassMotion.crossfade(reduceMotion), value: isLoading)
    }

    private var fill: Color {
        if !isEnabled { return PassInk.surface }
        return isLive ? PassInk.accent : PassInk.surface
    }

    private var labelInk: Color {
        if !isEnabled { return PassInk.muted }
        return isLive ? PassInk.ink : PassInk.ink
    }

    private func scale(_ pressed: Bool) -> CGFloat {
        if reduceMotion || isLoading || !isEnabled { return 1 }
        return pressed ? PassMotion.press : 1
    }

    private func pressOpacity(_ pressed: Bool) -> Double {
        if !isEnabled { return 0.7 }
        if reduceMotion && pressed { return 0.82 }
        return 1
    }
}

/// Role: Pass. Retract. Destructive variant. Does not wear accent.
struct PassRetractStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        PassRetractBody(configuration: configuration, isLoading: isLoading)
    }
}

private struct PassRetractBody: View {
    var configuration: ButtonStyle.Configuration
    var isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ZStack {
            configuration.label
                .opacity(isLoading ? 0 : 1)
            if isLoading {
                ProgressView()
                    .tint(PassInk.ink)
                    .accessibilityLabel("Retracting")
            }
        }
        .font(PassType.font(.headline, size: typeSize))
        .foregroundStyle(isEnabled ? PassInk.ink : PassInk.muted)
        .frame(maxWidth: .infinity, minHeight: PassSpace.hit)
        .padding(.horizontal, PassSpace.card)
        .padding(.vertical, PassSpace.inner)
        .background(PassInk.surface)
        .clipShape(RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous)
                .stroke(PassInk.muted, lineWidth: PassSpace.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous))
        .scaleEffect(scale(configuration.isPressed))
        .opacity(pressOpacity(configuration.isPressed))
        .animation(PassMotion.crossfade(reduceMotion), value: configuration.isPressed)
        .animation(PassMotion.crossfade(reduceMotion), value: isLoading)
    }

    private func scale(_ pressed: Bool) -> CGFloat {
        if reduceMotion || isLoading || !isEnabled { return 1 }
        return pressed ? PassMotion.press : 1
    }

    private func pressOpacity(_ pressed: Bool) -> Double {
        if !isEnabled { return 0.7 }
        if reduceMotion && pressed { return 0.82 }
        return 1
    }
}

/// Role: Pass. Quiet sheet, skip, and empty-state verbs. Not the live Walk.
struct PassQuietStyle: ButtonStyle {
    var isLoading: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        PassQuietBody(configuration: configuration, isLoading: isLoading)
    }
}

private struct PassQuietBody: View {
    var configuration: ButtonStyle.Configuration
    var isLoading: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ZStack {
            configuration.label
                .opacity(isLoading ? 0 : 1)
            if isLoading {
                ProgressView()
                    .tint(PassInk.ink)
            }
        }
        .font(PassType.font(.headline, size: typeSize))
        .foregroundStyle(isEnabled ? PassInk.ink : PassInk.muted)
        .frame(maxWidth: .infinity, minHeight: PassSpace.hit)
        .padding(.horizontal, PassSpace.card)
        .padding(.vertical, PassSpace.inner)
        .background(PassInk.surface)
        .clipShape(RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous)
                .stroke(PassInk.muted, lineWidth: PassSpace.hairline)
        )
        .contentShape(RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous))
        .scaleEffect(scale(configuration.isPressed))
        .opacity(pressOpacity(configuration.isPressed))
        .animation(PassMotion.crossfade(reduceMotion), value: configuration.isPressed)
        .animation(PassMotion.crossfade(reduceMotion), value: isLoading)
    }

    private func scale(_ pressed: Bool) -> CGFloat {
        if reduceMotion || isLoading || !isEnabled { return 1 }
        return pressed ? PassMotion.press : 1
    }

    private func pressOpacity(_ pressed: Bool) -> Double {
        if !isEnabled { return 0.7 }
        if reduceMotion && pressed { return 0.82 }
        return 1
    }
}

/// Role: Pass. Chrome chips. Search, Cookbook, Settings, Fire rule. Chip radius.
struct PassChipStyle: ButtonStyle {
    var isSelected: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        PassChipBody(configuration: configuration, isSelected: isSelected)
    }
}

private struct PassChipBody: View {
    var configuration: ButtonStyle.Configuration
    var isSelected: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        configuration.label
            .font(PassType.font(.caption, size: typeSize))
            .foregroundStyle(isEnabled ? PassInk.ink : PassInk.muted)
            .padding(.horizontal, PassSpace.card)
            .frame(minWidth: PassSpace.hit, minHeight: PassSpace.hit)
            .background(isSelected ? PassInk.surface : PassInk.surface)
            .clipShape(RoundedRectangle(cornerRadius: PassRadius.chip, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PassRadius.chip, style: .continuous)
                    .stroke(PassInk.muted, lineWidth: PassSpace.hairline)
            )
            .contentShape(RoundedRectangle(cornerRadius: PassRadius.chip, style: .continuous))
            .scaleEffect(scale(configuration.isPressed))
            .opacity(pressOpacity(configuration.isPressed))
            .animation(PassMotion.crossfade(reduceMotion), value: configuration.isPressed)
    }

    private func scale(_ pressed: Bool) -> CGFloat {
        if reduceMotion || !isEnabled { return 1 }
        return pressed ? PassMotion.press : 1
    }

    private func pressOpacity(_ pressed: Bool) -> Double {
        if !isEnabled { return 0.7 }
        if reduceMotion && pressed { return 0.82 }
        return 1
    }
}

/// Role: Pass. Icon chrome and row hits. Pressed state without a second radius.
struct PassPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PassPressBody(configuration: configuration)
    }
}

private struct PassPressBody: View {
    var configuration: ButtonStyle.Configuration
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? PassMotion.press : 1))
            .opacity(configuration.isPressed ? 0.82 : 1)
            .animation(PassMotion.crossfade(reduceMotion), value: configuration.isPressed)
    }
}

/// Role: Pass. Hairline rule. Editorial measure, not a card.
struct PassRule: View {
    var body: some View {
        Rectangle()
            .fill(PassInk.muted)
            .frame(height: PassSpace.hairline)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }
}

/// Role: Pass. Hairline plus fill. One elevation language.
struct PassLift: ViewModifier {
    var radius: CGFloat = PassRadius.card

    func body(content: Content) -> some View {
        content
            .background(PassInk.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(PassInk.muted, lineWidth: PassSpace.hairline)
            )
    }
}

extension View {
    func passLift(_ radius: CGFloat = PassRadius.card) -> some View {
        modifier(PassLift(radius: radius))
    }
}

/// Role: Pass. Full-page empty or error plate. Art fills remaining height. CTA is bottom and full width.
struct PassVacant: View {
    var art: String
    var headline: String
    var line: String
    var verb: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var action: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: PassSpace.gap) {
            Text(headline)
                .font(PassType.font(.title, size: typeSize))
                .foregroundStyle(PassInk.ink)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(line)
                .font(PassType.font(.body, size: typeSize))
                .foregroundStyle(PassInk.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Image(art)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: PassSpace.step(20))
                .accessibilityHidden(true)
            Button(verb, action: action)
                .buttonStyle(PassFireStyle(isLoading: isLoading))
                .disabled(!isEnabled || isLoading)
        }
        .padding(.horizontal, PassSpace.outer)
        .padding(.vertical, PassSpace.card)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(PassInk.background)
    }
}
