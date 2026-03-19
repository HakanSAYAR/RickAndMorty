//
//  NetworkConfiguration.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - NetworkConfiguration

public struct NetworkConfiguration {
    /// Validated at initialisation — compile-time safety over runtime URL parsing.
    public let baseURL: URL
    public let defaultHeaders: [HTTPHeader]
    public let timeoutInterval: TimeInterval

    public init(
        baseURL: URL,
        defaultHeaders: [HTTPHeader] = [.acceptJSON],
        timeoutInterval: TimeInterval = 30
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeoutInterval = timeoutInterval
    }
}
