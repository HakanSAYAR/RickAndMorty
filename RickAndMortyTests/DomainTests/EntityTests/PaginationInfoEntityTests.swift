//
//  PaginationInfoEntityTests.swift
//  RickAndMortyTests
//
//  Created by Hakan SAYAR on 19.03.2026
//

import Testing
@testable import RickAndMorty

// MARK: - PaginationInfoEntityTests

struct PaginationInfoEntityTests {

    @Test func hasNextPage_true_whenMorePages() {
        let info = PaginationInfo(totalPages: 5, hasNextPage: true)
        #expect(info.hasNextPage == true)
        #expect(info.totalPages == 5)
    }

    @Test func hasNextPage_false_whenOnLastPage() {
        let info = PaginationInfo(totalPages: 1, hasNextPage: false)
        #expect(info.hasNextPage == false)
        #expect(info.totalPages == 1)
    }

    @Test func singlePage_noNextPage() {
        let info = PaginationInfo(totalPages: 1, hasNextPage: false)
        #expect(info.totalPages == 1)
        #expect(info.hasNextPage == false)
    }
}
