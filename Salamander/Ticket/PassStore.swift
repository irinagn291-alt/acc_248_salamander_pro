import Foundation

/// Role: Ticket. Persistence seam. Views call fileBowl, fileWalk, retract, save, and open. They never touch UserDefaults.
protocol PassStoring: Sendable {
    func load(now: Date, calendar: Calendar) async -> (document: PassDocument, notice: PassNotice?)
    func snapshot() async -> PassDocument
    func saveRecipe(_ recipe: Recipe, now: Date, calendar: Calendar) async throws -> PassDocument
    func openFromCookbook(itemID: UUID, now: Date, calendar: Calendar) async throws -> PassDocument
    func fileBowl(_ bowlID: UUID, now: Date, calendar: Calendar) async throws -> PassDocument
    func fileWalk(now: Date, calendar: Calendar) async throws -> PassDocument
    func retract() async throws -> PassDocument
    func setOnboardingComplete(_ flag: Bool) async -> PassDocument
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded(permit: Bool, now: Date, calendar: Calendar) async throws -> PassDocument?
    func seek(query: String, page: Int, pageSize: Int) async -> [Recipe]
}

/// Role: Ticket. Memory is the source of truth. UserDefaults slm.pass.v1 plus an Application Support projection. Views never touch UserDefaults.
actor PassStore {
    private struct Disk {
        var root: URL
        var vault: URL { root.appendingPathComponent("pass.json", isDirectory: false) }
        var spare: URL { root.appendingPathComponent("pass.json.backup", isDirectory: false) }
    }

    private let disk: Disk
    private let suite: String?
    private let files: FileManager
    private let quietNanos: UInt64
    private let seekNanos: UInt64
    private let client: PassClient
    private let shelf: [Recipe]

    private var memory = PassDocument.empty
    private var pending = false
    private var quietTask: Task<Void, Never>?
    private var seekTask: Task<[Recipe], Never>?
    private(set) var notice: PassNotice?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        client: PassClient = PassClient(),
        shelf: [Recipe] = PassShelf.bundled,
        fileManager: FileManager = .default,
        quietNanos: UInt64 = 360_000_000,
        seekNanos: UInt64 = 300_000_000
    ) {
        self.disk = Disk(root: directory)
        self.suite = defaultsSuiteName
        self.client = client
        self.shelf = shelf
        self.files = fileManager
        self.quietNanos = quietNanos
        self.seekNanos = seekNanos
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Salamander", isDirectory: true)
    }

    func load(now: Date = Date(), calendar: Calendar = .current) async -> (document: PassDocument, notice: PassNotice?) {
        notice = nil
        lastWriteError = nil
        pending = false
        switch recover() {
        case .clean(let document):
            memory = document
        case .spare(let document):
            memory = document
            notice = .restored
        case .blank(let hadPayload):
            memory = .empty
            if hadPayload {
                notice = .cleared
            }
        }
        memory.currentDaykey = PassDaykey.from(now, calendar: calendar).rawValue
        return (memory, notice)
    }

    func snapshot() async -> PassDocument {
        memory
    }

    func saveRecipe(_ recipe: Recipe, now: Date = Date(), calendar: Calendar = .current) async throws -> PassDocument {
        var next = memory
        next.saveRecipe(recipe, now: now, calendar: calendar)
        try persist(next)
        memory = next
        return memory
    }

    func openFromCookbook(
        itemID: UUID,
        now: Date = Date(),
        calendar: Calendar = .current
    ) async throws -> PassDocument {
        var next = memory
        try next.openFromCookbook(itemID: itemID, now: now, calendar: calendar)
        try persist(next)
        memory = next
        return memory
    }

    func fileBowl(
        _ bowlID: UUID,
        now: Date = Date(),
        calendar: Calendar = .current
    ) async throws -> PassDocument {
        var next = memory
        try next.fileBowl(bowlID, now: now, calendar: calendar)
        try persist(next)
        memory = next
        return memory
    }

    func fileWalk(now: Date = Date(), calendar: Calendar = .current) async throws -> PassDocument {
        var next = memory
        try next.fileWalk(now: now, calendar: calendar)
        try persist(next)
        memory = next
        return memory
    }

    func retract() async throws -> PassDocument {
        var next = memory
        try next.retract()
        try persist(next)
        memory = next
        return memory
    }

    func setOnboardingComplete(_ flag: Bool) async -> PassDocument {
        memory.onboardingComplete = flag
        pending = true
        armQuietWrite()
        return memory
    }

    func flush() async throws {
        quietTask?.cancel()
        quietTask = nil
        if pending {
            try persist(memory)
            pending = false
        }
    }

    func resetAllData() async throws {
        quietTask?.cancel()
        quietTask = nil
        seekTask?.cancel()
        seekTask = nil
        memory = .empty
        pending = false
        notice = nil
        lastWriteError = nil
        let defaults = defaults()
        defaults.removeObject(forKey: PassKey.snapshot)
        defaults.removeObject(forKey: PassKey.backup)
        defaults.removeObject(forKey: PassKey.demo)
        if files.fileExists(atPath: disk.root.path) {
            try files.removeItem(at: disk.root)
        }
        prepareRoot()
    }

    func seedDemoIfNeeded(
        permit: Bool,
        now: Date = Date(),
        calendar: Calendar = .current
    ) async throws -> PassDocument? {
        guard permit else { return nil }
        let defaults = defaults()
        guard defaults.object(forKey: PassKey.demo) == nil else { return nil }
        memory = PassSeed.document(at: now, calendar: calendar, shelf: shelf)
        try persist(memory)
        defaults.set(true, forKey: PassKey.demo)
        return memory
    }

    func seek(query: String, page: Int = 1, pageSize: Int = 20) async -> [Recipe] {
        seekTask?.cancel()
        let delay = seekNanos
        let task = Task<[Recipe], Never> {
            if delay > 0 {
                do {
                    try await Task.sleep(nanoseconds: delay)
                } catch {
                    return []
                }
            }
            guard !Task.isCancelled else { return [] }
            return await self.runSeek(query: query, page: page, pageSize: pageSize)
        }
        seekTask = task
        return await task.value
    }

    private func runSeek(query: String, page: Int, pageSize: Int) async -> [Recipe] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        do {
            let remote = try await client.search(query: trimmed, page: page, pageSize: pageSize)
            if remote.isEmpty {
                return memory.localMatches(query: trimmed, shelf: shelf)
            }
            var next = memory
            for recipe in remote {
                next.cache(recipe)
            }
            do {
                try persist(next)
                memory = next
            } catch {
                lastWriteError = String(describing: error)
            }
            return remote
        } catch is CancellationError {
            return memory.localMatches(query: trimmed, shelf: shelf)
        } catch {
            return memory.localMatches(query: trimmed, shelf: shelf)
        }
    }

    private enum Recovered {
        case clean(PassDocument)
        case spare(PassDocument)
        case blank(Bool)
    }

    private func recover() -> Recovered {
        let defaults = defaults()
        if let data = defaults.data(forKey: PassKey.snapshot), let document = decode(data) {
            return .clean(document)
        }
        if let document = decodeFile(disk.vault) {
            return .clean(document)
        }
        if let data = defaults.data(forKey: PassKey.backup), let document = decode(data) {
            return .spare(document)
        }
        if let document = decodeFile(disk.spare) {
            return .spare(document)
        }
        let hadPayload = defaults.data(forKey: PassKey.snapshot) != nil
            || files.fileExists(atPath: disk.vault.path)
        return .blank(hadPayload)
    }

    private func persist(_ document: PassDocument) throws {
        let data = try document.encoded()
        let defaults = defaults()
        if let previous = defaults.data(forKey: PassKey.snapshot) {
            defaults.set(previous, forKey: PassKey.backup)
        }
        defaults.set(data, forKey: PassKey.snapshot)
        try files.createDirectory(at: disk.root, withIntermediateDirectories: true)
        if files.fileExists(atPath: disk.vault.path) {
            do {
                if files.fileExists(atPath: disk.spare.path) {
                    try files.removeItem(at: disk.spare)
                }
                try files.copyItem(at: disk.vault, to: disk.spare)
            } catch {
                lastWriteError = String(describing: error)
            }
        }
        try data.write(to: disk.vault, options: .atomic)
        pending = false
        lastWriteError = nil
    }

    private func armQuietWrite() {
        quietTask?.cancel()
        let delay = quietNanos
        quietTask = Task { [weak self] in
            if delay > 0 {
                do {
                    try await Task.sleep(nanoseconds: delay)
                } catch {
                    return
                }
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        quietTask = nil
        do {
            if pending {
                try persist(memory)
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func decode(_ data: Data) -> PassDocument? {
        try? PassDocument.read(data)
    }

    private func decodeFile(_ url: URL) -> PassDocument? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data)
    }

    private func defaults() -> UserDefaults {
        if let suite {
            return UserDefaults(suiteName: suite) ?? .standard
        }
        return .standard
    }

    private func prepareRoot() {
        if !files.fileExists(atPath: disk.root.path) {
            try? files.createDirectory(at: disk.root, withIntermediateDirectories: true)
        }
    }
}

extension PassStore: PassStoring {}
