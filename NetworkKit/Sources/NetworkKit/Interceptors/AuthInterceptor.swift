//
//  AuthInterceptor.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - AuthInterceptor

public final class AuthInterceptor: AuthenticationInterceptor {

    // MARK: - Properties

    private let tokenProvider: TokenProviderProtocol
    /// Coordinator for token refresh, auto-created if provider supports it.
    private let coordinator: TokenRefreshCoordinator?

    // MARK: - Init

    public init(tokenProvider: TokenProviderProtocol) {
        self.tokenProvider = tokenProvider
        if let refreshable = tokenProvider as? any TokenRefreshProviderProtocol {
            self.coordinator = TokenRefreshCoordinator(provider: refreshable)
        } else {
            self.coordinator = nil
        }
    }

    // MARK: - NetworkInterceptorProtocol

    public func adapt(_ request: URLRequest) async throws -> URLRequest {
        // Don't override an Authorization header explicitly set by the caller.
        guard request.value(forHTTPHeaderField: "Authorization") == nil else { return request }
        guard let token = try await tokenProvider.token() else { return request }

        var mutableRequest = request
        mutableRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return mutableRequest
    }

    // MARK: - AuthenticationInterceptor

    public func handleUnauthorized(_ request: URLRequest) async throws -> URLRequest? {
        guard let coordinator else { return nil }

        let newToken = try await coordinator.refreshIfNeeded()

        var refreshedRequest = request
        // Replace with refreshed token.
        refreshedRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
        return refreshedRequest
    }

    // MARK: - Public

    /// Clears the refresh coordinator on sign-out.
    public func invalidate() async {
        await coordinator?.invalidate()
    }
}
