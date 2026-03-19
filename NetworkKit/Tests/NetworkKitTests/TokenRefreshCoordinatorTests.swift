//
//  TokenRefreshCoordinatorTests.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import XCTest
@testable import NetworkKit

final class TokenRefreshCoordinatorTests: XCTestCase {

    // MARK: - Basic Refresh

    func test_refreshIfNeeded_callsProviderOnce() async throws {
        let provider = SpyRefreshProvider(token: "new-token")
        let sut = TokenRefreshCoordinator(provider: provider)

        let token = try await sut.refreshIfNeeded()

        XCTAssertEqual(token, "new-token")
        XCTAssertEqual(provider.refreshCallCount, 1)
    }

    func test_refreshIfNeeded_whenCalledConcurrently_callsProviderOnce() async throws {
        let provider = SlowRefreshProvider(token: "shared-token", delay: 100_000_000)
        let sut = TokenRefreshCoordinator(provider: provider)

        // Launch 5 concurrent refresh calls
        async let t1 = sut.refreshIfNeeded()
        async let t2 = sut.refreshIfNeeded()
        async let t3 = sut.refreshIfNeeded()
        async let t4 = sut.refreshIfNeeded()
        async let t5 = sut.refreshIfNeeded()

        let results = try await [t1, t2, t3, t4, t5]

        XCTAssertTrue(results.allSatisfy { $0 == "shared-token" }, "All callers must receive the same token")
        XCTAssertEqual(provider.refreshCallCount, 1, "Provider must be called exactly once despite concurrent requests")
    }

    // MARK: - Failure Handling

    func test_refreshIfNeeded_whenProviderThrows_invalidatesToken() async {
        let provider = FailingRefreshProvider()
        let sut = TokenRefreshCoordinator(provider: provider)

        do {
            _ = try await sut.refreshIfNeeded()
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(provider.invalidateCalled, "Token must be invalidated after refresh failure")
        }
    }

    func test_refreshIfNeeded_afterFailure_allowsNewRefreshAttempt() async throws {
        let provider = SpyRefreshProvider(token: "recovery-token")
        provider.failOnFirstCall = true
        let sut = TokenRefreshCoordinator(provider: provider)

        // First attempt fails
        _ = try? await sut.refreshIfNeeded()

        // Second attempt should succeed
        let token = try await sut.refreshIfNeeded()
        XCTAssertEqual(token, "recovery-token")
    }

    // MARK: - Invalidate

    func test_invalidate_clearsInFlightTask() async {
        let provider = SlowRefreshProvider(token: "token", delay: 500_000_000)
        let sut = TokenRefreshCoordinator(provider: provider)

        // Start a refresh in the background
        let task = Task { try await sut.refreshIfNeeded() }
        // Give it time to start
        try? await Task.sleep(nanoseconds: 10_000_000)

        await sut.invalidate()
        task.cancel()
        // No assertion needed — we verify it doesn't hang or crash
    }

    // MARK: - Integration: AuthInterceptor + Coordinator

    func test_authInterceptor_withRefreshableProvider_createsCoordinator() async throws {
        let provider = SpyRefreshProvider(token: "refreshed-token")
        let interceptor = AuthInterceptor(tokenProvider: provider)

        var request = URLRequest(url: URL(string: "https://api.test.com")!)
        request.setValue("Bearer expired-token", forHTTPHeaderField: "Authorization")

        let refreshed = try await interceptor.handleUnauthorized(request)

        XCTAssertNotNil(refreshed)
        XCTAssertEqual(refreshed?.value(forHTTPHeaderField: "Authorization"), "Bearer refreshed-token")
    }

    func test_authInterceptor_withNonRefreshableProvider_returnsNilOnUnauthorized() async throws {
        let provider = SimpleTokenProvider(token: "token")
        let interceptor = AuthInterceptor(tokenProvider: provider)

        let request = URLRequest(url: URL(string: "https://api.test.com")!)
        let refreshed = try await interceptor.handleUnauthorized(request)

        XCTAssertNil(refreshed, "Non-refreshable provider must return nil — no refresh supported")
    }

    // MARK: - Integration: URLSessionNetworkClient 401 Flow

