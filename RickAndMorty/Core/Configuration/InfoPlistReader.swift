//
//  InfoPlistReader.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - InfoPlistKey

enum InfoPlistKey: String {
    case baseURL = "BASE_URL"
}

// MARK: - InfoPlistReader

struct InfoPlistReader {

    /// Returns the String value for the given Info.plist key.
    /// Calls fatalError if the key is missing or not a String — configuration errors must surface at startup.
    static func string(for key: InfoPlistKey) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String else {
            fatalError("Info.plist is missing required key '\(key.rawValue)' or its value is not a String.")
        }
        return value
    }
}
