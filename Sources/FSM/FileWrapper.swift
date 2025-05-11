//
//  FileWrapper.swift
//
//  Created by Rene Hexel on 1/10/2023.
//  Copyright © 2023, 2025 Rene Hexel. All rights reserved.
//
// swiftlint:disable:this type_contents_order
import Foundation
#if !canImport(Darwin)
import SystemPackage

/// A file wrapper is a wrapper around a filesystem object.
///
/// The FileWrapper class provides a convenient way to access the contents
/// of files, directories, or symbiolic links.  It provides a uniform interface to their
/// contents, regardless of their underlying representation on disk.
/// In addition to representing a regular file, a directory, or a symbolic link,
/// a FileWrapper subclass can also represent a custom file type that you define.
open class FileWrapper: @unchecked Sendable {
    /// The content of the file wrapper.
    @usableFromInline var content: Content?
    /// The URL of the file wrapper.
    @usableFromInline var url: URL?
    /// The resource values associated with the URL
    @usableFromInline var resourceValues = URLResourceValues()
    /// Reading options for the file wrapper.
    @usableFromInline var readingOptions: ReadingOptions = []
    /// Writing options for the file wrapper.
    @usableFromInline var writingOptions: WritingOptions = []
    /// Return the file name of the file wrapper.
    open var filename: String?
    /// Return the preferred file name of the file wrapper.
    open var preferredFilename: String?
    /// Returns whether the file wrapper is a directory.
    @inlinable open var isDirectory: Bool {
        content?.isDirectory ?? resourceValues.isDirectory ?? false
    }
    /// Returns whether the file wrapper is a directory.
    @inlinable open var isSymbolicLink: Bool {
        content?.isSymbolicLink ?? resourceValues.isSymbolicLink ?? false
    }
    /// Returns whether the file wrapper is a directory.
    @inlinable open var isRegularFile: Bool {
        content?.isRegularFile ?? resourceValues.isRegularFile ?? false
    }
    /// Returns the regular file contents of the file wrapper.
    @inlinable open var regularFileContents: Data? {
        guard isRegularFile else { return nil }
        if content == nil { try? read() }
        guard case let .data(regularFileContents) = content else { return nil }
        return regularFileContents
    }
    /// Returns the file wrappers contained in a directory.
    @inlinable open var fileWrappers: [String: FileWrapper]? {
        guard isDirectory else { return nil }
        if content == nil { try? read() }
        guard case let .directory(fileWrappers) = content else { return nil }
        return fileWrappers
    }
    /// Designated initialiser for reading from a URL.
    ///
    ///This initialiser sets up a file wrapper for  reading from the given URL.
    /// - Parameters:
    ///   - url: The URL to read from.
    ///   - options: The reading options to use.
    /// - Throws: Any error thrown by the underlying file system.
    @inlinable
    public init(url: URL, options: ReadingOptions = []) throws {
        self.url = url
        self.filename = url.lastPathComponent
        self.preferredFilename = url.lastPathComponent
        self.readingOptions = options
        self.resourceValues = try url.resourceValues(forKeys: urlKeys)
        if options.contains(.immediate) {
            try read()
        }
    }

    /// Designated initialiser for a regular file FileWrapper.
    /// - Parameter contents: The file contents.
    @inlinable
    public init(regularFileWithContents contents: Data) {
        content = .data(contents)
    }

    /// Designated initialiser for a directory FileWrapper.
    ///
    /// This initialiser sets up a file wrapper for a directory with the given
    /// file wrappers as children.
    /// - Parameter childrenByPreferredName:
    @inlinable
    public init(directoryWithFileWrappers childrenByPreferredName: [String: FileWrapper]) {
        content = .directory(childrenByPreferredName)
    }

    /// Designated initialiser for a symbolic link FileWrapper.
    /// - Parameter url: Destination URL of the symbolic link.
    @inlinable
    public init(symbolicLinkWithDestinationURL url: URL) {
        content = .symbolicLink(url)
    }

