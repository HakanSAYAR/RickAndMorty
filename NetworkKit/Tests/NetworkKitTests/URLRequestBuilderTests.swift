//
//  URLRequestBuilderTests.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import XCTest
@testable import NetworkKit

final class URLRequestBuilderTests: XCTestCase {

    private var sut: URLRequestBuilder!
    private var config: NetworkConfiguration!

    override func setUp() {
        super.setUp()
        sut = URLRequestBuilder()
        config = NetworkConfiguration(baseURL: URL(string: "https://rickandmortyapi.com/api")!)
    }

    override func tearDown() {
        sut = nil
        config = nil
        super.tearDown()
    }

    // MARK: - URL

    func test_build_withBasePath_createsCorrectURL() throws {
        let endpoint = MockEndpoint(path: "/character", method: .get)

        let request = try sut.build(from: endpoint, configuration: config)

        XCTAssertEqual(request.url?.absoluteString, "https://rickandmortyapi.com/api/character")
    }

    func test_build_withStringQueryParameter_appendsToURL() throws {
        let endpoint = MockEndpoint(path: "/character", queryParameters: ["name": .string("Rick")])

        let request = try sut.build(from: endpoint, configuration: config)

        XCTAssertTrue(request.url?.absoluteString.contains("name=Rick") ?? false)
    }

    func test_build_withIntQueryParameter_appendsToURL() throws {
        let endpoint = MockEndpoint(path: "/character", queryParameters: ["page": .int(2)])

        let request = try sut.build(from: endpoint, configuration: config)

        XCTAssertTrue(request.url?.absoluteString.contains("page=2") ?? false)
    }

    func test_build_withBoolQueryParameter_appendsToURL() throws {
        let endpoint = MockEndpoint(queryParameters: ["active": .bool(true)])

        let request = try sut.build(from: endpoint, configuration: config)

        XCTAssertTrue(request.url?.absoluteString.contains("active=true") ?? false)
    }

