//
//  MachineStorageFactory.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Factory for creating appropriate machine storage based on URL or format.
///
/// This factory provides a centralized way to create the correct storage type
/// (directory-based or single-file) based on file extensions and format specifications.
///
/// ## Usage
///
/// ```swift
/// // Reading
/// let storage = try MachineStorageFactory.read(from: url)
/// let machine = storage.machine
///
/// // Writing
/// let storage = MachineStorageFactory.create(
///     for: machine,
///     format: .scxml,
///     at: outputURL
/// )
/// try storage.write(to: outputURL)
/// ```
public enum MachineStorageFactory {

    /// Read machine storage from a URL.
    ///
    /// This method automatically detects the storage type based on whether
    /// the URL points to a directory or a regular file.
    ///
    /// - Parameter url: The URL to read from
    /// - Returns: Appropriate MachineStorage instance
    /// - Throws: Error if reading fails or format is unsupported
    public static func read(from url: URL) throws -> any MachineStorage {
        // Detect based on file/directory
        let wrapper = try FileWrapper(url: url, options: [])

        if wrapper.isDirectory {
            return try MachineDirectoryWrapper(url: url)
        } else if wrapper.isRegularFile {
            return try MachineFileWrapper(url: url)
        } else {
            throw FSMError.unsupportedInputFormat
        }
    }

    /// Create storage for writing a machine.
    ///
    /// This method creates the appropriate storage type based on the
    /// specified format. If no format is specified, it attempts to infer
    /// the format from the URL extension. The machine's language binding
    /// is updated to match the target format without modifying the original.
    ///
    /// - Parameters:
    ///   - machine: The machine to store
    ///   - format: The desired output format (optional, inferred from URL if nil)
    ///   - url: The URL to write to
    /// - Returns: Appropriate MachineStorage instance
    public static func create(
        for machine: Machine,
        format: Format?,
        at url: URL
    ) -> any MachineStorage {
        // Determine format from parameter or URL extension
        let targetFormat: Format?
        if let format {
            targetFormat = format
        } else {
            let ext = url.pathExtension.lowercased()
            targetFormat = Format.allCases.first { $0.fileExtension == ext }
        }

        // Determine target language binding
        let targetLanguage: (any LanguageBinding)?
        if let targetFormat, let language = formatToLanguageBinding[targetFormat] {
            targetLanguage = language
        } else {
            targetLanguage = nil
        }

        // Copy machine with new language binding
        let machineToStore = Machine(copying: machine, language: targetLanguage)

        // Create appropriate storage type based on format
        if let targetFormat, targetFormat.isSingleFile {
            return MachineFileWrapper(machine: machineToStore, named: url.lastPathComponent)
        } else {
            // Default to directory-based storage
            return MachineDirectoryWrapper(machine: machineToStore, named: url.lastPathComponent)
        }
    }
}
