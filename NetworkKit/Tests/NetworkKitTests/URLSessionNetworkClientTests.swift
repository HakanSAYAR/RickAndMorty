//
//  URLSessionNetworkClientTests.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import XCTest
@testable import NetworkKit

final class URLSessionNetworkClientTests: XCTestCase {

    private var sut: URLSessionNetworkClient!
    private var mockSession: MockURLSession!
    private var mockLogger: MockNetworkLogger!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        mockLogger = MockNetworkLogger()
        sut = URLSessionNetworkClient(
            session: mockSession,
            interceptors: [],
            logger: mockLogger,
            retryPolicy: .none
        )
    }

    override func tearDown() {
        sut = nil
        mockSession = nil
        mockLogger = nil
        super.tearDown()
    }

    // MARK: - Success

    func test_send_withSuccessfulResponse_returnsData() async throws {
        let expected = "{\"id\":1}".data(using: .utf8)!
        mockSession.stub(data: expected, statusCode: 200)

        let result = try await sut.send(makeRequest())

        XCTAssertEqual(result, expected)
    }

    func test_send_logsRequestAndResponse() async throws {
        mockSession.stub(data: Data(), statusCode: 200)

        _ = try await sut.send(makeRequest())

        XCTAssertEqual(mockLogger.loggedRequests.count, 1)
        XCTAssertEqual(mockLogger.loggedResponses.count, 1)
    }

    func test_send_logsCURL() async throws {
        mockSession.stub(data: Data(), statusCode: 200)

        _ = try await sut.send(makeRequest())

        XCTAssertEqual(mockLogger.loggedCURLRequests.count, 1)
    }

    // MARK: - Status Code Handling

    func test_send_with401_throwsUnauthorized() async {
        mockSession.stub(data: Data(), statusCode: 401)
        await assertThrows(NetworkError.unauthorized(nil)) { _ = try await self.sut.send(self.makeRequest()) }
    }

    func test_send_with403_throwsForbidden() async {
        mockSession.stub(data: Data(), statusCode: 403)
        await assertThrows(NetworkError.forbidden(nil)) { _ = try await self.sut.send(self.makeRequest()) }
    }

    func test_send_with404_throwsNotFound() async {
        mockSession.stub(data: Data(), statusCode: 404)
        await assertThrows(NetworkError.notFound(nil)) { _ = try await self.sut.send(self.makeRequest()) }
    }

    func test_send_with500_throwsServerError() async {
        mockSession.stub(data: Data(), statusCode: 500)
        await assertThrows(NetworkError.serverError(500, nil)) { _ = try await self.sut.send(self.makeRequest()) }
    }

    func test_send_with418_throwsStatusCode() async {
        mockSession.stub(data: Data(), statusCode: 418)
        await assertThrows(NetworkError.statusCode(418, nil)) { _ = try await self.sut.send(self.makeRequest()) }
    }

    // MARK: - URLError Mapping

    func test_send_withNotConnectedToInternet_throwsNoInternetConnection() async {
        mockSession.stubFailure(URLError(.notConnectedToInternet))
        await assertThrows(NetworkError.noInternetConnection) { _ = try await self.sut.send(self.makeRequest()) }
    }

    func test_send_withTimedOut_throwsTimeout() async {
        mockSession.stubFailure(URLError(.timedOut))
        await assertThrows(NetworkError.timeout) { _ = try await self.sut.send(self.makeRequest()) }
    }

    func test_send_withURLErrorCancelled_throwsCancellationError() async {
        mockSession.stubFailure(URLError(.cancelled))

        do {
            _ = try await sut.send(makeRequest())
            XCTFail("Expected CancellationError")
        } catch is CancellationError {
            // success
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    // MARK: - Interceptors

    func test_send_appliesInterceptorsToRequest() async throws {
        final class AddHeaderInterceptor: NetworkInterceptorProtocol {
            func adapt(_ request: URLRequest) async throws -> URLRequest {
                var r = request
                r.setValue("test-value", forHTTPHeaderField: "X-Test")
                return r
            }
        }

        mockSession.stub(data: Data(), statusCode: 200)
        sut = URLSessionNetworkClient(
            session: mockSession,
            interceptors: [AddHeaderInterceptor()],
            logger: mockLogger,
            retryPolicy: .none
        )

        _ = try await sut.send(makeRequest())

        XCTAssertEqual(mockSession.receivedRequests.first?.value(forHTTPHeaderField: "X-Test"), "test-value")
    }

    func test_send_skipsAuthInterceptor_whenRequiresAuthIsFalse() async throws {
        final class SpyAuthInterceptor: AuthenticationInterceptor {
            private(set) var adaptCallCount = 0
            func adapt(_ request: URLRequest) async throws -> URLRequest {
                adaptCallCount += 1
                return request
            }
        }

        let spy = SpyAuthInterceptor()
        mockSession.stub(data: Data(), statusCode: 200)
        sut = URLSessionNetworkClient(
            session: mockSession,
            interceptors: [spy],
            logger: mockLogger,
            retryPolicy: .none
        )

        _ = try await sut.send(makeRequest(), metadata: RequestMetadata(requiresAuth: false))

        XCTAssertEqual(spy.adaptCallCount, 0, "AuthenticationInterceptor must be skipped when requiresAuth is false")
    }

    func test_send_runsAuthInterceptor_whenRequiresAuthIsTrue() async throws {
        final class SpyAuthInterceptor: AuthenticationInterceptor {
            private(set) var adaptCallCount = 0
            func adapt(_ request: URLRequest) async throws -> URLRequest {
                adaptCallCount += 1
                return request
            }
        }

        let spy = SpyAuthInterceptor()
        mockSession.stub(data: Data(), statusCode: 200)
        sut = URLSessionNetworkClient(
            session: mockSession,
            interceptors: [spy],
            logger: mockLogger,
            retryPolicy: .none
        )

        _ = try await sut.send(makeRequest(), metadata: RequestMetadata(requiresAuth: true))

        XCTAssertEqual(spy.adaptCallCount, 1)
    }

    // MARK: - Invalid response logging

    func test_send_logsError_whenResponseIsNotHTTPURLResponse() async {
        // Stub a non-HTTP URLResponse
        let plainResponse = URLResponse(
            url: URL(string: "https://test.com")!,
            mimeType: nil,
            expectedContentLength: 0,
            textEncodingName: nil
        )
        mockSession.result = .success((Data(), plainResponse))

        _ = try? await sut.send(makeRequest())

        XCTAssertEqual(mockLogger.loggedErrors.count, 1)
    }

    // MARK: - Helpers

    private func makeRequest(url: String = "https://rickandmortyapi.com/api/character") -> URLRequest {
        URLRequest(url: URL(string: url)!)
    }

    private func assertThrows<E: Error & Equatable>(
        _ expected: E,
        operation: () async throws -> Void
    ) async {
        do {
            try await operation()
            XCTFail("Expected \(expected) to be thrown")
        } catch let error as E {
            XCTAssertEqual(error, expected)
        } catch {
            XCTFail("Expected \(expected) but got \(error)")
        }
    }
}

// MARK: - NetworkError: Equatable

extension NetworkError: Equatable {
    public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.invalidResponse, .invalidResponse),
             (.noInternetConnection, .noInternetConnection),
             (.timeout, .timeout):
            return true
        case (.unauthorized(let l), .unauthorized(let r)): return l == r
        case (.forbidden(let l), .forbidden(let r)):       return l == r
        case (.notFound(let l), .notFound(let r)):         return l == r
        case (.statusCode(let lc, let ld), .statusCode(let rc, let rd)): return lc == rc && ld == rd
        case (.serverError(let lc, let ld), .serverError(let rc, let rd)): return lc == rc && ld == rd
        default: return false
        }
    }
}
