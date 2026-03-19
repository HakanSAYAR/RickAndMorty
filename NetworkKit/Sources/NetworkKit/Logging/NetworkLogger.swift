//
//  NetworkLogger.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation
import os.log

// MARK: - NetworkLogger

public final class NetworkLogger: NetworkLoggerProtocol {

    // MARK: - Defaults

    public static let defaultSensitiveHeaders: Set<String> = [
        "authorization", "x-api-key", "cookie", "set-cookie"
    ]

    public static let defaultSensitiveBodyKeys: Set<String> = [
        "password", "token", "secret", "access_token", "refresh_token",
        "card_number", "cvv", "ssn"
    ]

    // MARK: - Properties

    private let logLevel: NetworkLogLevel
    private let osLogger: Logger
    /// Lowercase header names whose values will be replaced with "***".
    private let sensitiveHeaders: Set<String>
    /// Lowercase JSON body keys whose values will be replaced with "***".
    private let sensitiveBodyKeys: Set<String>
    /// Response bodies longer than this are truncated in logs. 0 = no limit.
    private let maxBodyLogLength: Int

    // MARK: - Init
    // subsystem: injected to support apps, extensions, and test targets.

    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.networkkit",
        logLevel: NetworkLogLevel = .standard,
        sensitiveHeaders: Set<String> = defaultSensitiveHeaders,
        sensitiveBodyKeys: Set<String> = defaultSensitiveBodyKeys,
        maxBodyLogLength: Int = 2048
    ) {
        self.logLevel = logLevel
        self.osLogger = Logger(subsystem: subsystem, category: "Network")
        self.sensitiveHeaders = Set(sensitiveHeaders.map { $0.lowercased() })
        self.sensitiveBodyKeys = Set(sensitiveBodyKeys.map { $0.lowercased() })
        self.maxBodyLogLength = maxBodyLogLength
    }

    // MARK: - NetworkLoggerProtocol

    public func logRequest(_ request: URLRequest) {
        guard logLevel != .minimal else { return }

        var log = "\n┌─────────────────── 📡 REQUEST ───────────────────"
        log += "\n│ \(request.httpMethod ?? "UNKNOWN") \(request.url?.absoluteString ?? "nil")"

        if logLevel == .verbose {
            if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
                log += "\n│ Headers:"
                headers.sorted { $0.key < $1.key }.forEach {
                    log += "\n│   \($0.key): \(maskedHeaderValue($0.value, for: $0.key))"
                }
            }
            if let body = request.httpBody, let bodyString = prettyPrinted(data: body, maskingKeys: sensitiveBodyKeys) {
                log += "\n│ Body: \(bodyString)"
            }
        }

        log += "\n└────────────────────────────────────────────────\n"
        osLogger.debug("\(log)")
    }

    public func logResponse(
        _ response: HTTPURLResponse,
        data: Data,
        for request: URLRequest,
        duration: TimeInterval
    ) {
        let isSuccess = (200...299).contains(response.statusCode)

        if logLevel == .minimal, isSuccess { return }

        let emoji = isSuccess ? "✅" : "❌"
        let durationString = String(format: "%.3fs", duration)

        var log = "\n┌─────────────────── \(emoji) RESPONSE ────────────────────"
        log += "\n│ \(response.statusCode) | \(durationString) | \(request.url?.absoluteString ?? "nil")"

        if logLevel == .verbose, let bodyString = prettyPrinted(data: data, maskingKeys: sensitiveBodyKeys) {
            log += "\n│ Body: \(bodyString)"
        }

        log += "\n└────────────────────────────────────────────────\n"

        if isSuccess {
            osLogger.debug("\(log)")
        } else {
            osLogger.error("\(log)")
        }
    }

    public func logError(_ error: Error, for request: URLRequest) {
        var log = "\n┌─────────────────── 🔴 ERROR ───────────────────"
        log += "\n│ URL: \(request.url?.absoluteString ?? "nil")"
        log += "\n│ Error: \(error.localizedDescription)"
        log += "\n└────────────────────────────────────────────────\n"
        osLogger.error("\(log)")
    }

    public func logCURL(_ request: URLRequest) {
        guard logLevel == .verbose else { return }

        var components = ["curl -v"]
        components.append("-X \(request.httpMethod ?? "GET")")

        if let headers = request.allHTTPHeaderFields {
            headers.sorted { $0.key < $1.key }.forEach { key, value in
                let safeValue = maskedHeaderValue(value, for: key)
                components.append("-H '\(shellEscaped("\(key): \(safeValue)"))'")
            }
        }

        if let body = request.httpBody,
           let bodyString = prettyPrinted(data: body, maskingKeys: sensitiveBodyKeys) {
            // Collapse to single line for a valid cURL -d argument
            let oneLine = bodyString
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .joined()
            components.append("-d '\(shellEscaped(oneLine))'")
        }

        if let url = request.url?.absoluteString {
            components.append("'\(shellEscaped(url))'")
        }

        let curl = components.joined(separator: " \\\n  ")
        let log = "\n┌─────────────────── 🌀 cURL ───────────────────\n\(curl)\n└────────────────────────────────────────────────\n"
        osLogger.debug("\(log)")
    }

    // MARK: - Private — Shell Escaping

    /// Escapes single quotes for POSIX single-quoted shell strings.
    /// Replaces each ' with '\'' so the resulting string is safe
    /// to embed inside single quotes in a cURL command.
    // Internal access allows @testable unit tests to verify escaping directly
    // without capturing os.log output.
    func shellEscaped(_ string: String) -> String {
        string.replacingOccurrences(of: "'", with: "'\\''")
    }

    // MARK: - Private — Masking

    func maskedHeaderValue(_ value: String, for key: String) -> String {
        sensitiveHeaders.contains(key.lowercased()) ? "***" : value
    }

    /// Parses, masks sensitive keys, and pretty-prints JSON or fallback text.
    func prettyPrinted(data: Data, maskingKeys: Set<String>) -> String? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            if let text = String(data: data, encoding: .utf8) { return truncated(text) }
            return "<\(data.count) bytes>"
        }

        // Recurse into nested objects.
        let masked = maskJSON(jsonObject, keys: maskingKeys)

        guard
            let maskedData = try? JSONSerialization.data(withJSONObject: masked, options: .prettyPrinted),
            let prettyString = String(data: maskedData, encoding: .utf8)
        else {
            return String(data: data, encoding: .utf8)
        }

        return truncated(prettyString)
    }

    /// Masks sensitive keys in JSON recursively.
    func maskJSON(_ value: Any, keys: Set<String>) -> Any {
        if let dict = value as? [String: Any] {
            var result = [String: Any]()
            for (key, val) in dict {
                result[key] = keys.contains(key.lowercased()) ? "***" : maskJSON(val, keys: keys)
            }
            return result
        }
        if let array = value as? [Any] {
            return array.map { maskJSON($0, keys: keys) }
        }
        return value
    }

    func truncated(_ string: String) -> String {
        guard maxBodyLogLength > 0, string.count > maxBodyLogLength else { return string }
        return string.prefix(maxBodyLogLength) + "… [\(string.count - maxBodyLogLength) more chars]"
    }
}
