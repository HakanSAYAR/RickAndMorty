//
//  NetworkError.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - NetworkError

public enum NetworkError: LocalizedError {
    case invalidURL
    /// The response was not a valid HTTPURLResponse.
    case invalidResponse
    /// Non-2xx status code with optional backend error body.
    case statusCode(Int, Data?)
    case decoding(Error)
    /// 401 — optional backend error body preserved for debugging.
    case unauthorized(Data?)
    /// 403 — optional backend error body preserved for debugging.
    case forbidden(Data?)
    /// 404 — optional backend error body preserved for debugging.
    case notFound(Data?)
    case noInternetConnection
    case timeout
    /// 5xx — optional backend error body preserved for debugging.
    case serverError(Int, Data?)
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .statusCode(let code, _):
            return "Unexpected status code: \(code)."
        case .decoding(let error):
            if let decodingError = error as? DecodingError {
                return "Failed to decode response: \(decodingError.detailedDescription)"
            }
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized. Please check your credentials."
        case .forbidden:
            return "Access forbidden."
        case .notFound:
            return "Resource not found."
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "Request timed out. Please try again."
        case .serverError(let code, _):
            return "Server error with status code: \(code)."
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }

}

// MARK: - DecodingError

private extension DecodingError {
    /// Human-readable description that surfaces the key path and failure reason.
    var detailedDescription: String {
        func path(_ ctx: DecodingError.Context) -> String {
            let p = ctx.codingPath.map(\.stringValue).joined(separator: ".")
            return p.isEmpty ? "(root)" : p
        }
        switch self {
        case .keyNotFound(let key, let ctx):
            return "Key '\(key.stringValue)' not found at \(path(ctx)). \(ctx.debugDescription)"
        case .typeMismatch(let type, let ctx):
            return "Type mismatch for \(type) at \(path(ctx)). \(ctx.debugDescription)"
        case .valueNotFound(let type, let ctx):
            return "Value of type \(type) not found at \(path(ctx)). \(ctx.debugDescription)"
        case .dataCorrupted(let ctx):
            return "Data corrupted at \(path(ctx)). \(ctx.debugDescription)"
        @unknown default:
            return localizedDescription
        }
    }
}

// MARK: - NetworkError + helpers

public extension NetworkError {

    var isUnauthorized: Bool {
        if case .unauthorized = self { return true }
        return false
    }

    var httpStatusCode: Int? {
        switch self {
        case .statusCode(let code, _):  return code
        case .unauthorized:             return 401
        case .forbidden:                return 403
        case .notFound:                 return 404
        case .serverError(let code, _): return code
        default:                        return nil
        }
    }

    var isConnectionFailure: Bool {
        switch self {
        case .noInternetConnection, .timeout: return true
        default: return false
        }
    }
}

// MARK: - NetworkError + responseBody

public extension NetworkError {
    /// Decoded backend error body as a UTF-8 string, if available.
    var responseBody: String? {
        switch self {
        case .statusCode(_, let data),
             .unauthorized(let data),
             .forbidden(let data),
             .notFound(let data),
             .serverError(_, let data):
            guard let data else { return nil }
            return String(data: data, encoding: .utf8)
        default:
            return nil
        }
    }
}
