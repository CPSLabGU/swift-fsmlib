//
//  DirectoryWrapper.swift
//
//  Created by Rene Hexel on 13/10/2023.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
// swiftlint:disable identifier_name
import Foundation

/// A generic directory wrapper.
///
/// This class extends `FileWrapper` to represent a directory on the file system,
/// providing convenience properties for accessing the directory name with and
/// without file extensions.
open class DirectoryWrapper: FileWrapper {
    /// Return the directory name of the machine.
    @usableFromInline var _preferredDirectoryName: String?
    /// The directory name of the machine.
    ///
    /// This returns the preferred directory name,
    /// falling back to preferredFilename, filename,
    /// or the current directory name if not set.
    @usableFromInline var directoryName: String {
        get {
            _preferredDirectoryName ?? preferredFilename ?? filename ?? FileManager.default.currentDirectoryName
        } set {
            _preferredDirectoryName = newValue
        }
    }
    /// Directory name without the file extension.
    ///
    /// The directory name without the file extension,
    /// useful for converting to types or identifiers
    /// or for display or other processing purposes.
    @usableFromInline var name: String {
        let dirName = directoryName
        return dirName.lastIndex(of: ".").map {
            String(dirName[dirName.startIndex..<$0])
        } ?? dirName
    }
}