    /// Read form the given URL.
    ///
    /// Recursively reads the contents of the file wrapper from the given URL.
    /// When reading a directory, the contents of the directory are read as
    /// child file wrappers.
    /// - Parameters:
    ///   - url: The URL to read from.
    ///   - options: The reading options to use.
    @inlinable
    open func read(from url: URL, options: ReadingOptions = []) throws {
        self.url = url
        self.filename = url.lastPathComponent
        self.preferredFilename = url.lastPathComponent
        self.readingOptions = options
        try read()
    }

    /// Read the file wrapper contents.
    @usableFromInline
    func read() throws {
        if isDirectory {
            try readDirectory()
        } else if isSymbolicLink {
            try readSymbolicLink()
        } else if isRegularFile {
            try readRegularFile()
        }
    }

    /// Read the directory associated with the file wrapper.
    @usableFromInline
    func readDirectory() throws {
        guard let url else { throw POSIXError(.EBADF) }
        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: Array(urlKeys))
        var children = [Filename: FileWrapper]()
        try contents.forEach {
            children[$0.lastPathComponent] = try FileWrapper(url: $0, options: readingOptions)
        }
        content = .directory(children)
    }

    /// Read the symbolic link associated with the file wrapper.
    @usableFromInline
    func readSymbolicLink() throws {
        guard let url else { throw POSIXError(.EBADF) }
        let fileManager = FileManager.default
        let destination = try fileManager.destinationOfSymbolicLink(atPath: url.path)
        var isDirectory: ObjCBool = false
        _ = fileManager.fileExists(atPath: destination, isDirectory: &isDirectory)
        content = .symbolicLink(URL(fileURLWithPath: destination, isDirectory: isDirectory.boolValue))
    }

    /// Read the file associated with the file wrapper.
    @usableFromInline
    func readRegularFile() throws {
        guard let url else { throw POSIXError(.EBADF) }
        let data = try Data(contentsOf: url, options: readingOptions.contains(.withoutMapping) ? [] : .mappedIfSafe)
        content = .data(data)
    }

    /// Write the file wrapper to the given URL.
    ///
    /// This function (recursively) writes the entire content
    /// of the file wrapper to the given URL.
    /// - Note: a non-nil `originalContentsURL` tells this method
    /// to avoid unnecessary I/O (e.g. by creating hard links) if possible.
    /// - Parameters:
    ///   - url: The URL to write to.
    ///   - options: The writing options to use.
    ///   - originalContentsURL: The original URL of the file wrapper contents.
    @inlinable
    open func write(to url: URL, options: FileWrapper.WritingOptions = [], originalContentsURL: URL? = nil) throws {
        self.url = url
        self.writingOptions = options
        if isDirectory {
            try writeDirectory(originalContentsURL: originalContentsURL)
        } else if isSymbolicLink {
            try writeSymbolicLink()
        } else if isRegularFile {
            try writeRegularFile(originalContentsURL: originalContentsURL)
        }
    }

    /// Write the directory file wrapper to its associated URL.
    ///
    /// This function recursively writes the entire content
    /// of the file wrapper to the given URL.
    /// - Note: a non-nil `originalContentsURL` tells this method
    /// to avoid unnecessary I/O (e.g. by creating hard links) if possible.
    /// - Parameter originalContentsURL: The original URL of the file wrapper contents (or `nil`).
    @usableFromInline
    func writeDirectory(originalContentsURL: URL? = nil) throws {
        guard let url, case let .directory(children) = content else { throw POSIXError(.EBADF) }
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        for (file, fileWrapper) in children {
#if canImport(Darwin)
            let fileURL = url.appending(path: file, directoryHint: fileWrapper.isDirectory ? .isDirectory : .notDirectory)
            let originalURL = originalContentsURL.map { $0.appending(path: file, directoryHint: .notDirectory) }
#else
            let fileURL = url.appendingPathComponent(file, isDirectory: fileWrapper.isDirectory)
            let originalURL = originalContentsURL.map { $0.appendingPathComponent(file, isDirectory: false) }
#endif
            try fileWrapper.write(to: fileURL, options: writingOptions, originalContentsURL: originalURL)
        }
        if writingOptions.contains(.withNameUpdating) {
            filename = url.lastPathComponent
            preferredFilename = url.lastPathComponent
        }
    }

    /// Write the file associated with the file wrapper.
    @usableFromInline
    func writeRegularFile(originalContentsURL: URL? = nil) throws {
        guard let url else { throw POSIXError(.EBADF) }
        try writeData(to: url, originalContentsURL: originalContentsURL)
    }

    /// Write the file associated with the file wrapper.
    /// - Parameters:
    ///   - url: The URL to write the data to.
    ///   - originalContentsURL: The original URL of the file wrapper contents (or `nil`).
    @usableFromInline
    func writeData(to url: URL, originalContentsURL: URL? = nil) throws {
        if let originalContentsURL,
           let originalData = try? Data(contentsOf: originalContentsURL, options: readingOptions.contains(.withoutMapping) ? [] : .mappedIfSafe) {
            let writeLink: Bool
            if case let .data(data) = content {
                writeLink = data == originalData
            } else {
                writeLink = true
            }
            if writeLink {
                do {
                    try FileManager.default.linkItem(at: originalContentsURL, to: url)
                    return
                } catch {
                    // ignore and fall back to writing file data
                }
            }
        }
        guard case let .data(data) = content else { throw POSIXError(.EINVAL) }
        try data.write(to: url, options: writingOptions.contains(.atomic) ? .atomic : [])
        if writingOptions.contains(.withNameUpdating) {
            filename = url.lastPathComponent
            preferredFilename = url.lastPathComponent
        }
    }

    /// Write the symbolic link associated with the file wrapper.
    @usableFromInline
    func writeSymbolicLink() throws {
        guard let url, case let .symbolicLink(destinationURL) = content else { throw POSIXError(.EBADF) }
        try FileManager.default.createSymbolicLink(at: url, withDestinationURL: destinationURL)
    }

    /// Add a child `FileWrapper`.
    /// - Parameter child: The child `FileWrapper` to add.
    /// - Returns: The filename of the added child.
    @discardableResult @inlinable
    open func addFileWrapper(_ child: FileWrapper) -> String {
        guard case var .directory(children) = content else { return "" }
        let filename = child.filename ?? child.preferredFilename ?? UUID().uuidString
        children[filename] = child
        content = .directory(children)
        return filename
    }

    /// Remove a child `FileWrapper`.
    /// - Parameter child: The child `FileWrapper` to remove.
    @inlinable
    open func removeFileWrapper(_ child: FileWrapper) {
        guard case var .directory(children) = content else { return }
        for (filename, fileWrapper) in children where fileWrapper === child {
            child.removeFileWrappers()
            if let url = child.url {
                try? FileManager.default.removeItem(at: url)
            } else if let url = url {
                let fileURL = url.appendingPathComponent(filename)
                try? FileManager.default.removeItem(at: fileURL)
            }
            children[filename] = nil
            content = .directory(children)
            break
        }
    }
}

