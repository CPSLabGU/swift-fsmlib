//
//  FileWritingSupport.swift
//  FSMEcore
//
//  Created by Rene Hexel on 25/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// File writing modes that depend on the runtime.
///
/// Native platforms replace generated files atomically.  WebAssembly
/// (WASI) hosts have no temporary files for an atomic replace, so files
/// are written directly there.  This keeps that difference in one place.
enum FileWritingSupport {
    /// Whether text files are replaced atomically on this runtime.
    static var writesAtomically: Bool {
        FileURIHandler.writesAtomically
    }

    /// The data writing options that replace a file atomically where supported.
    ///
    /// On native platforms this is `.atomic`; on WASI it is empty.
    static var atomicWritingOptions: Data.WritingOptions {
        #if os(WASI)
        []
        #else
        .atomic
        #endif
    }
}
