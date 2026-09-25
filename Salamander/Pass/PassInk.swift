import SwiftUI

/// Role: Pass. One colour accessor. Hex lives only here: #1F1415 #2B1C1D #F2EDEE #E45864 #AC9193.
enum PassInk {
    enum Hex {
        static let background = "#1F1415"
        static let surface = "#2B1C1D"
        static let ink = "#F2EDEE"
        static let accent = "#E45864"
        static let muted = "#AC9193"
    }

    static var background: Color { Color("background") }
    static var surface: Color { Color("surface") }
    static var ink: Color { Color("ink") }
    static var accent: Color { Color("passAccent") }
    static var muted: Color { Color("muted") }
}

/// Role: Pass. SF Pro via Font.system. Six steps: display, title, headline, body, caption, micro. Display drops a step at AX5. Never below 12pt.
enum PassType {
    static let face = "SF Pro"

    enum Step: CaseIterable {
        case display
        case title
        case headline
        case body
        case caption
        case micro
    }

    static func font(_ step: Step, size: DynamicTypeSize = .large) -> Font {
        switch step {
        case .display:
            if size >= .accessibility3 {
                return .system(.title2, design: .default).weight(.heavy)
            }
            return .system(.title, design: .default).weight(.heavy)
        case .title:
            return .system(.title3, design: .default).weight(.semibold)
        case .headline:
            return .system(.headline, design: .default).weight(.semibold)
        case .body:
            return .system(.body, design: .default)
        case .caption:
            return .system(.footnote, design: .default).monospacedDigit()
        case .micro:
            return .system(.caption, design: .default).monospacedDigit()
        }
    }
}

/// Role: Pass. One 8pt grid. Hits are 44pt. Views never pick a stray padding.
enum PassSpace {
    static let unit: CGFloat = 8

    static func step(_ n: Int) -> CGFloat {
        unit * CGFloat(n)
    }

    static var hit: CGFloat { 44 }
    static var outer: CGFloat { step(3) }
    static var card: CGFloat { step(2) }
    static var inner: CGFloat { step(1) }
    static var gap: CGFloat { step(1) }
    static var hairline: CGFloat { 1 }
}

/// Role: Pass. Cards 18pt, chips 12pt. Never a second radius language.
enum PassRadius {
    static let card: CGFloat = 18
    static let chip: CGFloat = 12
}
