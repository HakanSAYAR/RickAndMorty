//
//  PaginationInfo.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - PaginationInfo

struct PaginationInfo {
    nonisolated let totalPages: Int
    nonisolated let hasNextPage: Bool

    nonisolated init(totalPages: Int, hasNextPage: Bool) {
        self.totalPages = totalPages
        self.hasNextPage = hasNextPage
    }
}