public extension FileWrapper {
    /// The reading options for the file wrapper.
    struct ReadingOptions: OptionSet, @unchecked Sendable {
        /// Raw value of the reading options.
        public var rawValue: UInt
        /// Designated raw value initialiser.
        /// - Parameter rawValue: The raw value to initialise with.
        @inlinable
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        /// Read the file wrapper immediately.
        ///
        /// This option causes the file wrapper to
        /// read its content immediatelay after creation.
        public static var immediate: FileWrapper.ReadingOptions { .init(rawValue: 1) }
        /// Do not use memory mapping.
        ///
        /// This option causes the file wrapper to
        /// read its content without attempting to use
        /// memory mapping.
        ///
        /// - Note: this option is useful to prevent
        /// the file wrapper to keep a file open, whiich
        /// may prevent media from being ejected.
        public static var withoutMapping: FileWrapper.ReadingOptions { .init(rawValue: 2) }
    }

    /// The writeing options for the file wrapper.
    struct WritingOptions: OptionSet, @unchecked Sendable {
        /// Raw value of the writeing options.
        public var rawValue: UInt
        /// Designated raw value initialiser.
        /// - Parameter rawValue: The raw value to initialise with.
        @inlinable
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        /// Write the file wrapper atomically.
        ///
        /// This option causes the file wrapper to
        /// write its content atomically, i.e. the
        /// file wrapper will write to a temporary
        /// file and then rename it to the target
        /// file name.
        public static var atomic: FileWrapper.WritingOptions { .init(rawValue: 1) }
        /// Update the file name on successful write.
        ///
        /// This option causes the file wrapper to
        /// update its file name to the target file
        /// name if the write operation succeeds.
        public static var withNameUpdating: FileWrapper.WritingOptions { .init(rawValue: 2) }
    }
}

