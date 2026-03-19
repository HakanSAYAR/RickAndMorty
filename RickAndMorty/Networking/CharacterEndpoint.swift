//
//  CharacterEndpoint.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Foundation
import NetworkKit

// MARK: - CharacterEndpoint

enum CharacterEndpoint: Endpoint {
    case characters(page: Int)

    var path: String {
        switch self {
        case .characters: return "/character"
        }
    }

    var method: HTTPMethod { .get }

    var queryParameters: [String: QueryParameterValue]? {
        switch self {
        case .characters(let page):
            return ["page": .int(page)]
        }
    }

    // API is public — no token required.
    var requiresAuth: Bool { false }
}
