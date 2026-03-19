//
//  MockNetworkClient.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation
@testable import NetworkKit

// MARK: - MockNetworkClient

final class MockNetworkClient: NetworkClientProtocol {

    var result: Result<Data, Error> = .success(Data())
    private(set) var sentRequests: [URLRequest] = []
    private(set) var sentMetadata: [RequestMetadata] = []
    var callCount: Int { sentRequests.count }

    func send(_ request: URLRequest, metadata: RequestMetadata = .default) async throws -> Data {
        sentRequests.append(request)
        sentMetadata.append(metadata)
        return try result.get()
    }

    func stub<T: Encodable>(response: T, encoder: JSONEncoder = JSONEncoder()) {
        let data = try? encoder.encode(response)
        result = .success(data ?? Data())
    }
}
