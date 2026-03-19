//
//  ListItem.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - ListItem

enum ListItem: Sendable {
    case character(Character)
    case galleryPhoto(GalleryPhoto)
}

nonisolated extension ListItem: Hashable {}
