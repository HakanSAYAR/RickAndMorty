//
//  APIService.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - APIServiceProtocol

public protocol APIServiceProtocol {
    /// Fetches a resource and decodes the response body into T.
    func fetch<T: Decodable>(endpoint: Endpoint) async throws -> T
    /// Performs a request where no response body is expected (e.g. DELETE).
    func perform(endpoint: Endpoint) async throws
}

// MARK: - APIService

public final class APIService: APIServiceProtocol {

    // MARK: - Properties

    private let client: NetworkClientProtocol
    private let builder: URLRequestBuilderProtocol
    private let decoder: ResponseDecoderProtocol
    private let configuration: NetworkConfiguration

    // MARK: - Init

    public init(
        client: NetworkClientProtocol,
        builder: URLRequestBuilderProtocol,
        decoder: ResponseDecoderProtocol,
        configuration: NetworkConfiguration
    ) {
        self.client = client
        self.builder = builder
        self.decoder = decoder
        self.configuration = configuration
    }

    // MARK: - APIServiceProtocol

    public func fetch<T: Decodable>(endpoint: Endpoint) async throws -> T {
        let request = try builder.build(from: endpoint, configuration: configuration)
        let metadata = RequestMetadata(requiresAuth: endpoint.requiresAuth, allowsRetry: endpoint.allowsRetry)
        let data = try await client.send(request, metadata: metadata)
        return try decoder.decode(T.self, from: data)
    }

    public func perform(endpoint: Endpoint) async throws {
        let request = try builder.build(from: endpoint, configuration: configuration)
        let metadata = RequestMetadata(requiresAuth: endpoint.requiresAuth, allowsRetry: endpoint.allowsRetry)
        _ = try await client.send(request, metadata: metadata)
    }
}