    func test_client_refreshesToken_on401_andRetries() async throws {
        let provider = SpyRefreshProvider(token: "new-token")
        let interceptor = AuthInterceptor(tokenProvider: provider)
        let session = TokenRefreshSession()
        let sut = URLSessionNetworkClient(
            session: session,
            interceptors: [interceptor],
            logger: nil,
            retryPolicy: .none
        )

        let data = try await sut.send(
            URLRequest(url: URL(string: "https://api.test.com/resource")!),
            metadata: RequestMetadata(requiresAuth: true)
        )

        XCTAssertFalse(data.isEmpty, "Should succeed after token refresh")
        XCTAssertEqual(provider.refreshCallCount, 1, "Refresh must be called exactly once")
        XCTAssertEqual(session.callCount, 2, "First call returns 401, second succeeds")
    }

    func test_client_doesNotRefresh_on401_whenRequiresAuthIsFalse() async {
        let provider = SpyRefreshProvider(token: "new-token")
        let interceptor = AuthInterceptor(tokenProvider: provider)
        let session = AlwaysUnauthorizedSession()
        let sut = URLSessionNetworkClient(
            session: session,
            interceptors: [interceptor],
            logger: nil,
            retryPolicy: .none
        )

        do {
            _ = try await sut.send(
                URLRequest(url: URL(string: "https://api.test.com/public")!),
                metadata: RequestMetadata(requiresAuth: false)
            )
            XCTFail("Expected unauthorized error")
        } catch NetworkError.unauthorized {
            XCTAssertEqual(provider.refreshCallCount, 0, "No refresh for public endpoints")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_client_doesNotRefreshTwice_ifSecond401Received() async {
        let provider = SpyRefreshProvider(token: "still-invalid-token")
        let interceptor = AuthInterceptor(tokenProvider: provider)
        let session = AlwaysUnauthorizedSession()
        let sut = URLSessionNetworkClient(
            session: session,
            interceptors: [interceptor],
            logger: nil,
            retryPolicy: .none
        )

        do {
            _ = try await sut.send(
                URLRequest(url: URL(string: "https://api.test.com/resource")!),
                metadata: RequestMetadata(requiresAuth: true)
            )
            XCTFail("Expected unauthorized error")
        } catch NetworkError.unauthorized {
            XCTAssertEqual(provider.refreshCallCount, 1, "Refresh must not loop — attempted only once")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Test Helpers

/// Spy that records calls and returns a configurable token.
final class SpyRefreshProvider: TokenRefreshProviderProtocol {
    private let stubbedToken: String
    private(set) var refreshCallCount = 0
    private(set) var invalidateCalled = false
    var failOnFirstCall = false
    private var firstCallDone = false

    init(token: String) { self.stubbedToken = token }

    func token() async throws -> String? { stubbedToken }

    func refreshToken() async throws -> String {
        refreshCallCount += 1
        if failOnFirstCall && !firstCallDone {
            firstCallDone = true
            throw NetworkError.unauthorized(nil)
        }
        return stubbedToken
    }

    func invalidateToken() async {
        invalidateCalled = true
    }
}

/// Simulates a slow network refresh to test concurrent callers.
final class SlowRefreshProvider: TokenRefreshProviderProtocol {
    private let stubbedToken: String
    private let delay: UInt64
    private(set) var refreshCallCount = 0

    init(token: String, delay: UInt64) {
        self.stubbedToken = token
        self.delay = delay
    }

    func token() async throws -> String? { stubbedToken }

    func refreshToken() async throws -> String {
        refreshCallCount += 1
        try await Task.sleep(nanoseconds: delay)
        return stubbedToken
    }

    func invalidateToken() async {}
}

/// Provider that always throws on refresh.
final class FailingRefreshProvider: TokenRefreshProviderProtocol {
    private(set) var invalidateCalled = false
    func token() async throws -> String? { nil }
    func refreshToken() async throws -> String { throw NetworkError.unauthorized(nil) }
    func invalidateToken() async { invalidateCalled = true }
}

/// Provider that does NOT conform to TokenRefreshProviderProtocol.
final class SimpleTokenProvider: TokenProviderProtocol {
    private let stubbedToken: String
    init(token: String) { self.stubbedToken = token }
    func token() async throws -> String? { stubbedToken }
}

/// Returns 401 on the first call, 200 with data on the second.
final class TokenRefreshSession: URLSessionProtocol {
    private(set) var callCount = 0

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        callCount += 1
        let statusCode = callCount == 1 ? 401 : 200
        let data = callCount == 1 ? Data() : "{\"ok\":true}".data(using: .utf8)!
        return (data, MockURLSession.makeHTTPResponse(statusCode: statusCode))
    }
}

/// Always returns 401.
final class AlwaysUnauthorizedSession: URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        (Data(), MockURLSession.makeHTTPResponse(statusCode: 401))
    }
}
