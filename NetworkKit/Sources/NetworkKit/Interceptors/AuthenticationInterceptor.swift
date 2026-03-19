//
//  AuthenticationInterceptor.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - AuthenticationInterceptor
// Marker + capability protocol.
// URLSessionNetworkClient uses it to:
//   1. Skip auth injection when RequestMetadata.requiresAuth is false.
//   2. Trigger a token refresh when a 401 is received.

public protocol AuthenticationInterceptor: NetworkInterceptorProtocol {
    /// Called once when a 401 is received.
    /// Should refresh the token and return the original request with the new
    /// Authorization header applied. Return nil if refresh is not supported.
    func handleUnauthorized(_ request: URLRequest) async throws -> URLRequest?
}

// Default no-op so simple conformers don't need to implement this.
public extension AuthenticationInterceptor {
    func handleUnauthorized(_ request: URLRequest) async throws -> URLRequest? { nil }
}
