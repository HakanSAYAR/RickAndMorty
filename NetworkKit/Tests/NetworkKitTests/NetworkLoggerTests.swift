//
//  NetworkLoggerTests.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import XCTest
@testable import NetworkKit

final class NetworkLoggerTests: XCTestCase {

    private var sut: NetworkLogger!

    override func setUp() {
        super.setUp()
        sut = NetworkLogger(subsystem: "com.test", logLevel: .verbose)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Sensitive Header Masking

    func test_maskedHeaderValue_masksAuthorization() {
        let result = sut.maskedHeaderValue("Bearer secret-token", for: "Authorization")
        XCTAssertEqual(result, "***")
    }

    func test_maskedHeaderValue_masksCaseInsensitive() {
        let result = sut.maskedHeaderValue("value", for: "AUTHORIZATION")
        XCTAssertEqual(result, "***")
    }

    func test_maskedHeaderValue_masksXAPIKey() {
        let result = sut.maskedHeaderValue("my-api-key", for: "X-API-Key")
        XCTAssertEqual(result, "***")
    }

    func test_maskedHeaderValue_masksCookie() {
        let result = sut.maskedHeaderValue("session=abc", for: "Cookie")
        XCTAssertEqual(result, "***")
    }

    func test_maskedHeaderValue_doesNotMaskContentType() {
        let result = sut.maskedHeaderValue("application/json", for: "Content-Type")
        XCTAssertEqual(result, "application/json")
    }

    // MARK: - Sensitive Body Key Masking

    func test_maskJSON_masksPasswordKey() {
        let input: [String: Any] = ["username": "rick", "password": "portal123"]
        let result = sut.maskJSON(input, keys: ["password"]) as? [String: Any]

        XCTAssertEqual(result?["username"] as? String, "rick")
        XCTAssertEqual(result?["password"] as? String, "***")
    }

    func test_maskJSON_masksKeyCaseInsensitive() {
        let input: [String: Any] = ["Password": "secret"]
        let result = sut.maskJSON(input, keys: ["password"]) as? [String: Any]

        XCTAssertEqual(result?["Password"] as? String, "***")
    }

    func test_maskJSON_masksNestedKeys() {
        let input: [String: Any] = ["user": ["name": "Rick", "token": "hidden-value"]]
        let result = sut.maskJSON(input, keys: ["token"]) as? [String: Any]
        let nested = result?["user"] as? [String: Any]

        XCTAssertEqual(nested?["name"] as? String, "Rick")
        XCTAssertEqual(nested?["token"] as? String, "***")
    }

    func test_maskJSON_masksKeysInsideArrayElements() {
        let input: [Any] = [["password": "secret1"], ["password": "secret2"]]
        let result = sut.maskJSON(input, keys: ["password"]) as? [[String: Any]]

        XCTAssertEqual(result?[0]["password"] as? String, "***")
        XCTAssertEqual(result?[1]["password"] as? String, "***")
    }

    func test_maskJSON_doesNotMaskNonSensitiveKeys() {
        let input: [String: Any] = ["name": "Rick Sanchez", "id": 1]
        let result = sut.maskJSON(input, keys: ["password"]) as? [String: Any]

        XCTAssertEqual(result?["name"] as? String, "Rick Sanchez")
    }

    // MARK: - prettyPrinted — Non-JSON body

    func test_prettyPrinted_returnsUTF8String_forPlainText() {
        let data = "hello world".data(using: .utf8)!
        let result = sut.prettyPrinted(data: data, maskingKeys: [])
        XCTAssertEqual(result, "hello world")
    }

    func test_prettyPrinted_returnsBytePlaceholder_forBinaryData() {
        let data = Data([0xFF, 0xFE, 0x00]) // invalid UTF-8
        let result = sut.prettyPrinted(data: data, maskingKeys: [])
        XCTAssertEqual(result, "<3 bytes>")
    }

    // MARK: - Body Truncation

    func test_truncated_doesNotTruncate_whenWithinLimit() {
        let shortLogger = NetworkLogger(subsystem: "com.test", logLevel: .verbose, maxBodyLogLength: 100)
        let short = String(repeating: "a", count: 50)
        XCTAssertEqual(shortLogger.truncated(short), short)
    }

    func test_truncated_truncates_whenOverLimit() {
        let shortLogger = NetworkLogger(subsystem: "com.test", logLevel: .verbose, maxBodyLogLength: 10)
        let long = String(repeating: "a", count: 50)
        let result = shortLogger.truncated(long)
        XCTAssertTrue(result.contains("more chars"))
        XCTAssertTrue(result.hasPrefix(String(repeating: "a", count: 10)))
    }

    func test_truncated_noLimit_whenMaxBodyLogLengthIsZero() {
        let unlimitedLogger = NetworkLogger(subsystem: "com.test", logLevel: .verbose, maxBodyLogLength: 0)
        let long = String(repeating: "a", count: 5000)
        XCTAssertEqual(unlimitedLogger.truncated(long), long)
    }

    // MARK: - cURL Single-Quote Escaping

    func test_shellEscaped_replacesSingleQuoteWithPOSIXSequence() {
        let result = sut.shellEscaped("Bearer it's'token")
        XCTAssertEqual(result, "Bearer it'\\''s'\\''token")
    }

    func test_shellEscaped_noSingleQuote_returnsUnchanged() {
        let result = sut.shellEscaped("Bearer safetoken123")
        XCTAssertEqual(result, "Bearer safetoken123")
    }

    func test_shellEscaped_bodyWithMultipleSingleQuotes_escapesAll() {
        let result = sut.shellEscaped("it's a 'test' payload")
        XCTAssertEqual(result, "it'\\''s a '\\''test'\\'' payload")
    }
}
