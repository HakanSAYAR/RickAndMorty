//
//  NetworkErrorTests.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import XCTest
@testable import NetworkKit

final class NetworkErrorTests: XCTestCase {

    // MARK: - isUnauthorized

    func test_isUnauthorized_trueForUnauthorizedCase() {
        XCTAssertTrue(NetworkError.unauthorized(nil).isUnauthorized)
    }

    func test_isUnauthorized_falseForOtherCases() {
        let others: [NetworkError] = [
            .forbidden(nil),
            .notFound(nil),
            .statusCode(400, nil),
            .serverError(500, nil),
            .noInternetConnection,
            .timeout,
            .invalidURL
        ]
        for error in others {
            XCTAssertFalse(error.isUnauthorized, "\(error) should not be unauthorized")
        }
    }

    // MARK: - httpStatusCode

    func test_httpStatusCode_returnsCode_forStatusCodeCase() {
        XCTAssertEqual(NetworkError.statusCode(422, nil).httpStatusCode, 422)
    }

    func test_httpStatusCode_returns401_forUnauthorized() {
        XCTAssertEqual(NetworkError.unauthorized(nil).httpStatusCode, 401)
    }

    func test_httpStatusCode_returns403_forForbidden() {
        XCTAssertEqual(NetworkError.forbidden(nil).httpStatusCode, 403)
    }

    func test_httpStatusCode_returns404_forNotFound() {
        XCTAssertEqual(NetworkError.notFound(nil).httpStatusCode, 404)
    }

    func test_httpStatusCode_returnsCode_forServerError() {
        XCTAssertEqual(NetworkError.serverError(503, nil).httpStatusCode, 503)
    }

    func test_httpStatusCode_nilForNonHTTPErrors() {
        let nonHTTP: [NetworkError] = [
            .invalidURL,
            .invalidResponse,
            .noInternetConnection,
            .timeout
        ]
        for error in nonHTTP {
            XCTAssertNil(error.httpStatusCode, "\(error) should have no HTTP status code")
        }
    }

    // MARK: - isConnectionFailure

    func test_isConnectionFailure_trueForNoInternetAndTimeout() {
        XCTAssertTrue(NetworkError.noInternetConnection.isConnectionFailure)
        XCTAssertTrue(NetworkError.timeout.isConnectionFailure)
    }

    func test_isConnectionFailure_falseForOtherCases() {
        let others: [NetworkError] = [
            .unauthorized(nil),
            .forbidden(nil),
            .notFound(nil),
            .statusCode(400, nil),
            .serverError(500, nil),
            .invalidURL,
            .invalidResponse
        ]
        for error in others {
            XCTAssertFalse(error.isConnectionFailure, "\(error) should not be a connection failure")
        }
    }
}
