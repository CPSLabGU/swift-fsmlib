//
//  ArrangementWrapper.swift
//
//  Created by Rene Hexel on 9/10/2023.
//  Copyright © 2016, 2023, 2024, 2025 Rene Hexel. All rights reserved.
//
// swiftlint:disable large_tuple
import Foundation

/// Directory file wrapper wrapping an arrangement of Machines
open class ArrangementWrapper: DirectoryWrapper {
    /// The arrangement wrapped by this class.
    public var arrangement: Arrangement
    /// The language the arrangement is written in.
    public var language: any LanguageBinding
    /// Whether or onot the arrangement supports suspension
    public var isSuspensible = true

    /// Clone a FileWrapper.
    ///
    /// This initialiser sets up an arrangement wrapper for reading from the given file wrapper.
    /// The existing file wrapper must be a directory.
    /// - Parameter fileWrapper: The `FileWrapper` to clone.
    @inlinable
    public init(fileWrapper: FileWrapper) throws {
        let namedWrappers = try createMachineWrappers(for: fileWrapper)
        let namedInstances = namedWrappers.map {
            Instance(name: $0.instance, typeFile: $0.name, machine: $0.wrapper.machine)
        }
        arrangement = Arrangement(namedInstances: namedInstances)
        language = languageBindingIfAvailable(for: fileWrapper) ?? arrangement.namedInstances.lazy.compactMap { $0.machine.language }.first ?? CBinding()
        let machineWrappers = [String: MachineWrapper](uniqueKeysWithValues: namedWrappers.map { ($0.name, $0.wrapper) })
        super.init(directoryWithFileWrappers: machineWrappers)
        preferredFilename = fileWrapper.preferredFilename
    }
    /// Create a file wrapper for a directory with the given children.
    /// - Parameters:
    ///   - childrenByPreferredName: Child file wrappers by preferred name.
    ///   - arrangement: The arrangement to wrap.
    ///   - instanceNames: The names of the instances in the order in which they should be arranged.
    ///   - name: The preferred file name for the arrangement to wrap.
    ///   - language: The language the arrangement is written in.
    @inlinable
    public init(directoryWithFileWrappers childrenByPreferredName: [MachineName: FileWrapper] = [:], for arrangement: Arrangement, named name: String? = nil, language: (any LanguageBinding)? = nil) {
        self.arrangement = arrangement
        self.language = language ?? arrangement.namedInstances.lazy.compactMap { $0.machine.language }.first ?? CBinding()
        super.init(directoryWithFileWrappers: childrenByPreferredName)
        if let name { self.preferredFilename = name }
    }

