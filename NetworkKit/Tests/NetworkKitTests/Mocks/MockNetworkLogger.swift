//
//  MockNetworkLogger.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation
@testable import NetworkKit

// MARK: - MockNetworkLogger

final class MockNetworkLogger: NetworkLoggerProtocol {

    private(set) var loggedRequests: [URLRequest] = []
    private(set) var loggedResponses: [(HTTPURLResponse, Data, URLRequest, TimeInterval)] = []
    private(set) var loggedErrors: [(Error, URLRequest)] = []
    private(set) var loggedCURLRequests: [URLRequest] = []

    func logRequest(_ request: URLRequest) {
        loggedRequests.append(request)
    }

    func logResponse(
        _ response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        duration: TimeInterval
    ) {
        loggedResponses.append((response, data, request, duration))
    }

    func logError(_ error: Error, for request: URLRequest) {
        loggedErrors.append((error, request))
    }

    func logCURL(_ request: URLRequest) {
        loggedCURLRequests.append(request)
    }
}
