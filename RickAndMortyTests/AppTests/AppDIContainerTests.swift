//
//  AppDIContainerTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Foundation
import Testing
@testable import RickAndMorty

// MARK: - AppDIContainerTests

@MainActor
struct AppDIContainerTests {

    @Test func init_withMockConfiguration_createsContainer() {
        _ = AppDIContainer(configuration: MockConfiguration())
    }

    @Test func init_withCustomBaseURL_createsContainer() {
        let config = MockConfiguration(baseURL: URL(string: "https://mock.api.com")!)
        _ = AppDIContainer(configuration: config)
    }
}
