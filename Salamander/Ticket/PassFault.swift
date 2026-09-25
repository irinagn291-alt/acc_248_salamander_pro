import Foundation

/// Role: Ticket. Typed refusals of open, bowl, walk, and retract. Views map these. They never mutate the fold.
enum PassFault: Error, Equatable, Sendable {
    case passEmpty
    case openRefused
    case unknownBook
    case unknownBowl
    case bowlBlocked
    case alreadyFiled
    case walkBeforeFire
    case walkBlocked
    case walkExhausted
    case retractEmpty
}

enum PassCodecError: Error, Equatable, Sendable {
    case unknownSchema(Int)
    case damaged
}

enum PassNotice: Equatable, Sendable {
    case restored
    case cleared
}

enum PassKey {
    static let snapshot = "slm.pass.v1"
    static let backup = "slm.pass.v1.backup"
    static let demo = "slm.demo.v1"
}
