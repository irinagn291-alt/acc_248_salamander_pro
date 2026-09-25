import Foundation

/// Role: Pass. Walk index, bowl counts, and ServiceMark counts go through NumberFormatter. Never interpolate for display.
enum PassFigures {
    private static let whole: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static func integer(_ value: Int) -> String {
        whole.string(from: NSNumber(value: value)) ?? String(value)
    }

    static func daykey(_ value: Int) -> String {
        integer(value)
    }
}
