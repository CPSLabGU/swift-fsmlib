//
//  DirectoryWrapper.swift
//
//  Created by Rene Hexel on 13/10/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// A generic directory wrapper.
open class DirectoryWrapper: FileWrapper {
    /// Return the directory name of the machine.
    @usableFromInline var _preferredDirectoryName: String?
    /// Machine directory name.
    @usableFromInline var directoryName: String {
        get {
            _preferredDirectoryName ?? preferredFilename ?? filename ?? FileManager.default.currentDirectoryName
        } set {
            _preferredDirectoryName = newValue
        }
    }
    /// Directory name without the file extension.
    @usableFromInline var name: String {
        let dirName = directoryName
        return dirName.lastIndex(of: ".").map {
            String(dirName[dirName.startIndex..<$0])
        } ?? dirName
    }
}
