import Foundation

/// Role: Pass. Day edges as Int YYYYMMDD from Calendar.startOfDay in the user's zone.
struct PassDaykey: RawRepresentable, Hashable, Sendable, Comparable, Codable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static func from(_ date: Date, calendar: Calendar) -> PassDaykey {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return PassDaykey(rawValue: year * 10_000 + month * 100 + day)
    }

    func startDate(calendar: Calendar) -> Date? {
        var parts = DateComponents()
        parts.year = rawValue / 10_000
        parts.month = (rawValue / 100) % 100
        parts.day = rawValue % 100
        guard let date = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: date)
    }

    func shifted(by days: Int, calendar: Calendar) -> PassDaykey {
        guard let start = startDate(calendar: calendar),
              let moved = calendar.date(byAdding: .day, value: days, to: start)
        else {
            return self
        }
        return PassDaykey.from(moved, calendar: calendar)
    }

    static func < (lhs: PassDaykey, rhs: PassDaykey) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
