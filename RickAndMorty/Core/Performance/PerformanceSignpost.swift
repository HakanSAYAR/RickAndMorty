//
//  PerformanceSignpost.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import Foundation
import os.signpost

// MARK: - PerformanceSignpost

/// Centralized os_signpost wrapper for Instruments profiling.
enum PerformanceSignpost {

    // MARK: - Log

    // nonisolated: OSLog is Sendable and thread-safe; called from both main and background.
    nonisolated static let log = OSLog(subsystem: "com.rickandmorty", category: .pointsOfInterest)

    // MARK: - Name

    // nonisolated: StaticString constants, no state.
    nonisolated enum Name {
        static let cellConfigure      = StaticString("cell_configure")
        static let imageRequest       = StaticString("image_request")
        static let prefetchStart      = StaticString("prefetch_start")
        static let prefetchCancel     = StaticString("prefetch_cancel")
        static let snapshotApply      = StaticString("snapshot_apply")
        static let assetCacheLookup   = StaticString("asset_cache_lookup")
        static let assetCachePopulate = StaticString("asset_cache_populate")
    }

    // MARK: - API
    // All methods are nonisolated: os_signpost is thread-safe and designed for
    // multi-threaded profiling. These are called from both @MainActor and background.

    nonisolated static func begin(_ name: StaticString, id: OSSignpostID = .exclusive, _ message: StaticString = "") {
        os_signpost(.begin, log: log, name: name, signpostID: id, message)
    }

    nonisolated static func end(_ name: StaticString, id: OSSignpostID = .exclusive) {
        os_signpost(.end, log: log, name: name, signpostID: id)
    }

    nonisolated static func event(_ name: StaticString, _ message: StaticString = "") {
        os_signpost(.event, log: log, name: name, message)
    }

    // MARK: - Convenience

    /// Measures a synchronous block and emits begin/end signposts.
    @discardableResult
    nonisolated static func measure<T>(_ name: StaticString, block: () -> T) -> T {
        let id = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: id)
        defer { os_signpost(.end, log: log, name: name, signpostID: id) }
        return block()
    }
}
