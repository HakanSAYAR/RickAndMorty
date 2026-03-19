//
//  Array+Ext.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
