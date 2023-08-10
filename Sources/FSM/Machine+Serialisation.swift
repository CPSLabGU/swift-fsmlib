//
//  Machine+Serialisation.swift
//
//  Created by Rene Hexel on 14/10/16.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//

import Foundation

/// Representation of a file name
public typealias Filename = String

extension Filename {
    /// Name of the text file containing state names (one per line).
    static let states = "States"

    /// Name of the states layout file
    static let layout = "Layout.plist"

    /// Key for the file version
    static let fileVersionKey = "Version"

    /// Current file version value
    static let fileVersion = "1.3"

    /// key for fsm graph
    static let graph = "net.mipal.micase.graph"

    /// metadata key
    static let metaData = "net.mipal.micase.metadata"
}

extension URL {
    /// return the URL for a given file inside a FileWrapper
    /// - Parameter name: The file name to look for.
    /// - Returns: The URL for the file.
    @usableFromInline
    func forFile(_ name: Filename) -> URL { return appendingPathComponent(name) }
}
