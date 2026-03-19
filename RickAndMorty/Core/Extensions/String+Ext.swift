//
//  String+Ext.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

extension String {
    // nonisolated: NSLocalizedString is thread-safe.
    nonisolated var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
