//
//  PhotoDetailViewData.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

// MARK: - PhotoDetailViewData

struct PhotoDetailViewData: Sendable {
    nonisolated let imageSource: PhotoImageSource
    nonisolated let characterName: String

    nonisolated init(imageSource: PhotoImageSource, characterName: String) {
        self.imageSource = imageSource
        self.characterName = characterName
    }
}

nonisolated extension PhotoDetailViewData: Equatable {}
