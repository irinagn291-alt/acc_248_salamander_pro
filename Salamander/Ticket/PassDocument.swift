import Foundation

/// Role: Ticket. Codable pass document. schemaVersion from 1. The pass is a fold over Tickets. Walk index is WalkMark count. Idle is derived from Firing.
struct PassDocument: Equatable, Sendable, Codable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var recipes: [Recipe]
    var cookbookItems: [CookbookItem]
    var tickets: [TicketRecord]
    var bowls: [Bowl]
    var walks: [Walk]
    var walkMarks: [WalkMark]
    var fireMarks: [FireMark]
    var serviceMarks: [ServiceMark]
    var cachedCatalog: [Recipe]
    var currentDaykey: Int

    static let schema = 1

    static let empty = PassDocument(
        schemaVersion: schema,
        onboardingComplete: false,
        recipes: [],
        cookbookItems: [],
        tickets: [],
        bowls: [],
        walks: [],
        walkMarks: [],
        fireMarks: [],
        serviceMarks: [],
        cachedCatalog: [],
        currentDaykey: 0
    )

    /// One open ticket. Plated tickets remain as ServiceMark history plus a plated row.
    var openTicket: Ticket? {
        tickets.compactMap { record -> Ticket? in
            switch record.phase {
            case .mise, .firing:
                return assembled(record.id)
            case .plated:
                return nil
            }
        }.first
    }

    var isBusy: Bool { openTicket != nil }

    var holdsIdle: Bool { openTicket?.holdsIdle ?? false }

    var canWalk: Bool {
        guard let ticket = openTicket, case .firing = ticket else { return false }
        return remainingWalks(for: ticket.sheet.id) > 0
    }

    var canFileBowl: Bool {
        guard let ticket = openTicket, case .mise = ticket else { return false }
        return !ticket.sheet.unfiledBowls.isEmpty
    }

    var canRetract: Bool {
        guard let ticket = retractTarget else { return false }
        if walkIndex(for: ticket.sheet.id) > 0 { return true }
        return ticket.sheet.bowls.contains(where: \.isFiled)
    }

    var canOpen: Bool { !isBusy }

    func assembled(_ ticketID: UUID) -> Ticket? {
        guard let record = tickets.first(where: { $0.id == ticketID }) else { return nil }
        let ticketBowls = bowls.filter { $0.ticketID == ticketID }
        let ticketWalks = walks.filter { $0.ticketID == ticketID }
        return Ticket.fold(record: record, bowls: ticketBowls, walks: ticketWalks)
    }

    func walkIndex(for ticketID: UUID) -> Int {
        walkMarks.filter { $0.ticketID == ticketID }.count
    }

    func remainingWalks(for ticketID: UUID) -> Int {
        let total = walks.filter { $0.ticketID == ticketID }.count
        return max(total - walkIndex(for: ticketID), 0)
    }

    func liveWalk(for ticketID: UUID) -> Walk? {
        let ticketWalks = walks.filter { $0.ticketID == ticketID }
        let index = walkIndex(for: ticketID)
        guard ticketWalks.indices.contains(index) else { return nil }
        return ticketWalks[index]
    }

    func recipe(for mealID: String) -> Recipe? {
        if let saved = recipes.first(where: { $0.id == mealID }) { return saved }
        return cachedCatalog.first(where: { $0.id == mealID })
    }

    mutating func cache(_ recipe: Recipe) {
        if let index = cachedCatalog.firstIndex(where: { $0.id == recipe.id }) {
            cachedCatalog[index] = recipe
        } else {
            cachedCatalog.append(recipe)
        }
    }

    mutating func saveRecipe(
        _ recipe: Recipe,
        now: Date,
        calendar: Calendar,
        itemID: UUID = UUID()
    ) {
        cache(recipe)
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
        } else {
            recipes.append(recipe)
        }
        if let itemIndex = cookbookItems.firstIndex(where: { $0.mealID == recipe.id }) {
            cookbookItems[itemIndex].name = recipe.name
        } else {
            cookbookItems.append(
                CookbookItem(
                    id: itemID,
                    mealID: recipe.id,
                    name: recipe.name,
                    savedDaykey: PassDaykey.from(now, calendar: calendar).rawValue
                )
            )
        }
        currentDaykey = PassDaykey.from(now, calendar: calendar).rawValue
    }

    mutating func openFromCookbook(
        itemID: UUID,
        now: Date,
        calendar: Calendar,
        ticketID: UUID = UUID(),
        bowlIDs: [UUID]? = nil,
        walkIDs: [UUID]? = nil
    ) throws {
        guard canOpen else { throw PassFault.openRefused }
        guard let item = cookbookItems.first(where: { $0.id == itemID }) else {
            throw PassFault.unknownBook
        }
        guard let recipe = recipe(for: item.mealID) else { throw PassFault.unknownBook }
        try openTicket(from: recipe, now: now, calendar: calendar, ticketID: ticketID, bowlIDs: bowlIDs, walkIDs: walkIDs)
    }

    mutating func openTicket(
        from recipe: Recipe,
        now: Date,
        calendar: Calendar,
        ticketID: UUID = UUID(),
        bowlIDs: [UUID]? = nil,
        walkIDs: [UUID]? = nil
    ) throws {
        guard canOpen else { throw PassFault.openRefused }
        guard !recipe.bowls.isEmpty, !recipe.walks.isEmpty else { throw PassFault.unknownBook }
        let daykey = PassDaykey.from(now, calendar: calendar).rawValue
        currentDaykey = daykey
        tickets.append(
            TicketRecord(
                id: ticketID,
                mealID: recipe.id,
                name: recipe.name,
                phase: .mise,
                openedDaykey: daykey
            )
        )
        for (index, bowl) in recipe.bowls.enumerated() {
            let ident = bowlIDs.flatMap { $0.indices.contains(index) ? $0[index] : nil } ?? UUID()
            bowls.append(bowl.placed(on: ticketID, id: ident))
        }
        for (index, walk) in recipe.walks.enumerated() {
            let ident = walkIDs.flatMap { $0.indices.contains(index) ? $0[index] : nil } ?? UUID()
            walks.append(walk.placed(on: ticketID, id: ident))
        }
    }

    mutating func fileBowl(
        _ bowlID: UUID,
        now: Date,
        calendar: Calendar,
        markID: UUID = UUID()
    ) throws {
        guard let ticket = openTicket else { throw PassFault.passEmpty }
        guard case .mise = ticket else { throw PassFault.bowlBlocked }
        guard let index = bowls.firstIndex(where: { $0.id == bowlID && $0.ticketID == ticket.sheet.id }) else {
            throw PassFault.unknownBowl
        }
        guard bowls[index].filedUnix == nil else { throw PassFault.alreadyFiled }
        let unix = now.timeIntervalSince1970
        bowls[index].filedUnix = unix
        currentDaykey = PassDaykey.from(now, calendar: calendar).rawValue
        let stillOpen = bowls.contains { $0.ticketID == ticket.sheet.id && $0.filedUnix == nil }
        if !stillOpen {
            setPhase(ticket.sheet.id, .firing)
            fireMarks.append(
                FireMark(
                    id: markID,
                    ticketID: ticket.sheet.id,
                    daykey: currentDaykey,
                    markedUnix: unix
                )
            )
        }
    }

    mutating func fileWalk(
        now: Date,
        calendar: Calendar,
        markID: UUID = UUID()
    ) throws {
        guard let ticket = openTicket else { throw PassFault.passEmpty }
        switch ticket {
        case .mise:
            throw PassFault.walkBeforeFire
        case .plated:
            throw PassFault.walkBlocked
        case .firing(let sheet):
            let index = walkIndex(for: sheet.id)
            let ticketWalks = walks.filter { $0.ticketID == sheet.id }
            guard ticketWalks.indices.contains(index) else { throw PassFault.walkExhausted }
            let walk = ticketWalks[index]
            let unix = now.timeIntervalSince1970
            currentDaykey = PassDaykey.from(now, calendar: calendar).rawValue
            walkMarks.append(
                WalkMark(
                    id: markID,
                    ticketID: sheet.id,
                    walkID: walk.id,
                    daykey: currentDaykey,
                    markedUnix: unix
                )
            )
            if index + 1 == ticketWalks.count {
                setPhase(sheet.id, .plated)
                serviceMarks.append(
                    ServiceMark(
                        id: UUID(),
                        ticketID: sheet.id,
                        mealID: sheet.mealID,
                        name: sheet.name,
                        daykey: currentDaykey,
                        markedUnix: unix
                    )
                )
            }
        }
    }

    mutating func retract() throws {
        guard let ticket = retractTarget else { throw PassFault.retractEmpty }
        let ticketID = ticket.sheet.id
        if let lastMark = walkMarks.last(where: { $0.ticketID == ticketID }) {
            walkMarks.removeAll { $0.id == lastMark.id }
            if ticket.phase == .plated {
                if let mark = serviceMarks.last(where: { $0.ticketID == ticketID }) {
                    serviceMarks.removeAll { $0.id == mark.id }
                }
                setPhase(ticketID, .firing)
            }
            return
        }
        guard let lastBowl = ticket.sheet.filedBowls.last else { throw PassFault.retractEmpty }
        if let index = bowls.firstIndex(where: { $0.id == lastBowl.id }) {
            bowls[index].filedUnix = nil
        }
        if ticket.phase == .firing {
            if let mark = fireMarks.last(where: { $0.ticketID == ticketID }) {
                fireMarks.removeAll { $0.id == mark.id }
            }
            setPhase(ticketID, .mise)
        }
    }

    func localMatches(query: String, shelf: [Recipe]) -> [Recipe] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        var seen: Set<String> = []
        var rows: [Recipe] = []
        let pool = recipes + cachedCatalog + shelf
        for recipe in pool where recipe.name.localizedCaseInsensitiveContains(needle) {
            if seen.insert(recipe.id).inserted {
                rows.append(recipe)
            }
        }
        return rows
    }

    static func read(_ data: Data) throws -> PassDocument {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        let probe: SchemaProbe
        do {
            probe = try decoder.decode(SchemaProbe.self, from: data)
        } catch {
            throw PassCodecError.damaged
        }
        switch probe.schemaVersion {
        case 1:
            do {
                var document = try decoder.decode(PassDocument.self, from: data)
                document.schemaVersion = schema
                return document
            } catch {
                throw PassCodecError.damaged
            }
        default:
            throw PassCodecError.unknownSchema(probe.schemaVersion)
        }
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.keyEncodingStrategy = .useDefaultKeys
        var copy = self
        copy.schemaVersion = Self.schema
        return try encoder.encode(copy)
    }

    private var retractTarget: Ticket? {
        if let open = openTicket { return open }
        guard let plated = tickets.last(where: { $0.phase == .plated }) else { return nil }
        return assembled(plated.id)
    }

    private mutating func setPhase(_ ticketID: UUID, _ phase: TicketPhase) {
        guard let index = tickets.firstIndex(where: { $0.id == ticketID }) else { return }
        tickets[index].phase = phase
    }
}

private struct SchemaProbe: Decodable {
    var schemaVersion: Int
}