extension FileWrapper {
    /// The content of a FileWrapper.
    @usableFromInline enum Content {
        /// File data associated with the FileWraper.
        case data(Data)
        /// Directory Bundle of FileWrapper.
        case directory([Filename: FileWrapper])
        /// Symbolic link target URL of FileWrapper.
        case symbolicLink(URL)

        /// Return whether the content is a regular file.
        @inlinable var isRegularFile: Bool {
            if case .data = self { return true }
            return false
        }
        /// Return whether the content is a directory bundle.
        @inlinable var isDirectory: Bool {
            if case .directory = self { return true }
            return false
        }
        /// Return whether the content is a symbolic link.
        @inlinable var isSymbolicLink: Bool {
            if case .symbolicLink = self { return true }
            return false
        }
    }
}

@usableFromInline let urlKeys: Set<URLResourceKey> = [.isDirectoryKey, .isSymbolicLinkKey, .isRegularFileKey]
#endif

extension FileWrapper {

    /// Return the contents of the given file as a String.
    ///
    /// - Parameter fileName: Name of the file inside the receiver.
    /// - Returns: The contents of the file as a String.
    @usableFromInline
    func stringContents(of fileName: String) -> String? {
        fileWrappers?[fileName]?.stringContents
    }

    /// Return the regular file contents as a String.
    @usableFromInline var stringContents: String? {
        regularFileContents.flatMap { String(data: $0, encoding: .utf8) }
    }

    /// Replace a child `FileWrapper`.
    ///
    /// This method checks wether the given child
    /// file wrapper already exists, and if so, removes
    /// the existing wrapper before adding the new one.
    ///
    /// - Parameter child: The child fileWrapper to replace.
    @usableFromInline
    func replaceFileWrapper(_ child: FileWrapper) {
        if let existingChild = (child.preferredFilename ?? child.filename).flatMap({ fileWrappers?[$0] }) {
            removeFileWrapper(existingChild)
        }
        addFileWrapper(child)
    }

    /// Remove all child FileWrappers.
    @usableFromInline
    func removeFileWrappers() {
        let wrappers = fileWrappers?.map { $0.value } ?? []
        for fileWrapper in wrappers {
            removeFileWrapper(fileWrapper)
        }
    }
}

/// Create a file wrapper for a given String.
///
/// This function will convert the given String
/// into a regular `FileWrapper` using the
/// given encoding.
///
/// - Parameters:
///   - name: The preferred file name for the `FileWrapper`
///   - string: The string to convert into data for the `FileWrapper` (empty if `nil`).
///   - encoding: The encoding to use when converting the string into data.
/// - Returns: The created `FileWrapper`.
@usableFromInline
func fileWrapper(named name: String, from string: String?, encoding: String.Encoding = .utf8) -> FileWrapper {
    fileWrapper(named: name, from: string?.data(using: encoding))
}

/// Create a file wrapper for the given Data.
///
/// This function will convert the given Data
/// into a regular `FileWrapper`.
/// - Parameters:
///   - name: The preferred file name for the `FileWrapper`
///   - data: The data to store in the `FileWrapper` (empty if `nil`).
/// - Returns: The created `FileWrapper`.
@usableFromInline
func fileWrapper(named name: String, from data: Data?) -> FileWrapper {
    let content = data ?? Data()
    let fileWrapper = FileWrapper(regularFileWithContents: content)
    fileWrapper.preferredFilename = name
    return fileWrapper
}
