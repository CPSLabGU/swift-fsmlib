//
//  MachineFileWrapper.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Single-file wrapper for machine formats.
///
/// This class provides storage for machine formats that use a single file
/// rather than a directory structure. Examples include SCXML (`.scxml`),
/// PlantUML state diagrams, and other XML/text-based FSM representations.
///
/// ## Usage
///
/// ```swift
/// // Reading
/// let storage = try MachineFileWrapper(url: URL(fileURLWithPath: "MyMachine.scxml"))
/// let machine = storage.machine
///
/// // Writing
/// let storage = MachineFileWrapper(machine: machine, named: "MyMachine.scxml")
/// try storage.write(to: url)
/// ```
///
/// ## Storage Format
///
/// Unlike `MachineDirectoryWrapper` which stores multiple files in a directory,
/// `MachineFileWrapper` stores all machine data in a single file.
/// The file format is determined by the language binding.
public class MachineFileWrapper: MachineStorage {
    /// The machine stored in this wrapper.
    public var machine: Machine

    /// The programming language binding for this machine.
    public var language: any LanguageBinding

    /// Whether the machine supports suspension.
    public var isSuspensible: Bool

    /// Internal file wrapper
    private var regularFileWrapper: FileWrapper

    /// The underlying FileWrapper (regular file).
    public var fileWrapper: FileWrapper { regularFileWrapper }

    // MARK: - Initialization

    /// Read machine from URL (MachineStorage protocol).
    ///
    /// - Parameter url: URL to the file
    /// - Throws: Error if file cannot be read or format is unsupported
    public required init(url: URL) throws {
        self.regularFileWrapper = try FileWrapper(url: url, options: [])
        guard regularFileWrapper.isRegularFile else {
            throw FSMError.notARegularFile
        }

        // Detect format and parse based on file extension
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "scxml":
            self.language = SCXMLBinding()
            guard let data = regularFileWrapper.regularFileContents else {
                throw FSMError.notARegularFile
            }
            let parser = SCXMLParser()
            self.machine = try parser.parse(data)
            self.isSuspensible = true

        default:
            throw FSMError.unsupportedInputFormat
        }
    }

    /// Create storage for a machine (MachineStorage protocol).
    ///
    /// - Parameters:
    ///   - machine: The machine to store
    ///   - name: Preferred filename (e.g., "MyMachine.scxml")
    public required init(machine: Machine, named name: String) {
        self.machine = machine
        self.language = machine.language
        self.isSuspensible = true
        self.regularFileWrapper = FileWrapper(regularFileWithContents: Data())
        self.regularFileWrapper.preferredFilename = name
        self.regularFileWrapper.filename = name
    }

    // MARK: - Writing

    /// Write the storage to the given URL with options (MachineStorage protocol).
    ///
    /// This method generates the file content using the language binding
    /// and writes it to the specified location.
    ///
    /// - Parameters:
    ///   - url: The URL to write to
    ///   - options: Writing options (ignored for single-file formats)
    /// - Throws: Error if writing fails or language doesn't support output
    public func write(to url: URL, options: FileWrapper.WritingOptions) throws {
        // Update filename
        regularFileWrapper.preferredFilename = url.lastPathComponent
        regularFileWrapper.filename = url.lastPathComponent

        // Format-specific writing
        let ext = url.pathExtension.lowercased()
        switch ext {
        case Format.scxml.fileExtension:
            if let scxmlBinding = language as? SCXMLBinding {
                try scxmlBinding.write(machine, to: url)
            } else {
                throw FSMError.unsupportedOutputFormat
            }

        default:
            throw FSMError.unsupportedOutputFormat
        }
    }

    /// Write the storage to the given URL (MachineStorage protocol).
    ///
    /// This override provides atomic writing for single-file formats.
    /// The atomic write is handled by the language binding's write method.
    ///
    /// - Parameter url: The URL to write to
    /// - Throws: Error if writing fails or language doesn't support output
    public func write(to url: URL) throws {
        // Single-file formats use atomic writes by default
        // The options parameter is not relevant for formats like SCXML
        // which handle atomicity in their write(to:) methods
        try write(to: url, options: [])
    }
}
