//
//  MachineWrapper.swift
//
//  Created by Rene Hexel on 30/9/2023.
//  Copyright © 2016, 2023, 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Directory file wrapper wrapping a Machine
///
/// This class provides directory-based storage for FSM machines,
/// where each machine is stored as a directory containing multiple files
/// (states, transitions, boilerplate, etc.).
///
/// - Note: For single-file formats like SCXML, use `MachineFileWrapper` instead.
open class MachineDirectoryWrapper: DirectoryWrapper, MachineStorage {
    /// The preferred file extension used for a machine wrapper.
    public static let fileExtension = "machine"
    /// The suffix to add to a machine name
    public static let dottedSuffix = "." + fileExtension
    /// The machine wrapped by this class.
    open var machine: Machine
    /// The language the machine is written in.
    open var language: any LanguageBinding
    /// Whether or not the machine is suspensible.
    open var isSuspensible = true

    // MARK: - MachineStorage Conformance

    /// The underlying FileWrapper (directory).
    public var fileWrapper: FileWrapper { self }

    /// Initialiser for reading from a URL (MachineStorage protocol).
    ///
    /// This initialiser sets up a file wrapper for reading from the given URL.
    ///
    /// - Parameter url: The URL to read from.
    /// - Throws: Any error thrown by the underlying file system.
    public required convenience init(url: URL) throws {
        let temporaryWrapper = try FileWrapper(url: url, options: [])
        try self.init(fileWrapper: temporaryWrapper)
        preferredFilename = url.lastPathComponent
        filename = url.lastPathComponent
    }

    /// Create storage for a machine (MachineStorage protocol).
    ///
    /// - Parameters:
    ///   - machine: The machine to store
    ///   - name: Preferred filename
    public required init(machine: Machine, named name: String) {
        self.machine = machine
        self.language = machine.language
        super.init(directoryWithFileWrappers: [:])
        self.preferredFilename = name
    }

    // MARK: - Legacy Initializers

    /// Initialiser for reading from a URL with options.
    ///
    /// This initialiser sets up a file wrapper for  reading from the given URL.
    ///
    /// - Parameters:
    ///   - url: The URL to read from.
    ///   - options: The reading options to use.
    /// - Throws: Any error thrown by the underlying file system.
    override public convenience init(url: URL, options: ReadingOptions = []) throws {
        let temporaryWrapper = try FileWrapper(url: url, options: options)
        try self.init(fileWrapper: temporaryWrapper)
        preferredFilename = url.lastPathComponent
        filename = url.lastPathComponent
    }

    /// Designated initialiser for reading from a URL.
    ///
    /// This initialiser sets up a file wrapper for  reading from the given URL.
    ///
    /// - Parameters:
    ///   - url: The URL to read from.
    ///   - options: The reading options to use.
    /// - Throws: Any error thrown by the underlying file system.
    @inlinable
    public init(for machine: Machine, url: URL, options: ReadingOptions = []) throws {
        let temporaryWrapper = try FileWrapper(url: url, options: options)
        self.machine = machine
        self.language = machine.language
        super.init(directoryWithFileWrappers: temporaryWrapper.fileWrappers ?? [:])
        preferredFilename = url.lastPathComponent
        filename = url.lastPathComponent
    }

    /// Create a file wrapper for a directory with the given children.
    ///
    /// This initialiser sets up a file wrapper for a directory with the given
    /// children.
    ///
    /// - Parameters:
    ///   - childrenByPreferredName: Child file wrappers by preferred name.
    ///   - machine: The machine to wrap.
    ///   - name: The preferred file name for the machine to wrap.
    @inlinable
    public init(directoryWithFileWrappers childrenByPreferredName: [String: FileWrapper], for machine: Machine, named name: String? = nil) {
        self.machine = machine
        self.language = machine.language
        super.init(directoryWithFileWrappers: childrenByPreferredName)
        if let name { self.preferredFilename = name }
    }

    /// Initialise from an existing directory wrapper.
    ///
    /// This initialiser sets up a machine wrapper from an existing
    /// directory wrapper.
    ///
    /// - Parameter fileWrapper: The original FileWrapper to initialise from.
    @inlinable
    public init(fileWrapper: FileWrapper) throws {
        guard fileWrapper.isDirectory else { throw FSMError.notADirectory }
        machine = Machine()
        language = machine.language
        super.init(directoryWithFileWrappers: fileWrapper.fileWrappers ?? [:])
        preferredFilename = fileWrapper.preferredFilename
        machine = try Machine(from: self)
        language = machine.language
    }
    /// Failable initialiser from a file Wrapper.
    ///
    /// This initialiser sets up a machine wrapper from an existing
    /// directory wrapper.  It fails if a `Machine` cannot be
    /// created from the wrapper or `FileWrapper` is not a
    /// directory wrapper.
    /// - Parameter fileWrapper: The original FileWrapper to initialise from.
    public convenience init?(_ fileWrapper: FileWrapper) {
        do {
            try self.init(fileWrapper: fileWrapper)
        } catch {
            return nil
        }
    }
    /// Initialise from a decoder.
    ///
    /// - Note: this is not implemented.
    ///
    /// - Parameter inCoder: The coder to initialise from.
    public required init?(coder inCoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Write the content of the machine to the specified location (MachineStorage protocol).
    ///
    /// Recursively writes the entire machine to the specified location.
    ///
    /// - Note: This requires that the `language` is a valid output language.
    /// - Parameters:
    ///   - url: The URL of the location to write to.
    ///   - options: The writing options to use.
    /// - Throws: Any error thrown during writing.
    public func write(to url: URL, options: FileWrapper.WritingOptions) throws {
        guard let destination = language as? (any OutputLanguage) else {
            throw FSMError.unsupportedOutputFormat
        }
        directoryName = url.lastPathComponent
        try machine.add(to: self, language: destination, isSuspensible: isSuspensible)
        try super.write(to: url, options: options, originalContentsURL: nil)
        filename = url.lastPathComponent
    }

    /// Write the content of the machine to the specified location (MachineStorage protocol).
    ///
    /// This is a convenience method that uses default options for directory writing.
    ///
    /// - Parameter url: The URL of the location to write to.
    /// - Throws: Any error thrown during writing.
    public func write(to url: URL) throws {
        try write(to: url, options: [])
    }
}
