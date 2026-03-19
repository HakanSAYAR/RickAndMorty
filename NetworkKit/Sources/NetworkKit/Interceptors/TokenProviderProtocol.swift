//
//  TokenProviderProtocol.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - TokenProviderProtocol
// async throws allows implementations to perform a network call to obtain or
// refresh an expired token before returning, without blocking the caller.
// Return nil when no token should be attached (e.g. anonymous session).

public protocol TokenProviderProtocol {
    func token() async throws -> String?
}
