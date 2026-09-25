import SwiftUI
import UIKit

/// Role: Pass. Quiet 180ms ease-out. Reduce Motion is an instant swap. One haptic on Bowl, Walk, Save, Retract.
enum PassMotion {
    static let fadeSeconds: Double = 0.18
    static let flashSeconds: Double = 0.36
    static let spinnerNanos: UInt64 = 150_000_000
    static let press: CGFloat = 0.98

    static func crossfade(_ reduceMotion: Bool) -> Animation? {
        if reduceMotion { return nil }
        return .easeOut(duration: fadeSeconds)
    }
}

/// Role: Pass. One success pulse. Never on opening a sheet.
enum PassPulse {
    @MainActor
    static func commit() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

/// Role: Pass. Daykey display through DateFormatter. Numbers still go through PassFigures.
enum PassStamp {
    @MainActor
    static func day(_ daykey: Int, calendar: Calendar = .current) -> String {
        guard let date = PassDaykey(rawValue: daykey).startDate(calendar: calendar) else {
            return PassFigures.daykey(daykey)
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

/// Role: Pass. Editorial sentences for faults, notices, and empty plates. No em dash. No slang.
enum PassCopy {
    static func fault(_ fault: PassFault) -> String {
        switch fault {
        case .passEmpty:
            return "The pass has no open ticket."
        case .openRefused:
            return "Tonight's ticket is still firing. Plate it before opening another recipe."
        case .unknownBook:
            return "That cookbook item is missing."
        case .unknownBowl:
            return "That bowl is not on tonight's ticket."
        case .bowlBlocked:
            return "Bowls file only during mise."
        case .alreadyFiled:
            return "That bowl is already filed."
        case .walkBeforeFire:
            return "File every mise bowl before the first walk."
        case .walkBlocked:
            return "Walks file only while the ticket is firing."
        case .walkExhausted:
            return "Every walk on this ticket is already filed."
        case .retractEmpty:
            return "There is nothing to retract."
        }
    }

    static func notice(_ notice: PassNotice) -> String {
        switch notice {
        case .restored:
            return "The pass was restored from a backup."
        case .cleared:
            return "The pass file was damaged. Tonight starts empty."
        }
    }

    static func phase(_ phase: TicketPhase) -> String {
        switch phase {
        case .mise:
            return "Mise"
        case .firing:
            return "Firing"
        case .plated:
            return "Plated"
        }
    }

    static func saveFailed() -> String {
        "The pass could not be saved. Try again."
    }

    static func bootFailed() -> String {
        "The pass folder could not be opened."
    }
}
