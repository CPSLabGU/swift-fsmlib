//
//  OutputLanguage.swift
//
//  Created by Rene Hexel on 12/8/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// A language binding that can be used to generate code.
public protocol OutputLanguage: LanguageBinding {
    /// Create a file wrapper for the given URL.
    ///
    /// This is used to create the file wrapper for the
    /// given URL in preparation for writing the FSM.
    func create(at url: URL) throws
    /// Write the language information to the given URL
    /// - Parameter url: The URL to write to.
    func writeLanguage(to url: URL) throws
    /// Write the state name information to the given URL
    /// - Parameters:
    ///   - stateNames: The names of the states.
    ///   - url: The machine URL to write to.
    func write(stateNames: StateNames, to url: URL) throws
}

public extension OutputLanguage {
    /// Create a file wrapper for the given URL.
    ///
    /// This is used to create the file wrapper for the
    /// given URL in preparation for writing the FSM.
    @inlinable
    func create(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    /// Write the language information to the given URL.
    ///
    /// The default implementation creates a `Language`
    /// file inside the file wrapper denoted by the given URL.
    @inlinable
    func writeLanguage(to url: URL) throws {
        try url.write(content: name, to: .language)
    }
    /// Write the state name information to the given URL
    /// - Parameters:
    ///   - stateNames: The names of the states.
    ///   - url: The machine URL to write to.
    @inlinable
    func write(stateNames: StateNames, to url: URL) throws {
        try url.write(content: stateNames.joined(separator: "\n"), to: .states)
    }
}
