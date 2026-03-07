//
//  MachineStorage.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Protocol for machine storage abstractions.
///
/// This protocol provides a common interface for both directory-based
/// machine storage (`.machine` directories) and single-file machine storage
/// (`.scxml` files). It enables the FSM library to work uniformly with
/// different storage formats while maintaining type safety.
///
/// ## Architecture
///
/// The storage hierarchy uses composition instead of inheritance to avoid
/// the diamond problem. Each storage type wraps a `FileWrapper` and provides
/// machine-specific functionality on top.
///
/// ## Conforming Types
///
/// - `MachineDirectoryWrapper`: Directory-based storage for `.machine` formats
/// - `MachineFileWrapper`: Single-file storage for `.scxml` and similar formats
///
/// ## Usage
///
/// Use `MachineStorageFactory` to create appropriate storage based on URL or format:
///
/// ```swift
/// // Reading
/// let storage = try MachineStorageFactory.create(from: url)
/// let machine = storage.machine
///
/// // Writing
/// let storage = MachineStorageFactory.create(for: machine, format: .scxml, at: url)
/// try storage.write(to: url)
/// ```
public protocol MachineStorage: AnyObject {
    /// The machine stored in this wrapper.
    var machine: Machine { get set }

    /// The programming language binding for this machine.
    var language: any LanguageBinding { get set }

    /// Whether the machine supports suspension.
    var isSuspensible: Bool { get set }

    /// The machine name (without file extension).
    var name: String { get }

    /// The underlying FileWrapper (directory or regular file).
    var fileWrapper: FileWrapper { get }

    /// Read machine from URL.
    ///
    /// - Parameter url: The URL to read from
    /// - Throws: Error if reading fails or format is unsupported
    init(url: URL) throws

    /// Create storage for a machine.
    ///
    /// - Parameters:
    ///   - machine: The machine to store
    ///   - name: Preferred filename
    init(machine: Machine, named name: String)

    /// Write the storage to the given URL with options.
    ///
    /// - Parameters:
    ///   - url: The URL to write to
    ///   - options: Writing options
    /// - Throws: Any error during writing
    func write(to url: URL, options: FileWrapper.WritingOptions) throws

    /// Write the storage to the given URL.
    ///
    /// This method provides format-specific default writing behavior.
    /// Implementations can override this to provide format-specific defaults
    /// (e.g., atomic writes for single files).
    ///
    /// - Parameter url: The URL to write to
    /// - Throws: Any error during writing
    func write(to url: URL) throws
}

/// Default implementations for MachineStorage.
public extension MachineStorage {
    /// Default name extraction from file wrapper filename.
    var name: String {
        let filename = fileWrapper.preferredFilename ?? fileWrapper.filename ?? "Unnamed"
        return filename.lastIndex(of: ".").map {
            String(filename[filename.startIndex..<$0])
        } ?? filename
    }

    /// Default write implementation that calls write(to:options:) with empty options.
    ///
    /// Implementations can override this to provide format-specific behavior.
    func write(to url: URL) throws {
        try write(to: url, options: [])
    }
}
