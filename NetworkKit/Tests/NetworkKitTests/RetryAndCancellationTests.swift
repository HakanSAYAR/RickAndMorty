//
//  RetryAndCancellationTests.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import XCTest
@testable import NetworkKit

final class RetryAndCancellationTests: XCTestCase {

    private var mockLogger: MockNetworkLogger!

    override func setUp() {
        super.setUp()
        mockLogger = MockNetworkLogger()
    }

    override func tearDown() {
        mockLogger = nil
        super.tearDown()
    }

    // MARK: - Retry — Idempotency

    func test_retry_doesNotRetry_forPOST() async {
        let session = CountingSession(responses: [
            (Data(), MockURLSession.makeHTTPResponse(statusCode: 500)),
            (Data(), MockURLSession.makeHTTPResponse(statusCode: 200))
        ])
        let policy = RetryPolicy(maxRetryCount: 2, retryDelay: 0, retryableStatusCodes: [500], retryOnConnectionFailure: false)
        let sut = URLSessionNetworkClient(session: session, interceptors: [], logger: mockLogger, retryPolicy: policy)

        var request = URLRequest(url: URL(string: "https://api.test.com/submit")!)
        request.httpMethod = "POST"

        do {
            _ = try await sut.send(request)
            XCTFail("Expected error")
        } catch is NetworkError {
            XCTAssertEqual(session.callCount, 1, "POST must not be retried")
        }
    }

    func test_retry_retriesOnServerError_forGET() async throws {
        let session = CountingSession(responses: [
            (Data(), MockURLSession.makeHTTPResponse(statusCode: 500)),
            (Data(), MockURLSession.makeHTTPResponse(statusCode: 500)),
            (Data(), MockURLSession.makeHTTPResponse(statusCode: 200))
        ])
        let policy = RetryPolicy(maxRetryCount: 2, retryDelay: 0, retryableStatusCodes: [500], retryOnConnectionFailure: false)
        let sut = URLSessionNetworkClient(session: session, interceptors: [], logger: mockLogger, retryPolicy: policy)

        var request = URLRequest(url: URL(string: "https://api.test.com/character")!)
        request.httpMethod = "GET"

        _ = try await sut.send(request)

        XCTAssertEqual(session.callCount, 3)
    }

    func test_retry_doesNotRetry_whenAllowsRetryIsFalse() async {
        let session = CountingSession(responses: [
            (Data(), MockURLSession.makeHTTPResponse(statusCode: 500)),
            (Data(), MockURLSession.makeHTTPResponse(statusCode: 200))
        ])
        let policy = RetryPolicy(maxRetryCount: 2, retryDelay: 0, retryableStatusCodes: [500], retryOnConnectionFailure: false)
        let sut = URLSessionNetworkClient(session: session, interceptors: [], logger: mockLogger, retryPolicy: policy)

        var request = URLRequest(url: URL(string: "https://api.test.com/payment")!)
        request.httpMethod = "GET"

        do {
            _ = try await sut.send(request, metadata: RequestMetadata(allowsRetry: false))
            XCTFail("Expected error")
        } catch is NetworkError {
            XCTAssertEqual(session.callCount, 1, "Endpoint with allowsRetry=false must not be retried")
        }
    }

    func test_retry_exhaustsMaxRetryCount_thenThrows() async {
        let session = CountingSession(responses: [
            (Data(), MockURLSession.makeHTTPResponse(statusCode: 500)),
            (Data(), MockURLSession.makeHTTPResponse(statusCode: 500)),
            (Data(), MockURLSession.makeHTTPResponse(statusCode: 500)),
            (Data(), MockURLSession.makeHTTPResponse(statusCode: 500))
        ])
        let policy = RetryPolicy(maxRetryCount: 2, retryDelay: 0, retryableStatusCodes: [500], retryOnConnectionFailure: false)
        let sut = URLSessionNetworkClient(session: session, interceptors: [], logger: mockLogger, retryPolicy: policy)

        var request = URLRequest(url: URL(string: "https://api.test.com/character")!)
        request.httpMethod = "GET"

        do {
            _ = try await sut.send(request)
            XCTFail("Expected error after max retries")
        } catch is NetworkError {
            // maxRetryCount = 2 means: 1 initial attempt + 2 retries = 3 total calls
            XCTAssertEqual(session.callCount, 3)
        }
    }

    // MARK: - Cancellation

    func test_cancellation_propagates_notWrappedInNetworkError() async {
        let session = HangingSession()
        let sut = URLSessionNetworkClient(session: session, interceptors: [], logger: mockLogger, retryPolicy: .none)
        let request = URLRequest(url: URL(string: "https://api.test.com/character")!)

        let task = Task {
            _ = try await sut.send(request)
        }

        task.cancel()

        do {
            try await task.value
            XCTFail("Expected CancellationError")
        } catch is CancellationError {
            // success — cancellation propagated correctly
        } catch let error as NetworkError {
            XCTFail("CancellationError must not be wrapped in NetworkError, got \(error)")
        } catch {
            // URLError.cancelled from URLSession is also acceptable
        }
    }

    func test_urlErrorCancelled_throwsCancellationError() async {
        let session = CountingSession(responses: [])
        // Override to throw URLError.cancelled
        let failSession = FailingSession(error: URLError(.cancelled))
        let sut = URLSessionNetworkClient(session: failSession, interceptors: [], logger: mockLogger, retryPolicy: .none)
        let request = URLRequest(url: URL(string: "https://api.test.com/character")!)

        do {
            _ = try await sut.send(request)
            XCTFail("Expected CancellationError")
        } catch is CancellationError {
            // success
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }

        _ = session // suppress unused warning
    }
}

// MARK: - Test Sessions

private final class CountingSession: URLSessionProtocol {
    private(set) var callCount = 0
    private var responses: [(Data, URLResponse)]

    init(responses: [(Data, URLResponse)]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        callCount += 1
        defer { if !responses.isEmpty { responses.removeFirst() } }
        return responses.first ?? (Data(), MockURLSession.makeHTTPResponse(statusCode: 200))
    }
}

private final class HangingSession: URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await Task.sleep(nanoseconds: 10_000_000_000)
        return (Data(), MockURLSession.makeHTTPResponse(statusCode: 200))
    }
}

private final class FailingSession: URLSessionProtocol {
    private let error: Error
    init(error: Error) { self.error = error }
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        throw error
    }
}
