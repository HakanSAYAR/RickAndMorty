//
//  ConfigurationProvider.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation
import NetworkKit

// MARK: - ConfigurationProvider

protocol ConfigurationProvider {
    var baseURL: URL { get }
    var logLevel: NetworkLogLevel { get }
}
