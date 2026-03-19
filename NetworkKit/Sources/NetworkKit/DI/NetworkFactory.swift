//
//  NetworkFactory.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - NetworkFactory
// Composition root for the network stack.

public enum NetworkFactory {

    public static func make(
        configuration: NetworkConfiguration,
        tokenProvider: TokenProviderProtocol? = nil,
        logSubsystem: String = Bundle.main.bundleIdentifier ?? "com.networkkit",
        logLevel: NetworkLogLevel = .standard,
        retryPolicy: RetryPolicy = .default
    ) -> NetworkStack {
        let (interceptors, authInterceptor) = makeInterceptors(tokenProvider: tokenProvider)

        let client = URLSessionNetworkClient(
            session: URLSession.shared,
            interceptors: interceptors,
            logger: NetworkLogger(subsystem: logSubsystem, logLevel: logLevel),
            retryPolicy: retryPolicy
        )

        let apiService = APIService(
            client: client,
            builder: URLRequestBuilder(),
            decoder: JSONResponseDecoder(),
            configuration: configuration
        )

        return NetworkStack(apiService: apiService, authInterceptor: authInterceptor)
    }

    // MARK: - Private

    private static func makeInterceptors(
        tokenProvider: TokenProviderProtocol?
    ) -> (interceptors: [NetworkInterceptorProtocol], authInterceptor: AuthInterceptor?) {
        guard let tokenProvider else { return ([], nil) }
        let interceptor = AuthInterceptor(tokenProvider: tokenProvider)
        return ([interceptor], interceptor)
    }
}
