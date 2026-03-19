//
//  PHImageRequestOptionsFactory.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Photos

// MARK: - PHImageRequestOptionsFactoryProtocol

protocol PHImageRequestOptionsFactoryProtocol {
    func makeVisibleOptions() -> PHImageRequestOptions
    func makeCachingOptions() -> PHImageRequestOptions
}

// MARK: - PHImageRequestOptionsFactory

struct PHImageRequestOptionsFactory: PHImageRequestOptionsFactoryProtocol {

    /// Options for visible cell image requests.
    /// Delivers a degraded preview first then upgrades to full quality (.opportunistic).
    /// Network access is allowed so iCloud assets can be fetched on demand.
    func makeVisibleOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        return options
    }

    /// Options for background cache warming via PHCachingImageManager.
    /// Prioritises speed over quality (.fastFormat) to reduce CPU pressure during scroll.
    /// Network access is disabled to prevent background I/O for iCloud assets.
    func makeCachingOptions() -> PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false
        return options
    }
}
