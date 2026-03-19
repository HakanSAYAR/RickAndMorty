//
//  NetworkStack.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - NetworkStack
// The composed result of NetworkFactory.make(...).
// Holds the ready-to-use API service and, when a token provider was supplied,
// the auth interceptor whose lifecycle the app can manage (e.g. sign-out).
//
// Exposed as concrete type: invalidate() is implementation-specific.

public struct NetworkStack {
    public let apiService: APIServiceProtocol
    /// Non-nil only when a TokenProviderProtocol was supplied to NetworkFactory.make.
    /// nil = no token provider, no auth refresh lifecycle, pipeline is not auth-aware.
    public let authInterceptor: AuthInterceptor?
}
