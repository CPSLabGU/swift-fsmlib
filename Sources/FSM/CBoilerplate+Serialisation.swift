//
//  CBoilerplate+Serialisation.swift
//
//  Created by Rene Hexel on 16/8/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

public extension CBoilerplate {
    /// Write the boilerplate to the given URL.
    /// - Parameter url: The URL to write the boilerplate to.
    /// - Throws: Any error thrown by the underlying file system.
    @inlinable
    func write(to url: URL) throws {
        let name = url.deletingPathExtension().lastPathComponent
        try url.write(content: sections[.includePath] ?? "", to: "IncludePath")
        try url.write(content: sections[.includes] ?? "", to: "\(name)_Includes.h")
        try url.write(content: sections[.variables] ?? "", to: "\(name)_Variables.h")
        try url.write(content: sections[.functions] ?? "", to: "\(name)_Methods.h")
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
    boilerplate.sections[.includes]    = machine.stringContents(of: "\(name)_Includes.h")
    boilerplate.sections[.variables]   = machine.stringContents(of: "\(name)_Variables.h")
    boilerplate.sections[.functions]   = machine.stringContents(of: "\(name)_Methods.h")
    return boilerplate
}

/// Write the boilerplate to a given machine URL.
/// - Parameter machine: The machine URL.
/// - Throws: Any error thrown by the underlying file system.
@inlinable
public func writeBoilerplateofCMachine(to machine: URL) throws {
}

/// Return the boilerplate for a given state.
///
/// - Parameters:
///   - machine: The machine URL.
///   - state: The name of the state to examine.
/// - Returns: The boilerplate for the given state.
@inlinable
public func boilerplateofCState(at machine: URL, state: StateName) -> any Boilerplate {
    let name = machine.deletingPathExtension().lastPathComponent
    var boilerplate = CBoilerplate()
    boilerplate.sections[.includes]  = machine.stringContents(of: "State_\(name)_Includes.h")
    boilerplate.sections[.variables] = machine.stringContents(of: "State_\(name)_Variables.h")
    boilerplate.sections[.functions] = machine.stringContents(of: "State_\(name)_Methods.h")
    return boilerplate
}
