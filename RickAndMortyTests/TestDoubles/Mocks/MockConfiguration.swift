//
//  MockConfiguration.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation
import NetworkKit
@testable import RickAndMorty

// MARK: - MockConfiguration

struct MockConfiguration: ConfigurationProvider {
    var baseURL: URL = URL(string: "https://mock.rickandmortyapi.com/api")!
    var logLevel: NetworkLogLevel = .minimal
}
