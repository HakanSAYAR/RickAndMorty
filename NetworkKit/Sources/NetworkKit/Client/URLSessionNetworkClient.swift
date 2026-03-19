//
//  URLSessionNetworkClient.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - URLSessionNetworkClient

public final class URLSessionNetworkClient: NetworkClientProtocol {

    // MARK: - Properties

    private let session: URLSessionProtocol
    private let interceptors: [NetworkInterceptorProtocol]
    private let logger: NetworkLoggerProtocol?
    private let retryPolicy: RetryPolicy

    // MARK: - Init

    public init(
        session: URLSessionProtocol = URLSession.shared,
        interceptors: [NetworkInterceptorProtocol] = [],
        logger: NetworkLoggerProtocol? = NetworkLogger(),
        retryPolicy: RetryPolicy = .default
    ) {
        self.session = session
        self.interceptors = interceptors
        self.logger = logger
        self.retryPolicy = retryPolicy
    }

    // MARK: - NetworkClientProtocol

    public func send(_ request: URLRequest, metadata: RequestMetadata = .default) async throws -> Data {
        var adaptedRequest = request

        for interceptor in interceptors {
            if !metadata.requiresAuth, interceptor is AuthenticationInterceptor { continue }
            adaptedRequest = try await interceptor.adapt(adaptedRequest)
        }

        return try await executeWithRetry(request: adaptedRequest, metadata: metadata)
    }

    // MARK: - Private — Retry Loop

    private func executeWithRetry(request: URLRequest, metadata: RequestMetadata) async throws -> Data {
        // Token refresh may update currentRequest on 401.
        var currentRequest = request
        var attempt = 0
        // Prevent retry loop if refreshed token also fails.
        var tokenRefreshAttempted = false

        while true {
            do {
                return try await performRequest(currentRequest)

            } catch NetworkError.unauthorized(let body) where metadata.requiresAuth && !tokenRefreshAttempted {
                // Attempt a silent token refresh. On any failure (no coordinator,
                // network error during refresh, etc.) surface .unauthorized so
                // the caller can redirect to the login screen.
                do {
                    guard let refreshedRequest = try await attemptTokenRefresh(for: currentRequest) else {
                        throw NetworkError.unauthorized(body)
                    }
                    tokenRefreshAttempted = true
                    currentRequest = refreshedRequest
                } catch {
                    throw NetworkError.unauthorized(body)
                }

            } catch let error as NetworkError {
                guard shouldRetry(error: error, request: currentRequest, metadata: metadata, currentAttempt: attempt) else {
                    throw error
                }
                // Exponential backoff with jitter.
                let exponential = retryPolicy.retryDelay * pow(2.0, Double(attempt))
                let capped = min(retryPolicy.maxDelay, exponential)
                let jitter = Double.random(in: 0...capped)
                attempt += 1
                try await Task.sleep(nanoseconds: UInt64(jitter * 1_000_000_000))

            } catch is CancellationError {
                throw CancellationError()

            } catch {
                throw NetworkError.unknown(error)
            }
        }
    }

    // MARK: - Private — Perform

    private func performRequest(_ request: URLRequest) async throws -> Data {
        let startTime = Date()
        logger?.logRequest(request)
        logger?.logCURL(request)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            if urlError.code == .cancelled { throw CancellationError() }
            let mapped = map(urlError)
            logger?.logError(mapped, for: request)
            throw mapped
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            let error = NetworkError.invalidResponse
            logger?.logError(error, for: request)
            throw error
        }

        let duration = Date().timeIntervalSince(startTime)
        logger?.logResponse(httpResponse, data: data, for: request, duration: duration)

        try validate(statusCode: httpResponse.statusCode, data: data)

        return data
    }

    // MARK: - Private — Helpers

    /// Walks the interceptor list and delegates the 401 to the first
    /// AuthenticationInterceptor that returns a non-nil refreshed request.
    private func attemptTokenRefresh(for request: URLRequest) async throws -> URLRequest? {
        for interceptor in interceptors {
            if let authInterceptor = interceptor as? AuthenticationInterceptor,
               let refreshed = try await authInterceptor.handleUnauthorized(request) {
                return refreshed
            }
        }
        return nil
    }

    private func validate(statusCode: Int, data: Data) throws {
        let body: Data? = data.isEmpty ? nil : data
        switch statusCode {
        case 200...299: return
        case 401:       throw NetworkError.unauthorized(body)
        case 403:       throw NetworkError.forbidden(body)
        case 404:       throw NetworkError.notFound(body)
        case 500...599: throw NetworkError.serverError(statusCode, body)
        default:        throw NetworkError.statusCode(statusCode, body)
        }
    }

    private func map(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noInternetConnection
        case .timedOut:
            return .timeout
        default:
            return .unknown(error)
        }
    }

    private func shouldRetry(
        error: NetworkError,
        request: URLRequest,
        metadata: RequestMetadata,
        currentAttempt: Int
    ) -> Bool {
        guard currentAttempt < retryPolicy.maxRetryCount else { return false }
        guard metadata.allowsRetry else { return false }

        let idempotentMethods: Set<String> = ["GET", "HEAD", "PUT", "DELETE", "OPTIONS"]
        guard let method = request.httpMethod, idempotentMethods.contains(method) else { return false }

        switch error {
        case .serverError(let code, _):
            return retryPolicy.retryableStatusCodes.contains(code)
        case .noInternetConnection, .timeout:
            return retryPolicy.retryOnConnectionFailure
        default:
            return false
        }
    }
}
