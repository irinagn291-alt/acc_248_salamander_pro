import Foundation

/// Role: Pass. Typed transport failures. DTO decode never crashes the pass.
enum PassWire: Error, Equatable, Sendable {
    case notFound
    case malformed
    case transport
    case cancelled
    case unexpected
}

/// Role: Pass. One HTTP exchange. Tests inject a script.
protocol PassCourier: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Pass. 15 s timeout and the app User-Agent on every request.
struct PassSession: PassCourier, Sendable {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = PassClient.timeout
        configuration.timeoutIntervalForResource = PassClient.timeout
        configuration.httpAdditionalHeaders = ["User-Agent": PassClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

struct DynamicJSONKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init(_ string: String) {
        stringValue = string
        intValue = nil
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

/// Role: Pass. DTO that mirrors TheMealDB meal JSON. Maps to Recipe after decode.
struct MealDTO: Decodable, Sendable {
    var idMeal: String?
    var strMeal: String?
    var strCategory: String?
    var strArea: String?
    var strInstructions: String?
    var strMealThumb: String?
    var bowls: [Bowl]

    init(from decoder: Decoder) throws {
        let keyed = try decoder.container(keyedBy: DynamicJSONKey.self)
        idMeal = try keyed.decodeIfPresent(String.self, forKey: DynamicJSONKey("idMeal"))
        strMeal = try keyed.decodeIfPresent(String.self, forKey: DynamicJSONKey("strMeal"))
        strCategory = try keyed.decodeIfPresent(String.self, forKey: DynamicJSONKey("strCategory"))
        strArea = try keyed.decodeIfPresent(String.self, forKey: DynamicJSONKey("strArea"))
        strInstructions = try keyed.decodeIfPresent(String.self, forKey: DynamicJSONKey("strInstructions"))
        strMealThumb = try keyed.decodeIfPresent(String.self, forKey: DynamicJSONKey("strMealThumb"))
        var slots: [Bowl] = []
        for index in 1 ... 20 {
            let name = Self.trim(try keyed.decodeIfPresent(String.self, forKey: DynamicJSONKey("strIngredient\(index)")))
            let measure = Self.trim(try keyed.decodeIfPresent(String.self, forKey: DynamicJSONKey("strMeasure\(index)")))
            if name.isEmpty { continue }
            slots.append(Bowl.template(name: name, measure: measure))
        }
        bowls = slots
    }

    func asRecipe() -> Recipe? {
        let ident = Self.trim(idMeal)
        let name = Self.trim(strMeal)
        guard !ident.isEmpty, !name.isEmpty else { return nil }
        let lines = PassWalks.split(strInstructions)
        guard !bowls.isEmpty, !lines.isEmpty else { return nil }
        return Recipe(
            id: ident,
            name: name,
            category: Self.trim(strCategory),
            area: Self.trim(strArea),
            thumb: Self.trim(strMealThumb),
            bowls: bowls,
            walks: lines.map { Walk.template(text: $0) }
        )
    }

    private static func trim(_ value: String?) -> String {
        let text = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if text.lowercased() == "null" { return "" }
        return text
    }
}

struct MealsEnvelopeDTO: Decodable, Sendable {
    var meals: [MealDTO]?
}

/// Role: Pass. Owns TheMealDB search.php and lookup.php. cgi search pl maps to s, page, page_size. Never Open Food Facts.
actor PassClient {
    static let userAgent = "Salamander/1.0 (iOS; +https://salamander-pass.pro)"
    static let timeout: TimeInterval = 15
    static let searchHost = "www.themealdb.com"
    static let searchPath = "/api/json/v1/1/search.php"
    static let lookupPath = "/api/json/v1/1/lookup.php"
    /// Programmer constant; the domain string is fixed in SPEC.md.
    static let contactURL = URL(string: "https://salamander-pass.pro/contact-us")!
    /// Programmer constant; TheMealDB credit lives on Settings.
    static let catalogHomeURL = URL(string: "https://www.themealdb.com")!
    static let searchURL = URL(string: "https://www.themealdb.com/api/json/v1/1/search.php")!
    static let lookupURL = URL(string: "https://www.themealdb.com/api/json/v1/1/lookup.php")!

    private let courier: any PassCourier
    private let decoder: JSONDecoder

    init(courier: any PassCourier) {
        self.courier = courier
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    init() {
        self.init(courier: PassSession())
    }

    func search(query: String, page: Int = 1, pageSize: Int = 20) async throws -> [Recipe] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let request = Self.searchRequest(query: trimmed)
        let recipes = try await decodeMeals(request)
        return Self.slice(recipes, page: page, pageSize: pageSize)
    }

    func lookup(mealID: String) async throws -> Recipe {
        let trimmed = mealID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PassWire.notFound }
        let request = Self.lookupRequest(mealID: trimmed)
        let recipes = try await decodeMeals(request)
        guard let recipe = recipes.first else { throw PassWire.notFound }
        return recipe
    }

    nonisolated static func searchRequest(query: String) -> URLRequest {
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = searchHost
        parts.path = searchPath
        parts.queryItems = [
            URLQueryItem(name: "s", value: query),
        ]
        var request = URLRequest(url: parts.url ?? searchURL, timeoutInterval: timeout)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    nonisolated static func lookupRequest(mealID: String) -> URLRequest {
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = searchHost
        parts.path = lookupPath
        parts.queryItems = [
            URLQueryItem(name: "i", value: mealID),
        ]
        var request = URLRequest(url: parts.url ?? lookupURL, timeoutInterval: timeout)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    nonisolated static func slice<Item>(_ items: [Item], page: Int, pageSize: Int) -> [Item] {
        let size = min(max(pageSize, 1), 50)
        let index = max(page, 1)
        let start = (index - 1) * size
        guard start < items.count else { return [] }
        return Array(items[start ..< min(start + size, items.count)])
    }

    private func decodeMeals(_ request: URLRequest) async throws -> [Recipe] {
        let data = try await fetch(request)
        let envelope: MealsEnvelopeDTO
        do {
            envelope = try decoder.decode(MealsEnvelopeDTO.self, from: data)
        } catch is CancellationError {
            throw PassWire.cancelled
        } catch {
            throw PassWire.malformed
        }
        return (envelope.meals ?? []).compactMap { $0.asRecipe() }
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        var lastError: Error = PassWire.transport
        for attempt in 0 ... 1 {
            try Task.checkCancellation()
            do {
                return try await once(request)
            } catch let wire as PassWire {
                throw wire
            } catch is CancellationError {
                throw PassWire.cancelled
            } catch {
                if passHalted(error) { throw PassWire.cancelled }
                lastError = error
                if attempt == 0, passTransient(error) {
                    continue
                }
                throw PassWire.transport
            }
        }
        throw lastError
    }

    private func once(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await courier.send(request)
        guard let http = response as? HTTPURLResponse else {
            throw PassWire.unexpected
        }
        if http.statusCode == 404 {
            throw PassWire.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw PassWire.transport
        }
        return data
    }
}

func passTransient(_ error: Error) -> Bool {
    guard let urlError = error as? URLError else { return false }
    switch urlError.code {
    case .timedOut, .networkConnectionLost, .notConnectedToInternet,
         .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
        return true
    default:
        return false
    }
}

func passHalted(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    return (error as? URLError)?.code == .cancelled
}
