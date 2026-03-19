//
//  AppConfiguration.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation
import NetworkKit

// MARK: - AppConfiguration

struct AppConfiguration: ConfigurationProvider {

    var baseURL: URL {
        let raw = InfoPlistReader.string(for: .baseURL)
        guard let url = URL(string: raw) else {
            fatalError("Info.plist key 'BASE_URL' is not a valid URL: '\(raw)'")
        }
        return url
    }

    var logLevel: NetworkLogLevel {
        #if DEBUG
        return .verbose
        #else
        return .standard
        #endif
    }

    static let current = AppConfiguration()
}
