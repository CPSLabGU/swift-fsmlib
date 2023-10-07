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
    public func add(to wrapper: ArrangementWrapper, language: OutputLanguage, machineNames: [String], isSuspensible: Bool = true) throws -> [Filename] {
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
        try language.addLanguage(to: wrapper)
        try language.addArrangementInterface(for: instances, to: wrapper, isSuspensible: isSuspensible)
        try language.addArrangementCode(for: instances, to: wrapper, isSuspensible: isSuspensible)
        try language.addArrangementCMakeFile(for: instances, to: wrapper, isSuspensible: isSuspensible)
        return machineFiles.map {
            $0.hasSuffix(".machine") ? $0 : ($0 + ".machine")
        }
    }
}

