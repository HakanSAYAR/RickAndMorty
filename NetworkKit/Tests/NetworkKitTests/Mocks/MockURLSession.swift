//
//  MockURLSession.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation
@testable import NetworkKit

// MARK: - MockURLSession

final class MockURLSession: URLSessionProtocol {

    var result: Result<(Data, URLResponse), Error> = .success((Data(), makeHTTPResponse(statusCode: 200)))
    private(set) var receivedRequests: [URLRequest] = []
    var callCount: Int { receivedRequests.count }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        receivedRequests.append(request)
        return try result.get()
    }

    func stub(data: Data, statusCode: Int = 200) {
        result = .success((data, MockURLSession.makeHTTPResponse(statusCode: statusCode)))
    }

    func stub<T: Encodable>(response: T, statusCode: Int = 200, encoder: JSONEncoder = JSONEncoder()) {
        let data = (try? encoder.encode(response)) ?? Data()
        stub(data: data, statusCode: statusCode)
    }

    func stubFailure(_ error: Error) {
        result = .failure(error)
    }

    static func makeHTTPResponse(statusCode: Int, url: URL = URL(string: "https://test.com")!) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
