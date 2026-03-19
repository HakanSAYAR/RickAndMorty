//
//  JSONBodyEncoder.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - JSONBodyEncoder

public final class JSONBodyEncoder {

    private let keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy
    private let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy

    public init(
        keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys,
        dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601
    ) {
        self.keyEncodingStrategy = keyEncodingStrategy
        self.dateEncodingStrategy = dateEncodingStrategy
    }

    public func encode<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = keyEncodingStrategy
        encoder.dateEncodingStrategy = dateEncodingStrategy
        return try encoder.encode(value)
    }
}
