//
//  HTTPHeader.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

// MARK: - HTTPHeader

public struct HTTPHeader {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

// MARK: - Common Headers

public extension HTTPHeader {
    static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: value)
    }

    static func accept(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept", value: value)
    }

    static func authorization(bearerToken token: String) -> HTTPHeader {
        HTTPHeader(name: "Authorization", value: "Bearer \(token)")
    }

    // MARK: - Predefined Values

    static let contentTypeJSON = HTTPHeader.contentType("application/json")
    static let acceptJSON      = HTTPHeader.accept("application/json")
}
