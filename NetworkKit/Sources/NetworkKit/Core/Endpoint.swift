//
//  Endpoint.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - Endpoint

public protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [HTTPHeader] { get }
    var queryParameters: [String: QueryParameterValue]? { get }
    /// Throws on encoding errors to avoid silent failures.
    func makeBody() throws -> Data?
    /// Override to customize encoding strategies.
    var bodyEncoder: JSONBodyEncoder { get }
    /// Set to false for public endpoints that do not require a Bearer token.
    /// AuthInterceptor will skip token injection for these requests.
    var requiresAuth: Bool { get }
    /// Set to false for endpoints that must never be retried (e.g. payment, OTP submission).
    var allowsRetry: Bool { get }
}

public extension Endpoint {
    var headers: [HTTPHeader] { [] }
    var queryParameters: [String: QueryParameterValue]? { nil }
    func makeBody() throws -> Data? { nil }
    var bodyEncoder: JSONBodyEncoder { JSONBodyEncoder() }
    var requiresAuth: Bool { true }
    var allowsRetry: Bool { true }

    /// Convenience helper — encodes value using this endpoint's bodyEncoder.
    func encode<T: Encodable>(_ value: T) throws -> Data {
        try bodyEncoder.encode(value)
    }
}
