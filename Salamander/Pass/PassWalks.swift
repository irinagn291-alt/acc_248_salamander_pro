import Foundation

/// Role: Pass. Numbered fire lines from an instruction block. Leading step numbers are stripped.
enum PassWalks {
    static func split(_ text: String?) -> [String] {
        let raw = (text ?? "")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        var lines = raw
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { stripLead(String($0)) }
            .filter { !$0.isEmpty }
        if lines.count <= 1 {
            let blob = lines.first ?? stripLead(raw)
            lines = sentences(blob)
        }
        return lines
    }

    static func stripLead(_ line: String) -> String {
        var text = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = text.range(
            of: #"^(?:step\s+)?\d+[\.\)\:\-]\s*"#,
            options: [.regularExpression, .caseInsensitive]
        ) {
            text.removeSubrange(range)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func sentences(_ blob: String) -> [String] {
        let trimmed = blob.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        var parts: [String] = []
        var buffer = ""
        for character in trimmed {
            buffer.append(character)
            if character == "." {
                let piece = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
                if !piece.isEmpty {
                    parts.append(piece)
                }
                buffer = ""
            }
        }
        let tail = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty {
            parts.append(tail)
        }
        return parts.isEmpty ? [trimmed] : parts
    }
}
