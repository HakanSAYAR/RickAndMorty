//
//  NetworkClientProtocol.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - NetworkClientProtocol

public protocol NetworkClientProtocol {
    func send(_ request: URLRequest, metadata: RequestMetadata) async throws -> Data
}

// MARK: - Convenience

public extension NetworkClientProtocol {
    /// Sends a request using default metadata (requiresAuth: true, allowsRetry: true).
    func send(_ request: URLRequest) async throws -> Data {
        try await send(request, metadata: .default)
    }
}
