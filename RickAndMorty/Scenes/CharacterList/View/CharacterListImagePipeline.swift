//
//  CharacterListImagePipeline.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Kingfisher
import UIKit

// MARK: - CharacterListImagePipelineProtocol

/// Single source of truth for Kingfisher image-request options used by CharacterCell.
///
/// Both cell configure and ImagePrefetcher must call `options(targetSize:)` with
/// matching sizes to produce identical cache keys — guaranteeing prefetch cache hits.
protocol CharacterListImagePipelineProtocol {
    func options(targetSize: CGSize) -> KingfisherOptionsInfo
}

// MARK: - CharacterListImagePipeline

struct CharacterListImagePipeline: CharacterListImagePipelineProtocol {

    nonisolated init() {}

    /// Returns Kingfisher options. Processor + scale must match CharacterCell.configure for cache hits.
    func options(targetSize: CGSize) -> KingfisherOptionsInfo {
        [
            .processor(DownsamplingImageProcessor(size: targetSize)),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.2)),
            .retryStrategy(DelayRetryStrategy(maxRetryCount: 3, retryInterval: .seconds(10)))
        ]
    }
}
