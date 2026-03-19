//
//  TokenRefreshProviderProtocol.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - TokenRefreshProviderProtocol
// Extends TokenProviderProtocol for apps that support silent token refresh.
// Implement this instead of TokenProviderProtocol to enable the
// TokenRefreshCoordinator. AuthInterceptor detects the conformance automatically.

public protocol TokenRefreshProviderProtocol: TokenProviderProtocol {
    /// Performs a network call to obtain a new access token.
    /// Implementations must persist the new token so that subsequent
    /// token() calls return it without another network round-trip.
    func refreshToken() async throws -> String

    /// Clears any cached or persisted token.
    /// Called automatically by TokenRefreshCoordinator when refresh fails,
    /// so the app can present a login screen on the next auth check.
    func invalidateToken() async
}
