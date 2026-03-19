//
//  MockPHImageRequestOptionsFactory.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Photos
@testable import RickAndMorty

// MARK: - MockPHImageRequestOptionsFactory

final class MockPHImageRequestOptionsFactory: PHImageRequestOptionsFactoryProtocol {

    private(set) var makeVisibleOptionsCalled = false
    private(set) var makeCachingOptionsCalled = false

    func makeVisibleOptions() -> PHImageRequestOptions {
        makeVisibleOptionsCalled = true
        return PHImageRequestOptions()
    }

    func makeCachingOptions() -> PHImageRequestOptions {
        makeCachingOptionsCalled = true
        return PHImageRequestOptions()
    }
}
