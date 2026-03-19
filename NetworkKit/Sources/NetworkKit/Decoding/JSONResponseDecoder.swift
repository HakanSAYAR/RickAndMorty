//
//  JSONResponseDecoder.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - JSONResponseDecoder
// Creates a fresh JSONDecoder per call — avoids shared mutable state in concurrent contexts.

public final class JSONResponseDecoder: ResponseDecoderProtocol {

    private let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy
    private let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy

    public init(
        keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .convertFromSnakeCase,
        dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601
    ) {
        self.keyDecodingStrategy = keyDecodingStrategy
        self.dateDecodingStrategy = dateDecodingStrategy
    }

    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = keyDecodingStrategy
        decoder.dateDecodingStrategy = dateDecodingStrategy
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }
}
