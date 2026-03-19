//
//  NetworkLogLevel.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

// MARK: - NetworkLogLevel

public enum NetworkLogLevel {
    /// Logs URL, method, status, all headers, and full response body.
    case verbose
    /// Logs URL, method, and status code only.
    case standard
    /// Logs only failed requests and errors.
    case minimal
}
