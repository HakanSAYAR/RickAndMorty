//
//  NetworkStackTests.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import XCTest
@testable import NetworkKit

final class NetworkStackTests: XCTestCase {

    private let config = NetworkConfiguration(baseURL: URL(string: "https://example.com")!)

    // MARK: - apiService

    func test_make_apiService_isNotNil_withoutTokenProvider() {
        let stack = NetworkFactory.make(configuration: config)
        XCTAssertNotNil(stack.apiService)
    }

    func test_make_apiService_isNotNil_withTokenProvider() {
        let stack = NetworkFactory.make(configuration: config, tokenProvider: StubTokenProvider())
        XCTAssertNotNil(stack.apiService)
    }

    // MARK: - authInterceptor

    func test_make_withTokenProvider_exposesAuthInterceptor() {
        let stack = NetworkFactory.make(configuration: config, tokenProvider: StubTokenProvider())
        XCTAssertNotNil(stack.authInterceptor)
    }

    func test_make_withoutTokenProvider_authInterceptorIsNil() {
        // nil = no token provider, no auth refresh lifecycle, pipeline is not auth-aware
        let stack = NetworkFactory.make(configuration: config)
        XCTAssertNil(stack.authInterceptor)
    }
}

// MARK: - StubTokenProvider

private final class StubTokenProvider: TokenProviderProtocol {
    func token() async throws -> String? { "stub-token" }
}
