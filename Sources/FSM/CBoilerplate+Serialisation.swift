//
//  CBoilerplate+Serialisation.swift
//
//  Created by Rene Hexel on 16/8/2023.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Extension providing methods for serialising and deserialising CBoilerplate
/// objects to and from MachineWrapper instances. These methods facilitate
/// the management of boilerplate code sections for C-based finite-state
/// machines, supporting both machine-level and state-level boilerplate.
public extension CBoilerplate {
    /// Add the machine boilerplate to the given `MachineWrapper`.
    ///
    /// This method adds all relevant boilerplate sections for the machine
    /// to the specified wrapper, replacing any existing file wrappers
    /// for those sections.
    /// The boilerplate is used to provide necessary includes, variables,
    /// and functions for the generated C code.
    ///
    /// - Parameter wrapper: The `MachineWrapper` to add the boilerplate to.
    /// - Throws: Any error thrown by the underlying file system.
    @inlinable
    func add(to wrapper: MachineWrapper) {
        for (section, fileName) in cBoilerplateFileMappings(for: wrapper.name) {
            let fileWrapper = fileWrapper(named: fileName, from: sections[section])
            wrapper.replaceFileWrapper(fileWrapper)
        }
    }
    /// Write the boilerplate for a given state to the given URL.
    ///
    /// This method adds all relevant boilerplate sections
    /// for the specified state to the given wrapper,
    /// replacing any existing file wrappers for those sections.
    /// The boilerplate is used to provide necessary includes,
    /// variables, and functions for the generated C code for the state.
    ///
    /// - Parameters:
    ///   - state: The state to write the boilerplate for.
    ///   - wrapper: The `MachineWrapper` to add the state to.
    /// - Throws: Any error thrown by the underlying file system.
    @inlinable
    func add(state: String, to wrapper: MachineWrapper) {
        for (section, fileName) in cStateBoilerplateFileMappings(for: state) {
            let fileWrapper = fileWrapper(named: fileName, from: sections[section])
            wrapper.replaceFileWrapper(fileWrapper)
        }
    }
}

/// Return the boilerplate for a given machine.
/// - Parameter machine: The machine URL.
/// - Returns: The boilerplate for the given machine.
@inlinable
public func boilerplateOfCMachine(at machineWrapper: MachineWrapper) -> any Boilerplate {
    var boilerplate = CBoilerplate()
    for (section, fileName) in cBoilerplateFileMappings(for: machineWrapper.name) {
        boilerplate.sections[section] = machineWrapper.stringContents(of: fileName)
    }
    return boilerplate
}

/// Return the boilerplate for a given state.
///
/// - Parameters:
///   - machine: The machine URL.
///   - state: The name of the state to examine.
/// - Returns: The boilerplate for the given state.
@inlinable
public func boilerplateofCState(_ state: StateName, of machineWrapper: MachineWrapper) -> any Boilerplate {
    var boilerplate = CBoilerplate()
    for (section, fileName) in cStateBoilerplateFileMappings(for: state) {
        boilerplate.sections[section] = machineWrapper.stringContents(of: fileName)
    }
    return boilerplate
}

/// Return the mappings of machine boilerplate sections to filenames.
///
/// This function returns the file names relative to the machine URL
/// for the sections of the given machine.
///
/// - Parameter name: The name of the machine the boilerplate belongs to.
/// - Returns: The mappings from section to filename.
@usableFromInline
func cBoilerplateFileMappings(for machineName: String) -> [CBoilerplate.BoilerplateFileMapping] {
    [
        (.includePath, Filename.includePath),
        (.includes,  "Machine_\(machineName)_Includes.h"),
        (.variables, "Machine_\(machineName)_Variables.h"),
        (.functions, "Machine_\(machineName)_Methods.h")
    ]
}

/// Return the mappings of state boilerplate sections to filenames.
///
/// This function returns the file names relative to the machine URL
/// for the sections of the given state.
///
/// - Parameter state: The name of the state the boilerplate belongs to.
/// - Returns: The mappings from section to filename.
@usableFromInline
func cStateBoilerplateFileMappings(for state: String) -> [CBoilerplate.BoilerplateFileMapping] {
    [
        (.includes,  "State_\(state)_Includes.h"),
        (.variables, "State_\(state)_Variables.h"),
        (.functions, "State_\(state)_Methods.h"),
        (.onEntry,   "State_\(state)_OnEntry.mm"),
        (.onExit,    "State_\(state)_OnExit.mm"),
        (.internal,  "State_\(state)_Internal.mm"),
        (.onSuspend, "State_\(state)_OnSuspend.mm"),
        (.onResume,  "State_\(state)_OnResume.mm")
    ]
}
