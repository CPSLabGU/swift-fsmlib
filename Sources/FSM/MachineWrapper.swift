//
//  MachineWrapper.swift
//
//  Created by Rene Hexel on 30/9/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Directory file wrapper wrapping a Machine
open class MachineWrapper: DirectoryWrapper {
    /// The machine wrapped by this class.
    public var machine: Machine
    /// The language the machine is written in.
    public var language: LanguageBinding
    /// Whether or onot the machine is suspensible
    public var isSuspensible = true

    /// Initialiser for reading from a URL.
    ///
    ///This initialiser sets up a file wrapper for  reading from the given URL.
    /// - Parameters:
    ///   - url: The URL to read from.
    ///   - options: The reading options to use.
    /// - Throws: Any error thrown by the underlying file system.
    public override init(url: URL, options: ReadingOptions = []) throws {
        let temporaryWrapper = try FileWrapper(url: url, options: options)
        machine = Machine()
        language = machine.language
        super.init(directoryWithFileWrappers: temporaryWrapper.fileWrappers ?? [:])
        preferredFilename = url.lastPathComponent
        filename = url.lastPathComponent
        machine = try Machine(from: self)
        language = machine.language
    }

    /// Designated initialiser for reading from a URL.
    ///
    ///This initialiser sets up a file wrapper for  reading from the given URL.
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
    /// - Parameters:
    ///   - childrenByPreferredName: Child file wrappers by preferred name.
    ///   - machine: The machine to wrap.
    ///   - name: The preferred file name for the machine to wrap.
    @inlinable
    public init(directoryWithFileWrappers childrenByPreferredName: [String : FileWrapper] = [:], for machine: Machine, named name: String? = nil) {
        self.machine = machine
        self.language = machine.language
        super.init(directoryWithFileWrappers: childrenByPreferredName)
        if let name { self.preferredFilename = name }
    }

    /// Initialise from a decoder.
    /// - Note: this is not implemented.
    /// - Parameter inCoder: The coder to initialise from.
    required public init?(coder inCoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Write the content of the machine to the specified location.
    ///
    /// Recursively writes the entire machine to the specified location.
    ///
    /// - Note: This requires that the `language` is a valid output language.
    /// - Parameters:
    ///   - url: The URL of the location to write to.
    ///   - options: The writing options to use.
    ///   - originalContentsURL: The original URL of the file wrapper.
    override open func write(to url: URL, options: FileWrapper.WritingOptions = [], originalContentsURL: URL? = nil) throws {
        guard let destination = language as? OutputLanguage else {
            throw FSMError.unsupportedOutputFormat
        }
        directoryName = url.lastPathComponent
        try machine.add(to: self, language: destination, isSuspensible: isSuspensible)
        try super.write(to: url, options: options, originalContentsURL: originalContentsURL)
        filename = url.lastPathComponent
    }
}
