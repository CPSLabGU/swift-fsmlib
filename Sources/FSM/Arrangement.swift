//
//  Arrangement.swift
//
//  Created by Rene Hexel on 17/08/2023.
//  Copyright © 2015, 2016, 2023, 2024, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Arrangement of multiple finite-state machines (FSMs).
///
/// This struct represents a collection of FSM instances, allowing for the
/// grouping and management of multiple machines as a single arrangement.
/// Arrangements are used to coordinate the serialisation, deserialisation,
/// and code generation for sets of related FSMs.
///
/// - Note: Arrangements are typically used to model systems composed of
///         multiple interacting FSMs, supporting batch operations and
///         persistent storage of machine groups.
public struct Arrangement {
    /// The FSMs in the arrangement and their names.
    public var namedInstances: [Instance]

    /// Designated initialiser.
    ///
    /// This initialiser creates an arrangement of FSMs
    /// from the given array of machines.
    ///
    /// - Parameter namedInstances: The machines in this arrangement.
    @inlinable
    public init(namedInstances: [Instance]) {
        self.namedInstances = namedInstances
    }
    /// Constructor for reading an arrangement from a given URL.
    ///
    /// This initialiser will read the machines from
    /// the `ArrangementWrapper` at the given URL.
    ///
    /// - Note: The URL is expected to point to a directory containing the arrangement.
    /// - Parameter url: The URL to read the arrangement from.
    @inlinable
    public init(from url: URL) throws {
        let wrapper = try ArrangementWrapper(url: url)
        try self.init(from: wrapper)
    }
    /// Constructor for reading an arrangement from a file wrapper.
    ///
    /// This initialiser creates an arrangement of FSMs
    /// from the given file wrapper.
    ///
    /// - Note: The `ArrangementWrapper` is expected to point to a directory containing the machines.
    /// - Parameter arrangementWrapper: The `ArrangementWrapper` to read from.
    @inlinable
    public init(from arrangementWrapper: ArrangementWrapper) throws {
        let instances = arrangementWrapper.fileWrappers?.compactMap { element in
            MachineWrapper(element.value).map { Instance(name: element.key, typeFile: arrangementWrapper.name, machine: $0.machine) }
        } ?? []
        self.init(namedInstances: instances)
    }
}

/// Extension providing convenience properties for accessing and mutating
/// arrangement properties.
public extension Arrangement {
    /// Add the arrangement to the given `ArrangementWrapper`.
    ///
    /// This method creates a file wrapper for an arrangement of FSMs and writes
    /// it to the given `ArrangementWrapper`. It generates code and metadata for
    /// each FSM, ensuring that all required files are created and properly named.
    ///
    /// - Parameters:
    ///   - wrapper: The output `ArrangementWrapper` to add to.
    ///   - language: The output language format to use.
    ///   - machineNames: The names associated with the FSMs.
    ///   - isSuspensible: Whether the output FSMs should be suspensible.
    /// - Returns: The filenames of the machines for adding to the arrangement.
    /// - Throws: An error if writing to the wrapper fails.
    ///
    /// - Note: This method is used for batch generation of FSM arrangements.
    @inlinable
    func add(to wrapper: ArrangementWrapper, language: any OutputLanguage, machineNames: [String], isSuspensible: Bool = true) throws -> [Filename] {
        var instanceMappings = [String: (String, Machine)]()
        let instances = namedInstances.map {
            let machine = $0.machine
            let fileName = $0.name
            let instanceName = String(fileName.sansExtension)
            var j = 1
            var uniqueName = instanceName
            var resolvedFile = fileName
            var resolvedMachine = machine
            while let (existingName, existingMachine) = instanceMappings[uniqueName] {
                defer { j += 1 }
                uniqueName = "\(instanceName)_\(j)"
                if fileName == existingName { // avoid duplication
                    resolvedMachine = existingMachine
                    resolvedFile = existingName
                }
            }
            instanceMappings[uniqueName] = (resolvedFile, resolvedMachine)
            return Instance(name: uniqueName, typeFile: $0.typeFile, machine: resolvedMachine)
        }
        let machineFiles = instances.map(\.typeFile)
        try language.addLanguage(to: wrapper)
        try language.addArrangementInterface(for: instances, to: wrapper, isSuspensible: isSuspensible)
        try language.addArrangementCode(for: instances, to: wrapper, isSuspensible: isSuspensible)
        try language.addArrangementCMakeFile(for: instances, to: wrapper, isSuspensible: isSuspensible)
        try language.addArrangementMachine(instances: instances, to: wrapper, isSuspensible: isSuspensible)
        return machineFiles.map {
            $0.hasSuffix(MachineWrapper.dottedSuffix) ? $0 : ($0 + MachineWrapper.dottedSuffix)
        }
    }
    /// Read the names of machines from the given ``ArrangementWrapper``.
    ///
    /// This reads the content of the given ``ArrangementWrapper`` and interprets
    /// each line as a state name.
    ///
    /// - Parameters:
    ///   - wrapper: The machine wrapper to examine.
    ///   - machinesFilename: The name of the states file.
    /// - Throws: `NSError` if the file cannot be read.
    /// - Returns: An array of machine instances together with their machine names.
    @inlinable
    func machineInstanceNames(for wrapper: ArrangementWrapper, machinesFilename: Filename) -> [(instance: MachineName, machine: Filename)] {
        Arrangement.machineNames(from: wrapper.fileWrappers?[machinesFilename]?.stringContents ?? "")
    }
    /// Read the names of machines from the given string.
    ///
    /// This  interprets each line as a pair of instance and machine names.
    ///
    /// - Parameter content: content of the machine names file.
    /// - Returns: An array of machine names.
    @inlinable
    static func machineNames(from content: String) -> [(instance: MachineName, machine: Filename)] {
        content.lines.map(trimmed).filter(nonempty).map {
            let fields = $0.split(separator: "\t")
            return (instance: fields.first?.trimmed ?? "", machine: fields.last?.trimmed ?? "")
        }
    }
}
