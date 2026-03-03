//
//  ClaudeIngredientParserTests.swift
//  foragerTests
//
//  M10.6.1: Tests for ClaudeIngredientParser — API mocking,
//  response parsing, error handling, retry logic, validation.
//

import XCTest
@testable import forager

// MARK: - Mock URL Protocol

private class MockURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Tests

final class ClaudeIngredientParserTests: XCTestCase {

    private var parser: ClaudeIngredientParser!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: config)
        parser = ClaudeIngredientParser(apiKey: "sk-ant-test-key", session: session)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeToolUseResponse(ingredients: [[String: Any]]) -> Data {
        let response: [String: Any] = [
            "id": "msg_test",
            "type": "message",
            "role": "assistant",
            "content": [
                [
                    "type": "tool_use",
                    "id": "toolu_test",
                    "name": "parse_ingredients",
                    "input": [
                        "ingredients": ingredients
                    ]
                ]
            ],
            "stop_reason": "tool_use"
        ]
        return try! JSONSerialization.data(withJSONObject: response)
    }

    private func stubResponse(statusCode: Int = 200, data: Data? = nil) {
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data ?? Data())
        }
    }

    // MARK: - 1. Successful Batch Parse

    func testSuccessfulBatchParse() async throws {
        let responseData = makeToolUseResponse(ingredients: [
            ["name": "mushrooms", "quantity": 400, "unit": "g", "notes": NSNull()],
            ["name": "flour", "quantity": 2, "unit": "cups", "notes": "sifted"]
        ])
        stubResponse(data: responseData)

        let results = try await parser.parseBatch(["400g mushrooms", "2 cups flour, sifted"])

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].name, "mushrooms")
        XCTAssertEqual(results[0].quantity, 400)
        XCTAssertEqual(results[0].unit, "g")
        XCTAssertNil(results[0].notes)
        XCTAssertEqual(results[1].name, "flour")
        XCTAssertEqual(results[1].quantity, 2)
        XCTAssertEqual(results[1].unit, "cups")
        XCTAssertEqual(results[1].notes, "sifted")
        XCTAssertEqual(results[0].confidence, 0.95)
    }

    // MARK: - 2. Empty Input

    func testEmptyInputReturnsEmptyResults() async throws {
        let results = try await parser.parseBatch([])
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - 3. Single Ingredient

    func testSingleIngredientParse() async throws {
        let responseData = makeToolUseResponse(ingredients: [
            ["name": "eggs", "quantity": 2, "unit": NSNull(), "notes": NSNull()]
        ])
        stubResponse(data: responseData)

        let results = try await parser.parseBatch(["2 eggs"])

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "eggs")
        XCTAssertEqual(results[0].quantity, 2)
        XCTAssertNil(results[0].unit)
    }

    // MARK: - 4. Compound Ingredient (No Split)

    func testCompoundIngredientKeptAsOne() async throws {
        let responseData = makeToolUseResponse(ingredients: [
            ["name": "salt and pepper", "quantity": NSNull(), "unit": NSNull(), "notes": "to taste"]
        ])
        stubResponse(data: responseData)

        let results = try await parser.parseBatch(["salt and pepper to taste"])

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "salt and pepper")
        XCTAssertEqual(results[0].notes, "to taste")
    }

    // MARK: - 5. 401 Error (No Retry)

    func testInvalidAPIKeyThrowsWithoutRetry() async {
        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await parser.parseBatch(["1 cup flour"])
            XCTFail("Expected LLMParserError.invalidAPIKey")
        } catch let error as LLMParserError {
            XCTAssertEqual(error.errorDescription, "Invalid API key")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertEqual(requestCount, 1, "401 should not retry")
    }

    // MARK: - 6. 429 Error (Retries with Backoff)

    func testRateLimitedRetriesAndEventuallyThrows() async {
        var requestCount = 0
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await parser.parseBatch(["1 cup flour"])
            XCTFail("Expected LLMParserError.rateLimited")
        } catch let error as LLMParserError {
            XCTAssertEqual(error.errorDescription, "Rate limited — try again shortly")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }

        XCTAssertEqual(requestCount, 3, "Should retry 3 times on 429")
    }

    // MARK: - 7. Malformed Response

    func testMalformedResponseThrows() async {
        let badData = try! JSONSerialization.data(withJSONObject: ["content": "not an array"])
        stubResponse(data: badData)

        do {
            _ = try await parser.parseBatch(["1 cup flour"])
            XCTFail("Expected LLMParserError.malformedResponse")
        } catch let error as LLMParserError {
            XCTAssertTrue(error.errorDescription?.contains("Malformed") == true)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - 8. Validation: Empty Name Ingredients Throw

    func testEmptyNameIngredientsThrowsValidation() async {
        let responseData = makeToolUseResponse(ingredients: [
            ["name": "", "quantity": 1, "unit": "cup"]
        ])
        stubResponse(data: responseData)

        do {
            _ = try await parser.parseBatch(["1 cup ???"])
            XCTFail("Expected LLMParserError.validationFailed")
        } catch let error as LLMParserError {
            XCTAssertTrue(error.errorDescription?.contains("Dropped") == true ||
                          error.errorDescription?.contains("empty name") == true,
                          "Expected validation error about dropped/empty items, got: \(error.errorDescription ?? "nil")")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - 9. toParserResult Bridge

    func testToParserResultBridge() {
        let llmResult = LLMParserResult(
            name: "flour",
            quantity: 2.0,
            unit: "cups",
            notes: "sifted",
            confidence: 0.95,
            category: nil
        )

        let parserResult = llmResult.toParserResult(originalText: "2 cups flour, sifted", provider: "claude")

        XCTAssertEqual(parserResult.name, "flour")
        XCTAssertEqual(parserResult.quantity, 2.0)
        XCTAssertEqual(parserResult.unit, "cups")
        XCTAssertEqual(parserResult.notes, "sifted")
        XCTAssertEqual(parserResult.confidence, 0.95)
        XCTAssertEqual(parserResult.originalText, "2 cups flour, sifted")
        XCTAssertEqual(parserResult.parserUsed, "claude")
    }

    // MARK: - 10. Request Format Verification

    func testRequestIncludesCorrectHeaders() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            let responseData = self.makeToolUseResponse(ingredients: [
                ["name": "flour", "quantity": 1, "unit": "cup"]
            ])
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, responseData)
        }

        _ = try await parser.parseBatch(["1 cup flour"])

        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "x-api-key"), "sk-ant-test-key")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "content-type"), "application/json")
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
    }
}
