//
//  CBoilerplate+Serialisation.swift
//
//  Created by Rene Hexel on 16/8/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

public extension CBoilerplate {
    /// Write the machine boilerplate to the given URL.
    /// - Parameter url: The URL to write the boilerplate to.
    /// - Throws: Any error thrown by the underlying file system.
    @inlinable
    func write(to url: URL) throws {
        let name = url.deletingPathExtension().lastPathComponent
        try url.write(content: sections[.includePath] ?? "", to: "IncludePath")
        try url.write(content: sections[.includes]    ?? "", to: "Machine_\(name)_Includes.h")
        try url.write(content: sections[.variables]   ?? "", to: "Machine_\(name)_Variables.h")
        try url.write(content: sections[.functions]   ?? "", to: "Machine_\(name)_Methods.h")
    }
    /// Write the boilerplate for a given state to the given URL.
    /// - Throws: Any error thrown by the underlying file system.
    /// - Parameters:
    ///   - state: The state to write the boilerplate for.
    ///   - url: The machine URL to write to.
    @inlinable
    func write(state: String, to url: URL) throws {
        try url.write(content: sections[.includes]    ?? "", to: "State_\(state)_Includes.h")
        try url.write(content: sections[.variables]   ?? "", to: "State_\(state)_Variables.h")
        try url.write(content: sections[.functions]   ?? "", to: "State_\(state)_Methods.h")
        try url.write(content: sections[.onEntry]     ?? "", to: "State_\(state)_OnEntry.mm")
        try url.write(content: sections[.onExit]      ?? "", to: "State_\(state)_OnExit.mm")
        try url.write(content: sections[.internal]    ?? "", to: "State_\(state)_Internal.mm")
        try url.write(content: sections[.onSuspend]   ?? "", to: "State_\(state)_OnSuspend.mm")
        try url.write(content: sections[.onResume]    ?? "", to: "State_\(state)_OnResume.mm")
    }
}

/// Return the boilerplate for a given machine.
/// - Parameter machine: The machine URL.
/// - Returns: The boilerplate for the given machine.
@inlinable
public func boilerplateofCMachine(at machine: URL) -> any Boilerplate {
    let name = machine.deletingPathExtension().lastPathComponent
    var boilerplate = CBoilerplate()
    boilerplate.sections[.includePath] = machine.stringContents(of: "IncludePath")
    boilerplate.sections[.includes]    = machine.stringContents(of: "Machine_\(name)_Includes.h")
    boilerplate.sections[.variables]   = machine.stringContents(of: "Machine_\(name)_Variables.h")
    boilerplate.sections[.functions]   = machine.stringContents(of: "Machine_\(name)_Methods.h")
    return boilerplate
}

/// Return the boilerplate for a given state.
///
/// - Parameters:
///   - machine: The machine URL.
///   - state: The name of the state to examine.
/// - Returns: The boilerplate for the given state.
@inlinable
public func boilerplateofCState(at machine: URL, state: StateName) -> any Boilerplate {
    var boilerplate = CBoilerplate()
    boilerplate.sections[.includes]  = machine.stringContents(of: "State_\(state)_Includes.h")
    boilerplate.sections[.variables] = machine.stringContents(of: "State_\(state)_Variables.h")
    boilerplate.sections[.functions] = machine.stringContents(of: "State_\(state)_Methods.h")
    boilerplate.sections[.onEntry]   = machine.stringContents(of: "State_\(state)_OnEntry.mm")
    boilerplate.sections[.onExit]    = machine.stringContents(of: "State_\(state)_OnExit.mm")
    boilerplate.sections[.internal]  = machine.stringContents(of: "State_\(state)_Internal.mm")
    boilerplate.sections[.onSuspend] = machine.stringContents(of: "State_\(state)_OnSuspend.mm")
    boilerplate.sections[.onResume]  = machine.stringContents(of: "State_\(state)_OnResume.mm")
    return boilerplate
}
