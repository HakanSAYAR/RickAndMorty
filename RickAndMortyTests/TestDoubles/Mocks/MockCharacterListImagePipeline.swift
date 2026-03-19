//
//  MockCharacterListImagePipeline.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import UIKit
import Kingfisher
@testable import RickAndMorty

// MARK: - MockCharacterListImagePipeline

final class MockCharacterListImagePipeline: CharacterListImagePipelineProtocol {
    private(set) var capturedTargetSizes: [CGSize] = []

    func options(targetSize: CGSize) -> KingfisherOptionsInfo {
        capturedTargetSizes.append(targetSize)
        return [
            .processor(DownsamplingImageProcessor(size: targetSize)),
            .scaleFactor(1.0)
        ]
    }
}
