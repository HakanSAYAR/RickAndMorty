//
//  URLRequestBuilder.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - URLRequestBuilderProtocol

public protocol URLRequestBuilderProtocol {
    func build(from endpoint: Endpoint, configuration: NetworkConfiguration) throws -> URLRequest
}

// MARK: - URLRequestBuilder

public final class URLRequestBuilder: URLRequestBuilderProtocol {

    public init() {}

    public func build(from endpoint: Endpoint, configuration: NetworkConfiguration) throws -> URLRequest {
        guard var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        let basePath = components.path.hasSuffix("/")
            ? String(components.path.dropLast())
            : components.path
        let path = endpoint.path.hasPrefix("/") ? endpoint.path : "/\(endpoint.path)"
        components.path = basePath + path

        if let queryParameters = endpoint.queryParameters, !queryParameters.isEmpty {
            let existing = components.queryItems ?? []
            let new = queryParameters
                .sorted { $0.key < $1.key }
                .flatMap { $0.value.toURLQueryItems(name: $0.key) }
            components.queryItems = existing + new
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: configuration.timeoutInterval)
        request.httpMethod = endpoint.method.rawValue

        // Apply default headers first, endpoint headers override if same key.
        configuration.defaultHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.name) }
        endpoint.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.name) }

        request.httpBody = try endpoint.makeBody()

        // Set Content-Type only if body present and not already specified.
        if request.httpBody != nil, request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}
