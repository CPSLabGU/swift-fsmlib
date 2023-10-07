//
//  Arrangement.swift
//
//  Created by Rene Hexel on 17/08/2023.
//  Copyright © 2015, 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Arrangement of multiple FSMs.
public struct Arrangement {
    /// The FSMs in this arrangement.
    public var machines: [Machine]

    /// Designated initialiser.
    /// - Parameter machines: The machines in this arrangement.
    @inlinable
    public init(machines: [Machine]) {
        self.machines = machines
    }

    /// Write the arrangement to the given URL.
    ///
    /// This method creates a file wrapper for an arrangement
    /// of FSMs and writes it to the given URL.
    ///
    /// - Parameters:
    ///   - url: The output URL for the arrangement.
    ///   - machineNames: The names associated with the FSMs.
    ///   - format: The format of the output URL.
    ///   - isSuspensible: Whether the output FSMs should be suspensible.
    @inlinable
    public func wrapper(for url: URL, format: Format?) throws -> ArrangementWrapper {
        try wrapper(for: url, language: format.flatMap { formatToLanguageBinding[$0] })
    }

    /// Write the arrangement to the given URL.
    ///
    /// This method creates a file wrapper for an arrangement
    /// of FSMs and writes it to the given URL.
    ///
    /// - Parameters:
    ///   - url: The output URL for the arrangement.
    ///   - machineNames: The names associated with the FSMs.
    ///   - language: The language to use (defaults to the original language of the first machine).
    ///   - isSuspensible: Whether the output FSMs should be suspensible.
    @inlinable
    public func wrapper(for url: URL, language: LanguageBinding? = nil) throws -> ArrangementWrapper {
        guard let destination = (language ?? machines.first?.language) as? OutputLanguage else {
            throw FSMError.unsupportedOutputFormat
        }
        let wrapper = try destination.createArrangement(at: url)
        return wrapper
    }

    /// Add the arrangement to the given `ArrangementWrapper`.
    ///
    /// This method creates a file wrapper for an arrangement
    /// of FSMs and writes it to the given `ArrangementWrapper`.
    ///
    /// - Parameters:
    ///   - wrapper: The output `ArrangementWrapper` to add to.
    ///   - format: The arrangement format to use (defaults to the original language of the first machine).
    ///   - machineNames: The names associated with the FSMs.
    ///   - isSuspensible: Whether the output FSMs should be suspensible.
    /// - Returns: The filenames of the machines for adding to the arrangement.
    @inlinable
    public func add(to wrapper: ArrangementWrapper, in format: Format?, machineNames: [String], isSuspensible: Bool = true) throws -> [Filename] {
        try addArrangement(for: format.flatMap {
            formatToLanguageBinding[$0]
        }, to: wrapper, machineNames: machineNames, isSuspensible: isSuspensible)
    }

    /// Add the arrangement to the given `ArrangementWrapper`.
    ///
    /// This method creates a file wrapper for an arrangement
    /// of FSMs and writes it to the given `ArrangementWrapper`.
    ///
    /// - Parameters:
    ///   - language: The language to use (defaults to the original language of the first machine).
    ///   - wrapper: The output `ArrangementWrapper` to add to.
    ///   - machineNames: The names associated with the FSMs.
    ///   - isSuspensible: Whether the output FSMs should be suspensible.
    /// - Returns: The filenames of the machines for adding to the arrangement.
    @inlinable
    public func addArrangement(for language: LanguageBinding? = nil, to wrapper: ArrangementWrapper, machineNames: [String], isSuspensible: Bool = true) throws -> [Filename] {
        guard let destination = (language ?? machines.first?.language) as? OutputLanguage else {
            throw FSMError.unsupportedOutputFormat
        }
        return try addArrangement(outputFormat: destination, to: wrapper, machineNames: machineNames)
    }

    /// Add the arrangement to the given `ArrangementWrapper`.
    ///
    /// This method creates a file wrapper for an arrangement
    /// of FSMs and writes it to the given `ArrangementWrapper`.
    ///
    /// - Parameters:
    ///   - outputFormat: The output language format to use.
    ///   - wrapper: The output `ArrangementWrapper` to add to.
    ///   - machineNames: The names associated with the FSMs.
    ///   - isSuspensible: Whether the output FSMs should be suspensible.
    /// - Returns: The filenames of the machines for adding to the arrangement.
    @inlinable
    public func addArrangement(outputFormat: OutputLanguage, to wrapper: ArrangementWrapper, machineNames: [String], isSuspensible: Bool = true) throws -> [Filename] {
        var fsmMappings = [ String : (String, Machine) ]()
        let instances = zip(machines, machineNames).map {
            let machine = $0.0
            let name = $0.1
            var j = 1
            var uniqueName = name
            var resolvedName = name
            var resolvedMachine = machine
            while let (existingName, existingMachine) = fsmMappings[uniqueName] {
                defer { j += 1 }
                uniqueName = "\(name)_\(j)"
                if name == existingName { // avoid duplication
                    resolvedMachine = existingMachine
                    resolvedName = existingName
                }
            }
            fsmMappings[uniqueName] = (resolvedName, resolvedMachine)
            return Instance(fileName: uniqueName, typeFile: resolvedName, fsm: resolvedMachine.llfsm)
        }
        let machineFiles = instances.map(\.typeFile)
        try outputFormat.addLanguage(to: wrapper)
        try outputFormat.addArrangementInterface(for: instances, to: wrapper, isSuspensible: isSuspensible)
        try outputFormat.addArrangementCode(for: instances, to: wrapper, isSuspensible: isSuspensible)
        try outputFormat.addArrangementCMakeFile(for: instances, to: wrapper, isSuspensible: isSuspensible)
        return machineFiles.map {
            $0.hasSuffix(".machine") ? $0 : ($0 + ".machine")
        }
    }
}

