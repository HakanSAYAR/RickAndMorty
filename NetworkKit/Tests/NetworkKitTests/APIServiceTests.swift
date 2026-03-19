//
//  APIServiceTests.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import XCTest
@testable import NetworkKit

final class APIServiceTests: XCTestCase {

    private var sut: APIService!
    private var mockClient: MockNetworkClient!
    private var mockDecoder: MockResponseDecoder!
    private var config: NetworkConfiguration!

    override func setUp() {
        super.setUp()
        mockClient = MockNetworkClient()
        mockDecoder = MockResponseDecoder()
        config = NetworkConfiguration(baseURL: URL(string: "https://rickandmortyapi.com/api")!)
        sut = APIService(
            client: mockClient,
            builder: URLRequestBuilder(),
            decoder: mockDecoder,
            configuration: config
        )
    }

    override func tearDown() {
        sut = nil
        mockClient = nil
        mockDecoder = nil
        config = nil
        super.tearDown()
    }

    // MARK: - fetch<T>

    func test_fetch_withSuccessfulResponse_returnsDecodedValue() async throws {
        struct Character: Decodable, Equatable { let id: Int; let name: String }
        let expected = Character(id: 1, name: "Rick Sanchez")
        mockClient.result = .success(Data())
        mockDecoder.result = .success(expected)

        let result: Character = try await sut.fetch(endpoint: MockEndpoint())

        XCTAssertEqual(result, expected)
    }

    func test_fetch_callsClientExactlyOnce() async throws {
        struct Empty: Decodable {}
        mockClient.result = .success(Data())
        mockDecoder.result = .success(Empty())

        let _: Empty = try await sut.fetch(endpoint: MockEndpoint())

        XCTAssertEqual(mockClient.callCount, 1)
    }

    func test_fetch_whenClientThrows_propagatesError() async {
        mockClient.result = .failure(NetworkError.unauthorized(nil))

        do {
            let _: String = try await sut.fetch(endpoint: MockEndpoint())
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .unauthorized(nil))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_fetch_whenDecoderThrows_propagatesDecodingError() async {
        mockClient.result = .success(Data())
        mockDecoder.result = .failure(NetworkError.decoding(NSError(domain: "decode", code: 0)))

        do {
            let _: String = try await sut.fetch(endpoint: MockEndpoint())
            XCTFail("Expected decoding error")
        } catch NetworkError.decoding {
            // success
        } catch {
            XCTFail("Expected NetworkError.decoding, got \(error)")
        }
    }

    func test_fetch_buildsRequestWithCorrectURL() async throws {
        struct Empty: Decodable {}
        mockClient.result = .success(Data())
        mockDecoder.result = .success(Empty())

        let _: Empty = try await sut.fetch(endpoint: MockEndpoint(path: "/character"))

        XCTAssertEqual(
            mockClient.sentRequests.first?.url?.absoluteString,
            "https://rickandmortyapi.com/api/character"
        )
    }

    // MARK: - Metadata passthrough

    func test_fetch_passesRequiresAuthFalse_toClient() async throws {
        struct Empty: Decodable {}
        mockClient.result = .success(Data())
        mockDecoder.result = .success(Empty())

        let _: Empty = try await sut.fetch(endpoint: MockEndpoint(requiresAuth: false))

        XCTAssertEqual(mockClient.sentMetadata.first?.requiresAuth, false)
    }

    func test_fetch_passesAllowsRetryFalse_toClient() async throws {
        struct Empty: Decodable {}
        mockClient.result = .success(Data())
        mockDecoder.result = .success(Empty())

        let _: Empty = try await sut.fetch(endpoint: MockEndpoint(allowsRetry: false))

        XCTAssertEqual(mockClient.sentMetadata.first?.allowsRetry, false)
    }

    // MARK: - perform

    func test_perform_withSuccessfulResponse_doesNotThrow() async throws {
        mockClient.result = .success(Data())

        try await sut.perform(endpoint: MockEndpoint(method: .delete))

        XCTAssertEqual(mockClient.callCount, 1)
    }

    func test_perform_whenClientThrows_propagatesError() async {
        mockClient.result = .failure(NetworkError.notFound(nil))

        do {
            try await sut.perform(endpoint: MockEndpoint())
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .notFound(nil))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
