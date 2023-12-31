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
    public func add(to wrapper: ArrangementWrapper, language: any OutputLanguage, machineNames: [String], isSuspensible: Bool = true) throws -> [Filename] {
        var instanceMappings = [ String : (String, Machine) ]()
        let instances = zip(machines, machineNames).map {
            let machine = $0.0
            let fileName = $0.1
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
            return Instance(name: uniqueName, typeFile: resolvedFile, fsm: resolvedMachine.llfsm)
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

