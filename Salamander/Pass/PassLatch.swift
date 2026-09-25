import Foundation

/// Role: Pass. Home, Cookbook, Settings, and Search. Never a three-tab bar. Never a Game destination.
enum PassSurface: String, Equatable, Sendable {
    case home
    case cookbook
    case settings
    case search
}

enum PassSheet: String, Equatable, Sendable, Identifiable {
    case search
    case cookbook
    case settings

    var id: String { rawValue }

    var surface: PassSurface {
        switch self {
        case .search: .search
        case .cookbook: .cookbook
        case .settings: .settings
        }
    }

    static func from(_ surface: PassSurface) -> PassSheet? {
        switch surface {
        case .home: nil
        case .search: .search
        case .cookbook: .cookbook
        case .settings: .settings
        }
    }
}

/// Role: Pass. Launch keys for live shots. today, log, and goals open three different screens.
/// Extra cover slugs (search, cookbook, settings, home, cook) open those screens. Never a Game key.
enum ReviewPane: String, Equatable, Sendable {
    case today
    case log
    case goals
    case search
    case home
    case cookbook
    case settings
    case cook

    var surface: PassSurface {
        switch self {
        case .today, .home, .cook: .home
        case .log, .cookbook: .cookbook
        case .goals, .settings: .settings
        case .search: .search
        }
    }
}

/// Role: Pass. Reads ProcessInfo `-ReviewScreen today|log|goals` once after onboarding, plus extra cover slugs. No View.
enum PassLatch {
    static let flag = "-ReviewScreen"

    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> ReviewPane? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return ReviewPane(rawValue: arguments[next])
    }
}