    func test_build_withArrayQueryParameter_repeatsKey() throws {
        let endpoint = MockEndpoint(queryParameters: ["ids": .array(["1", "2", "3"])])

        let request = try sut.build(from: endpoint, configuration: config)

        let urlString = request.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("ids=1"))
        XCTAssertTrue(urlString.contains("ids=2"))
        XCTAssertTrue(urlString.contains("ids=3"))
    }

    func test_build_withDateQueryParameter_formatsCorrectly() throws {
        var components = DateComponents()
        components.year = 2026; components.month = 1; components.day = 15
        components.hour = 0; components.minute = 0; components.second = 0
        let date = Calendar(identifier: .gregorian).date(from: components)!

        let endpoint = MockEndpoint(queryParameters: ["from": .date(date, format: "yyyy-MM-dd")])

        let request = try sut.build(from: endpoint, configuration: config)

        XCTAssertTrue(request.url?.absoluteString.contains("from=2026-01-15") ?? false)
    }

    func test_build_baseURLQueryPreserved_whenEndpointAddsParams() throws {
        let configWithQuery = NetworkConfiguration(
            baseURL: URL(string: "https://rickandmortyapi.com/api?version=2")!
        )
        let endpoint = MockEndpoint(path: "/character", queryParameters: ["name": .string("Rick")])

        let request = try sut.build(from: endpoint, configuration: configWithQuery)

        let urlString = request.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("version=2"), "baseURL query param should be preserved")
        XCTAssertTrue(urlString.contains("name=Rick"), "endpoint query param should be present")
    }

    func test_build_withIntArrayQueryParameter_repeatsKey() throws {
        let endpoint = MockEndpoint(queryParameters: ["ids": .intArray([1, 2, 3])])

        let request = try sut.build(from: endpoint, configuration: config)

        let urlString = request.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("ids=1"))
        XCTAssertTrue(urlString.contains("ids=2"))
        XCTAssertTrue(urlString.contains("ids=3"))
    }

    func test_build_withStringArray_regressionCheck() throws {
        let endpoint = MockEndpoint(queryParameters: ["tags": .array(["a", "b", "c"])])

        let request = try sut.build(from: endpoint, configuration: config)

        let urlString = request.url?.absoluteString ?? ""
        XCTAssertTrue(urlString.contains("tags=a"))
        XCTAssertTrue(urlString.contains("tags=b"))
        XCTAssertTrue(urlString.contains("tags=c"))
    }

    func test_build_withEmptyQueryParameters_doesNotAppendQuestionMark() throws {
        let endpoint = MockEndpoint(queryParameters: [:])

        let request = try sut.build(from: endpoint, configuration: config)

        XCTAssertFalse(request.url?.absoluteString.contains("?") ?? true)
    }

    func test_build_withInvalidBaseURL_throwsInvalidURL() {
        // URLComponents will fail on a totally broken URL string passed as URL
        // so we test by crafting a config whose URL produces nil components.
        // The builder throws .invalidURL when components.url returns nil.
        let endpoint = MockEndpoint(path: " invalid path with spaces")

        XCTAssertThrowsError(try sut.build(from: endpoint, configuration: config)) { error in
            guard case NetworkError.invalidURL = error else {
                XCTFail("Expected NetworkError.invalidURL, got \(error)")
                return
            }
        }
    }

    // MARK: - HTTP Method

    func test_build_setsCorrectHTTPMethod() throws {
        let methods: [HTTPMethod] = [.get, .post, .put, .delete, .patch, .head, .options]

        for method in methods {
            let request = try sut.build(from: MockEndpoint(method: method), configuration: config)
            XCTAssertEqual(request.httpMethod, method.rawValue)
        }
    }

    // MARK: - Headers

    func test_build_appliesDefaultAcceptHeader() throws {
        let request = try sut.build(from: MockEndpoint(), configuration: config)

        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
    }

    func test_build_doesNotSetContentType_forBodylessRequest() throws {
        let request = try sut.build(from: MockEndpoint(method: .get), configuration: config)

        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
    }

    func test_build_setsContentTypeJSON_whenBodyIsPresent() throws {
        let bodyData = "{\"name\":\"Rick\"}".data(using: .utf8)!
        let endpoint = MockEndpoint(method: .post, body: bodyData)

        let request = try sut.build(from: endpoint, configuration: config)

        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func test_build_endpointContentTypeOverridesDefault() throws {
        let bodyData = Data([0x01, 0x02])
        let endpoint = MockEndpoint(
            method: .post,
            headers: [.contentType("application/octet-stream")],
            body: bodyData
        )

        let request = try sut.build(from: endpoint, configuration: config)

        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/octet-stream")
    }

    func test_build_appendsEndpointSpecificHeaders() throws {
        let endpoint = MockEndpoint(headers: [HTTPHeader(name: "X-Custom-Header", value: "MyValue")])

        let request = try sut.build(from: endpoint, configuration: config)

        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom-Header"), "MyValue")
    }

    // MARK: - Body

    func test_build_setsHTTPBody_whenEndpointProvidesOne() throws {
        let bodyData = "{\"name\":\"Rick\"}".data(using: .utf8)!
        let endpoint = MockEndpoint(method: .post, body: bodyData)

        let request = try sut.build(from: endpoint, configuration: config)

        XCTAssertEqual(request.httpBody, bodyData)
    }

    func test_build_nilBody_whenEndpointHasNoBody() throws {
        let request = try sut.build(from: MockEndpoint(method: .get), configuration: config)

        XCTAssertNil(request.httpBody)
    }

    func test_build_whenMakeBodyThrows_propagatesError() {
        var endpoint = MockEndpoint(method: .post)
        endpoint.shouldThrowOnMakeBody = true

        XCTAssertThrowsError(try sut.build(from: endpoint, configuration: config)) { error in
            guard case NetworkError.invalidURL = error else {
                XCTFail("Expected NetworkError to be thrown, got \(error)")
                return
            }
        }
    }

    // MARK: - JSONBodyEncoder

    func test_build_usesEndpointBodyEncoder_forEncoding() throws {
        struct Payload: Encodable { let firstName: String }

        struct EncodingEndpoint: Endpoint {
            var path: String = "/test"
            var method: HTTPMethod = .post
            var bodyEncoder = JSONBodyEncoder(keyEncodingStrategy: .convertToSnakeCase)
            func makeBody() throws -> Data? { try encode(Payload(firstName: "Rick")) }
        }

        let request = try sut.build(from: EncodingEndpoint(), configuration: config)
        let body = try XCTUnwrap(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]

        XCTAssertEqual(json?["first_name"], "Rick")
        XCTAssertNil(json?["firstName"])
    }

    // MARK: - Timeout

    func test_build_usesConfigurationTimeout() throws {
        let customConfig = NetworkConfiguration(
            baseURL: URL(string: "https://example.com")!,
            timeoutInterval: 60
        )

        let request = try sut.build(from: MockEndpoint(), configuration: customConfig)

        XCTAssertEqual(request.timeoutInterval, 60)
    }

    // MARK: - URL Normalization

    func test_build_withTrailingSlashOnBaseURL_doesNotProduceDoubleSlash() throws {
        let trailingSlashConfig = NetworkConfiguration(
            baseURL: URL(string: "https://rickandmortyapi.com/api/")!
        )

        let request = try sut.build(from: MockEndpoint(path: "/character"), configuration: trailingSlashConfig)

        XCTAssertEqual(request.url?.absoluteString, "https://rickandmortyapi.com/api/character")
    }

    func test_build_withNoLeadingSlashOnPath_stillBuildsCorrectURL() throws {
        let request = try sut.build(from: MockEndpoint(path: "character"), configuration: config)

        XCTAssertEqual(request.url?.absoluteString, "https://rickandmortyapi.com/api/character")
    }

    func test_build_withTrailingSlashOnBaseAndNoLeadingSlashOnPath_buildsCorrectURL() throws {
        let trailingSlashConfig = NetworkConfiguration(
            baseURL: URL(string: "https://rickandmortyapi.com/api/")!
        )

        let request = try sut.build(
            from: MockEndpoint(path: "character"),
            configuration: trailingSlashConfig
        )

        XCTAssertEqual(request.url?.absoluteString, "https://rickandmortyapi.com/api/character")
    }
}
