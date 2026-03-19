//
//  MockResponseDecoder.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation
@testable import NetworkKit

// MARK: - MockResponseDecoder

final class MockResponseDecoder: ResponseDecoderProtocol {

    var result: Result<Any, Error> = .success(())
    private(set) var decodeCallCount = 0

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        decodeCallCount += 1
        switch result {
        case .success(let value):
            guard let typed = value as? T else {
                throw NetworkError.decoding(
                    NSError(domain: "MockDecoder", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Cannot cast \(Swift.type(of: value)) to \(T.self)"])
                )
            }
            return typed
        case .failure(let error):
            throw error
        }
    }
}
