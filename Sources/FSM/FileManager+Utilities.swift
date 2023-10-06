//
//  FileManager+Utilities.swift
//
//  Created by Rene Hexel on 30/9/2023.
//  Copyright © 2023 Rene Hexel. All rights reserved.
//
import Foundation

extension FileManager {
    /// Current directory URL.
    @usableFromInline var currentDirectoryURL: URL {
        URL(fileURLWithPath: currentDirectoryPath)
    }

    /// Name of the current directory,
    ///
    /// This returns the last path component of the current directory URL.
    @usableFromInline var currentDirectoryName: String {
        currentDirectoryURL.lastPathComponent
    }
}
