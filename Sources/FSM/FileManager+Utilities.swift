//
//  FileManager+Utilities.swift
//
//  Created by Rene Hexel on 30/9/2023.
//  Copyright © 2023, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Extension providing utility properties for FileManager.
///
/// This extension adds convenience properties to FileManager for accessing
/// the current directory's URL and name, simplifying file system navigation
/// and manipulation tasks.
///
/// - Note: These utilities are useful for cross-platform code that needs to
///         work with the current working directory in a platform-independent
///         manner.
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
