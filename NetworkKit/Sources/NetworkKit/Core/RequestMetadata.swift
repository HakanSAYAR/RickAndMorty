//
//  RequestMetadata.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - RequestMetadata
// Per-request behavior flags (auth, retry) separate from URLRequest.

public struct RequestMetadata {
    /// When false, AuthenticationInterceptor conformers are skipped for this request.
    public let requiresAuth: Bool
    /// When false, the request will not be retried on failure regardless of RetryPolicy.
    public let allowsRetry: Bool

    public static let `default` = RequestMetadata()

    public init(requiresAuth: Bool = true, allowsRetry: Bool = true) {
        self.requiresAuth = requiresAuth
        self.allowsRetry = allowsRetry
    }
}
