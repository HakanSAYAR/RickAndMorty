//
//  ErrorMapper.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - ErrorMapper

struct ErrorMapper {
    static func message(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return L10n.Errors.noInternetConnection
            case .timedOut:
                return L10n.Errors.requestTimedOut
            default:
                return L10n.Errors.networkError
            }
        }
        return L10n.Errors.generic
    }
}

