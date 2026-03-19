//
//  TokenRefreshCoordinator.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - TokenRefreshCoordinator
// Actor ensures only one concurrent refresh; subsequent callers reuse the in-flight task.

public actor TokenRefreshCoordinator {

    // MARK: - Properties

    private let provider: any TokenRefreshProviderProtocol
    private var refreshTask: Task<String, Error>?

    // MARK: - Init

    public init(provider: any TokenRefreshProviderProtocol) {
        self.provider = provider
    }

    // MARK: - Public

    /// Returns a fresh token, reusing any in-flight refresh.
    public func refreshIfNeeded() async throws -> String {
        // Reuse the in-flight task — all concurrent callers share one refresh.
        if let existing = refreshTask {
            return try await existing.value
        }

        let task = Task<String, Error> { [provider] in
            try await provider.refreshToken()
        }
        refreshTask = task

        do {
            let token = try await task.value
            refreshTask = nil
            return token
        } catch {
            // Clear credentials on refresh failure to force re-login.
            refreshTask = nil
            await provider.invalidateToken()
            throw error
        }
    }

    /// Cancels any in-flight refresh and clears state.
    /// Call on explicit sign-out so a stale Task cannot surface a token
    /// belonging to the previous session.
    public func invalidate() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
