import XCTest
@testable import Salamander

final class PassClientTests: XCTestCase {
    func test_cgiSearchPlMapsOntoTheMealDBQueryS() throws {
        let request = PassClient.searchRequest(query: "bass")
        let url = try XCTUnwrap(request.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let keyed = Dictionary(uniqueKeysWithValues: items.compactMap { item in
            item.value.map { (item.name, $0) }
        })
        XCTAssertEqual(url.host, "www.themealdb.com")
        XCTAssertEqual(url.path, "/api/json/v1/1/search.php")
        XCTAssertEqual(keyed["s"], "bass")
        XCTAssertNil(keyed["search_terms"])
        XCTAssertNil(keyed["json"])
        XCTAssertFalse(url.absoluteString.contains("openfoodfacts"))
        XCTAssertFalse(url.absoluteString.contains("cgi/search.pl"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), PassClient.userAgent)
        XCTAssertEqual(request.timeoutInterval, 15)
        XCTAssertEqual(PassClient.userAgent, "Salamander/1.0 (iOS; +https://salamander-pass.pro)")
        XCTAssertEqual(PassClient.contactURL.absoluteString, "https://salamander-pass.pro/contact-us")
        XCTAssertEqual(PassClient.catalogHomeURL.absoluteString, "https://www.themealdb.com")
    }

    func test_lookupUsesMealIdParameterI() throws {
        let request = PassClient.lookupRequest(mealID: "52772")
        let url = try XCTUnwrap(request.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let keyed = Dictionary(uniqueKeysWithValues: items.compactMap { item in
            item.value.map { (item.name, $0) }
        })
        XCTAssertEqual(url.path, "/api/json/v1/1/lookup.php")
        XCTAssertEqual(keyed["i"], "52772")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), PassClient.userAgent)
    }

    func test_slicesMealsByPageOnDevice() {
        let items = ["a", "b", "c", "d", "e"]
        XCTAssertEqual(PassClient.slice(items, page: 2, pageSize: 2), ["c", "d"])
        XCTAssertEqual(PassClient.slice(items, page: 1, pageSize: 2), ["a", "b"])
        XCTAssertEqual(PassClient.slice(items, page: 4, pageSize: 2), [])
    }

    func test_dtoMapsIngredientsAndInstructionsThenDomainRecipe() async throws {
        let courier = ScriptedCourier(results: [
            .success((MealFixtures.searchJSON, try http(200))),
        ])
        let client = PassClient(courier: courier)
        let rows = try await client.search(query: "bass", page: 1, pageSize: 20)
        let row = try XCTUnwrap(rows.first)
        XCTAssertEqual(row.id, "52772")
        XCTAssertEqual(row.name, "Salt crust sea bass")
        XCTAssertEqual(row.bowls.map(\.name), ["Sea bass", "Coarse salt"])
        XCTAssertEqual(row.walks.map(\.text), ["Pat the bass dry.", "Pack the salt crust."])
        let request = await courier.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), PassClient.userAgent)
    }

    func test_retriesTransientTransportOnce() async throws {
        let courier = ScriptedCourier(results: [
            .failure(URLError(.timedOut)),
            .success((MealFixtures.searchJSON, try http(200))),
        ])
        let client = PassClient(courier: courier)
        let rows = try await client.search(query: "bass")
        XCTAssertEqual(rows.count, 1)
        let count = await courier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async throws {
        let courier = ScriptedCourier(results: [
            .success((Data(), try http(404))),
            .success((MealFixtures.searchJSON, try http(200))),
        ])
        let client = PassClient(courier: courier)
        do {
            _ = try await client.search(query: "bass")
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? PassWire, .notFound)
        }
        let count = await courier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsMalformed() async throws {
        let courier = ScriptedCourier(results: [
            .success((Data("{".utf8), try http(200))),
        ])
        let client = PassClient(courier: courier)
        do {
            _ = try await client.search(query: "bass")
            XCTFail("expected malformed")
        } catch {
            XCTAssertEqual(error as? PassWire, .malformed)
        }
    }

    func test_nullMealsIsEmptyNotMalformed() async throws {
        let courier = ScriptedCourier(results: [
            .success((Data("{\"meals\":null}".utf8), try http(200))),
        ])
        let client = PassClient(courier: courier)
        let rows = try await client.search(query: "xyz")
        XCTAssertTrue(rows.isEmpty)
    }

    func test_emptyQueryDoesNotHitNetwork() async throws {
        let courier = ScriptedCourier(results: [
            .success((MealFixtures.searchJSON, try http(200))),
        ])
        let client = PassClient(courier: courier)
        let rows = try await client.search(query: "   ")
        XCTAssertTrue(rows.isEmpty)
        let count = await courier.recordedRequests().count
        XCTAssertEqual(count, 0)
    }

    func test_setsUserAgentOnLookup() async throws {
        let courier = ScriptedCourier(results: [
            .success((MealFixtures.searchJSON, try http(200, url: PassClient.lookupURL))),
        ])
        let client = PassClient(courier: courier)
        let recipe = try await client.lookup(mealID: "52772")
        XCTAssertEqual(recipe.id, "52772")
        let request = await courier.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), PassClient.userAgent)
        XCTAssertTrue(request?.url?.path.contains("lookup.php") == true)
    }

    private func http(_ status: Int, url: URL = PassClient.searchURL) throws -> HTTPURLResponse {
        try XCTUnwrap(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil))
    }
}

enum MealFixtures {
    static let searchJSON = Data(
        """
        {"meals":[{"idMeal":"52772","strMeal":"Salt crust sea bass","strCategory":"Seafood","strArea":"French","strInstructions":"Pat the bass dry.\\nPack the salt crust.","strMealThumb":"https://example.com/bass.png","strIngredient1":"Sea bass","strMeasure1":"1 whole","strIngredient2":"Coarse salt","strMeasure2":"1 kg","strIngredient3":"","strMeasure3":""}]}
        """.utf8
    )
}
