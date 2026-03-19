//
//  NetworkInterceptorProtocol.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - NetworkInterceptorProtocol
// Interceptors are responsible for mutating outgoing URLRequests (e.g. injecting auth tokens).

public protocol NetworkInterceptorProtocol {
    func adapt(_ request: URLRequest) async throws -> URLRequest
}
