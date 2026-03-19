//
//  PermissionStatus.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation

// MARK: - PermissionStatus

enum PermissionStatus: Sendable {
    case authorized
    case denied
    case notDetermined
    case restricted
}

nonisolated extension PermissionStatus: Equatable {}
