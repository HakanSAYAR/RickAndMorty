//
//  RetryPolicy.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - RetryPolicy

public struct RetryPolicy {
    public let maxRetryCount: Int
    /// Base delay (seconds) used as the multiplier for exponential backoff.
    public let retryDelay: TimeInterval
    /// Upper bound (seconds) for the computed backoff delay before jitter is applied.
    public let maxDelay: TimeInterval
    public let retryableStatusCodes: Set<Int>
    public let retryOnConnectionFailure: Bool

    public init(
        maxRetryCount: Int,
        retryDelay: TimeInterval,
        maxDelay: TimeInterval = 30,
        retryableStatusCodes: Set<Int>,
        retryOnConnectionFailure: Bool
    ) {
        self.maxRetryCount = maxRetryCount
        self.retryDelay = retryDelay
        self.maxDelay = maxDelay
        self.retryableStatusCodes = retryableStatusCodes
        self.retryOnConnectionFailure = retryOnConnectionFailure
    }

    /// Retries up to 3 times for server errors (5xx) and connection failures.
    public static let `default` = RetryPolicy(
        maxRetryCount: 3,
        retryDelay: 1.0,
        maxDelay: 30,
        retryableStatusCodes: [500, 502, 503, 504],
        retryOnConnectionFailure: true
    )

    /// No retries.
    public static let none = RetryPolicy(
        maxRetryCount: 0,
        retryDelay: 0,
        maxDelay: 0,
        retryableStatusCodes: [],
        retryOnConnectionFailure: false
    )
}