    /// Initialise from a decoder.
    ///
    /// - Note: this is not implemented.
    ///
    /// - Parameter inCoder: The coder to initialise from.
    public required init?(coder inCoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Initialiser for reading from a URL.
    ///
    /// This initialiser sets up an arrangement file wrapper
    /// for reading from the given URL.
    ///
    /// - Parameters:
    ///   - url: The URL to read from.
    ///   - options: The reading options to use.
    /// - Throws: Any error thrown by the underlying file system.
    override public init(url: URL, options: ReadingOptions = []) throws {
        let directoryWrapper = try DirectoryWrapper(url: url, options: options)
        let namedWrappers = try createMachineWrappers(for: directoryWrapper)
        let namedInstances = namedWrappers.map {
            Instance(name: $0.instance, typeFile: $0.name, machine: $0.wrapper.machine)
        }
        language = languageBinding(for: directoryWrapper)
        arrangement = Arrangement(namedInstances: namedInstances)
        try super.init(url: url, options: options)
        for namedWrapper in namedWrappers {
            replaceFileWrapper(namedWrapper.wrapper) // replace FileWrapper with MachineWrapper
        }
        preferredFilename = url.lastPathComponent
        filename = url.lastPathComponent
    }

    /// Write the content of the arrangement to the specified location.
    ///
    /// Recursively writes the entire arrangement to the specified location.
    ///
    /// - Note: This requires that the `language` is a valid output language.
    /// - Parameters:
    ///   - url: The URL of the location to write to.
    ///   - options: The writing options to use.
    ///   - originalContentsURL: The original URL of the file wrapper.
    override open func write(to url: URL, options: FileWrapper.WritingOptions = [], originalContentsURL: URL? = nil) throws {
        guard let destination = language as? (any OutputLanguage) else {
            throw FSMError.unsupportedOutputFormat
        }
        preferredFilename = url.lastPathComponent
        let wrappersAndNames: [(wrapper: MachineWrapper, directory: Filename, instanceName: MachineName)] = try arrangement.namedInstances.compactMap {
            let fileName = $0.typeFile
            let existingWrapper: MachineWrapper?
            if let wrapper = fileWrappers?[fileName] {
                if let mw = wrapper as? MachineWrapper {
                    existingWrapper = mw
                } else if let mw = MachineWrapper(wrapper) {
                    mw.preferredFilename = fileName
                    existingWrapper = mw
                    replaceFileWrapper(mw)
                } else {
                    existingWrapper =  nil
                }
            } else {
                existingWrapper = nil
            }
            let machineWrapper: MachineWrapper
            if let existingWrapper {
                machineWrapper = existingWrapper
            } else {
#if swift(>=6)
                let machineURL = url.appending(path: fileName, directoryHint: .isDirectory)
#else
                let machineURL = url.appendingPathComponent(fileName, isDirectory: true)
#endif
                machineWrapper = try destination.createWrapper(at: machineURL, for: $0.machine)
                replaceFileWrapper(machineWrapper)
            }
            machineWrapper.language = language
            return (wrapper: machineWrapper, directory: fileName, instanceName: $0.name)
        }
        let names = wrappersAndNames.map { $0.1 }
        let fsmNames: [String] = try arrangement.add(to: self, language: destination, machineNames: names, isSuspensible: isSuspensible)
        let wrappers = wrappersAndNames.map { $0.0 }
        var fsmsWritten = Set<Filename>()
        try zip(wrappers, fsmNames).forEach {
            let machineName = $0.1
            guard !fsmsWritten.contains(machineName) else { return } // avoid duplication for multiple instances of the same machine
            let machineWrapper: MachineWrapper
            if $0.0.preferredFilename == machineName {
                machineWrapper = $0.0
            } else {
                machineWrapper = try MachineWrapper(fileWrapper: $0.0)
                machineWrapper.preferredFilename = machineName
            }
            try machineWrapper.machine.add(to: machineWrapper, language: destination, isSuspensible: isSuspensible)
            fsmsWritten.insert(machineName)
        }
        try super.write(to: url, options: options, originalContentsURL: originalContentsURL)
        filename = url.lastPathComponent
    }
}

/// Return the machine instances wrapped by the arrangment.
///
/// This function reads the Machines file containing the instances
/// and machine directories for these instances.
///
/// - Parameter directoryWrapper: The FileWrapper representing the arrangement directory.
/// - Returns: Array of tuples containing the instance names, machine names, and corresponding Machine wrappers.
@usableFromInline
func createMachineWrappers(for directoryWrapper: FileWrapper) throws -> [(instance: MachineName, name: Filename, wrapper: MachineWrapper)] {
    guard directoryWrapper.isDirectory else {
        throw FSMError.notADirectory
    }
    var allWrappers: [Filename: MachineWrapper] = [:]
    let instanceMachinePairs = Arrangement.machineNames(from: directoryWrapper.fileWrappers?[Filename.machines]?.stringContents ?? "")
    let namedWrappers: [(instance: MachineName, name: Filename, wrapper: MachineWrapper)] = instanceMachinePairs.compactMap { instanceName, name in
        let suffixedName = name + MachineWrapper.dottedSuffix
        let directoryName: Filename
        let fileWrapper: FileWrapper
        if let wrapper = directoryWrapper.fileWrappers?[name], wrapper.isDirectory {
            directoryName = name
            fileWrapper = wrapper
        } else if let wrapper = directoryWrapper.fileWrappers?[suffixedName] {
            directoryName = suffixedName
            fileWrapper = wrapper
        } else {
            return nil
        }
        let machineWrapper: MachineWrapper
        if let wrapper = allWrappers[directoryName] {
            machineWrapper = wrapper
        } else if let wrapper = MachineWrapper(fileWrapper) {
            allWrappers[directoryName] = wrapper
            machineWrapper = wrapper
        } else {
            return nil
        }
        return (instance: instanceName, name: directoryName, wrapper: machineWrapper)
    }
    return namedWrappers
}
