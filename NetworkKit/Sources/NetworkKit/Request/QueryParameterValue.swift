//
//  QueryParameterValue.swift
//  NetworkKit
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - QueryParameterValue

public enum QueryParameterValue {
    case string(String)
    case int(Int)
    case bool(Bool)
    case double(Double)
    /// Encodes as repeated keys: ids=1&ids=2&ids=3
    case array([String])
    case intArray([Int])
    case date(Date, String)
}

// MARK: - Convenience

public extension QueryParameterValue {

    /// Date with ISO8601 format by default.
    static func date(_ date: Date, format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> QueryParameterValue {
        .date(date, format)
    }
}

// MARK: - URLQueryItem Conversion

public extension QueryParameterValue {

    func toURLQueryItems(name: String) -> [URLQueryItem] {
        switch self {
        case .string(let value):
            return [URLQueryItem(name: name, value: value)]
        case .int(let value):
            return [URLQueryItem(name: name, value: String(value))]
        case .bool(let value):
            return [URLQueryItem(name: name, value: value ? "true" : "false")]
        case .double(let value):
            return [URLQueryItem(name: name, value: String(value))]
        case .array(let values):
            return values.map { URLQueryItem(name: name, value: $0) }
        case .intArray(let values):
            return values.map { URLQueryItem(name: name, value: String($0)) }
        case .date(let date, let format):
            return [URLQueryItem(name: name, value: DateFormatterCache.formatter(for: format).string(from: date))]
        }
    }
}

// MARK: - DateFormatterCache

private enum DateFormatterCache {
    private static var cache: [String: DateFormatter] = [:]
    private static let lock = NSLock()

    static func formatter(for format: String) -> DateFormatter {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[format] { return cached }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        cache[format] = formatter
        return formatter
    }
}
