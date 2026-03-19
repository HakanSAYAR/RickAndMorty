//
//  AuthInterceptorTests.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import XCTest
@testable import NetworkKit

final class AuthInterceptorTests: XCTestCase {

    // MARK: - Helpers

    private func makeInterceptor(token: String?) -> AuthInterceptor {
        AuthInterceptor(tokenProvider: StubTokenProvider(token: token))
    }

    private func makeRequest(authHeader: String? = nil) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.test.com/resource")!)
        if let authHeader { request.setValue(authHeader, forHTTPHeaderField: "Authorization") }
        return request
    }

    // MARK: - Token Injection

    func test_adapt_injectsToken_whenNoAuthHeaderPresent() async throws {
        let sut = makeInterceptor(token: "abc123")

        let adapted = try await sut.adapt(makeRequest())

        XCTAssertEqual(adapted.value(forHTTPHeaderField: "Authorization"), "Bearer abc123")
    }

    func test_adapt_doesNotOverride_existingAuthorizationHeader() async throws {
        let sut = makeInterceptor(token: "new-token")

        let adapted = try await sut.adapt(makeRequest(authHeader: "Bearer original-token"))

        XCTAssertEqual(adapted.value(forHTTPHeaderField: "Authorization"), "Bearer original-token")
    }

    func test_adapt_doesNotInjectToken_whenProviderReturnsNil() async throws {
        let sut = makeInterceptor(token: nil)

        let adapted = try await sut.adapt(makeRequest())

        XCTAssertNil(adapted.value(forHTTPHeaderField: "Authorization"))
    }

    // MARK: - AuthenticationInterceptor conformance

    func test_authInterceptor_conformsToAuthenticationInterceptor() {
        let sut = makeInterceptor(token: nil)
        XCTAssertTrue(sut is AuthenticationInterceptor)
    }

    func test_adapt_doesNotLeaveInternalHeaders() async throws {
        // AuthInterceptor must never add internal X-NK-* headers
        let sut = makeInterceptor(token: "abc123")

        let adapted = try await sut.adapt(makeRequest())

        XCTAssertNil(adapted.value(forHTTPHeaderField: "X-NK-Requires-Auth"))
        XCTAssertNil(adapted.value(forHTTPHeaderField: "X-NK-Allows-Retry"))
    }
}

// MARK: - StubTokenProvider

private final class StubTokenProvider: TokenProviderProtocol {
    private let stubbedToken: String?
    init(token: String?) { self.stubbedToken = token }
    func token() async throws -> String? { stubbedToken }
}
