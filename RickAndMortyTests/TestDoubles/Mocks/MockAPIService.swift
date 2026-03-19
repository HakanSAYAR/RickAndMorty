//
//  MockAPIService.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation
import NetworkKit
@testable import RickAndMorty

// MARK: - MockError

enum MockError: Error {
    case unexpectedType
    case generic
}

// MARK: - MockAPIService

final class MockAPIService: APIServiceProtocol {

    var resultsQueue: [Result<Any, Error>] = []
    var defaultResult: Result<Any, Error> = .success(CharacterPage.stub())
    var fetchCallCount = 0

    func fetch<T: Decodable>(endpoint: any Endpoint) async throws -> T {
        fetchCallCount += 1
        let result = resultsQueue.isEmpty ? defaultResult : resultsQueue.removeFirst()
        let value = try result.get()
        guard let typed = value as? T else { throw MockError.unexpectedType }
        return typed
    }

    func perform(endpoint: any Endpoint) async throws {}
}
