//
//  CharacterListSnapshotFactory.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import UIKit

// MARK: - CharacterListSnapshotFactory
//
// Pure stateless factory — no stored state, no side effects.

nonisolated enum CharacterListSnapshotFactory {

    static func makeSnapshot(
        from sections: [CharacterListSectionModel]
    ) -> NSDiffableDataSourceSnapshot<CharacterListSection, CharacterListSectionItem> {
        var snapshot = NSDiffableDataSourceSnapshot<CharacterListSection, CharacterListSectionItem>()
        for sectionModel in sections {
            snapshot.appendSections([sectionModel.section])
            snapshot.appendItems(sectionModel.items, toSection: sectionModel.section)
        }
        return snapshot
    }
}
