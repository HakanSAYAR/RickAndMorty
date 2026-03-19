//
//  PhotoDetailEvent.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

// MARK: - PhotoDetailEvent

enum PhotoDetailEvent: Equatable {
    case saveSuccess
    case alreadySaved
    case permissionDenied
    case saveError(String)
}
