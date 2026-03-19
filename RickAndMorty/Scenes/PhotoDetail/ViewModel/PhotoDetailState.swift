//
//  PhotoDetailState.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

// MARK: - PhotoDetailState

enum PhotoDetailState {
    case idle
    case loaded(PhotoDetailViewData)
}

nonisolated extension PhotoDetailState: Equatable {}
