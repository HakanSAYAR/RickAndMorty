//
//  MockEndpoint.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation
@testable import NetworkKit

// MARK: - MockEndpoint

struct MockEndpoint: Endpoint {
    var path: String
    var method: HTTPMethod
    var headers: [HTTPHeader]
    var queryParameters: [String: QueryParameterValue]?
    var bodyEncoder: JSONBodyEncoder
    var requiresAuth: Bool
    var allowsRetry: Bool

    private let stubbedBody: Data?
    var shouldThrowOnMakeBody = false

    func makeBody() throws -> Data? {
        if shouldThrowOnMakeBody { throw NetworkError.invalidURL }
        return stubbedBody
    }

    init(
        path: String = "/test",
        method: HTTPMethod = .get,
        headers: [HTTPHeader] = [],
        queryParameters: [String: QueryParameterValue]? = nil,
        body: Data? = nil,
        bodyEncoder: JSONBodyEncoder = JSONBodyEncoder(),
        requiresAuth: Bool = true,
        allowsRetry: Bool = true
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.stubbedBody = body
        self.bodyEncoder = bodyEncoder
        self.requiresAuth = requiresAuth
        self.allowsRetry = allowsRetry
    }
}
