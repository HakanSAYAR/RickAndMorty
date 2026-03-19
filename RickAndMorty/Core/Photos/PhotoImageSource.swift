//
//  PhotoImageSource.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import Foundation

// MARK: - PhotoImageSource

enum PhotoImageSource: Sendable {
    case remote(URL?)
    case local(String) // PHAsset localIdentifier
}

nonisolated extension PhotoImageSource: Equatable {}
