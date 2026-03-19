//
//  NetworkLoggerProtocol.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - NetworkLoggerProtocol

public protocol NetworkLoggerProtocol {
    func logRequest(_ request: URLRequest)
    func logResponse(_ response: HTTPURLResponse, data: Data, for request: URLRequest, duration: TimeInterval)
    func logError(_ error: Error, for request: URLRequest)
    /// Logs a ready-to-paste cURL command for the request. Default is a no-op.
    func logCURL(_ request: URLRequest)
}

public extension NetworkLoggerProtocol {
    func logCURL(_ request: URLRequest) {}
}
