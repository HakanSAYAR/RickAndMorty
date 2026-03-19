//
//  SortOption.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - SortOption

enum SortOption: Sendable {
    case newestFirst
    case oldestFirst
}

nonisolated extension SortOption: Equatable {}
