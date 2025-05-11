//
//  Machine+Serialisation.swift
//
//  Created by Rene Hexel on 14/10/16.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Representation of a file name
public typealias Filename = String

/// Extension providing filename constants for machine serialisation.
///
/// This extension defines standard filenames and keys used for serialising
/// and deserialising finite-state machines, including state lists, layouts,
/// and metadata files. These constants ensure consistency across file
/// operations and persistent storage.
///
/// - Note: Use these constants when reading or writing FSM-related files to
///         avoid hardcoding filenames throughout the codebase.
extension Filename {
    /// Programming language for the given machine.
    @usableFromInline static let language = "Language"

    /// Name of the text file containing state names (one per line).
    @usableFromInline static let states = "States"

    /// Name of the machine layout file
    @usableFromInline static let layout = "Layout.plist"

    /// Name of the window layout file
    @usableFromInline static let windowLayout = "WindowLayout.plist"

    /// Name of the include path file
    @usableFromInline static let includePath = "IncludePath"

    /// Key for the file version
    @usableFromInline static let fileVersionKey = "Version"

    /// Current file version value
    @usableFromInline static let fileVersion = "1.3"

    /// key for fsm graph
    @usableFromInline static let graph = "net.mipal.micase.graph"

    /// metadata key
    @usableFromInline static let metaData = "net.mipal.micase.metadata"
}

/// Extension providing file and content utilities for URL.
///
/// This extension adds convenience methods for constructing file URLs,
/// reading file contents as data or strings, and writing data or strings to
/// files. These utilities simplify file I/O for FSM serialisation and
/// deserialisation.
///
/// - Note: These methods return `nil` or empty strings if files do not exist
///         or cannot be read, making them safe for optional file operations.
extension URL {
    /// Return the URL for a given file name.
    ///
    /// This method returns the URL for a given file inside a FileWrapper
    ///
    /// - Parameter name: The file name to look for.
    /// - Returns: The URL for the file.
    @usableFromInline
    func fileURL(for name: Filename) -> URL { return appendingPathComponent(name) }

    /// Return the content of the given file.
    ///
    /// This method reads the content of
    /// the given file inside a FileWrapper
    /// into Data.
    ///
    /// - Note: If the file does not exist, or cannot be read, `nil` is returned.
    ///
    /// - Parameters:
    ///   - file: The file name to look for.
    ///   - options: The flags to pass when reading data.
    /// - Returns: The content of the file.
    @usableFromInline
    func contents(of file: Filename, options: Data.ReadingOptions = .mappedIfSafe) -> Data? {
        try? Data(contentsOf: fileURL(for: file), options: options)
    }

    /// Return the string content of the given file.
    ///
    /// This method reads the content of
    /// the given file inside a FileWrapper
    /// into a String.
    ///
    /// - Note: If the file does not exist, or cannot be read, an empty string is returned.
    ///
    /// - Parameters:
    ///   - file: The file name to look for.
    ///   - encoding: The encoding to use (defaults to UTF-8).
    /// - Returns: The content of the file.
    @usableFromInline
    func stringContents(of file: Filename, encoding: String.Encoding = .utf8) -> String {
        (try? String(contentsOf: fileURL(for: file), encoding: .utf8)) ?? ""
    }

    /// Write the given data to the given file.
    /// - Parameters:
    ///   - data: The data to write.
    ///   - encoding: The encoding to use (defaults to UTF-8).
    ///   - file: The file name to write to.
    @usableFromInline
    func write(_ data: Data?, options: Data.WritingOptions = .atomic, to file: Filename) throws {
        try data?.write(to: fileURL(for: file), options: options)
    }

    /// Write the given string to the given file.
    /// - Parameters:
    ///   - content: The string to write.
    ///   - encoding: The encoding to use (defaults to UTF-8).
    ///   - file: The file name to write to.
    @usableFromInline
    func write(content: String, encoding: String.Encoding = .utf8, to file: Filename) throws {
        try content.write(to: fileURL(for: file), atomically: true, encoding: encoding)
    }
}
