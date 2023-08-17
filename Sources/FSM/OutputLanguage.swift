//
//  OutputLanguage.swift
//
//  Created by Rene Hexel on 12/8/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// A language binding that can be used to generate code.
public protocol OutputLanguage: LanguageBinding {
    /// Create a file wrapper at the given URL.
    ///
    /// This is used to create the file wrapper for the
    /// given URL in preparation for writing the FSM.
    func create(at url: URL) throws
    /// Create an arrangement at the given URL.
    ///
    /// This is used to create the file wrapper for the
    /// given URL in preparation for writing the FSM
    /// arrangement.
    ///
    /// - Parameter url: The URL to create the file wrapper at.
    func createArrangement(at url: URL) throws
    /// Finalise writing.
    ///
    /// - Parameter url: The URL to finalise creating the file wrapper at.
    func finalise(_ url: URL) throws
    /// Write the language information to the given URL
    /// - Parameter url: The URL to write to.
    func writeLanguage(to url: URL) throws
    /// Write the window layout.
    ///
    /// - Parameters:
    ///   - windowLayout: The window layout (ignord if `nil`)
    ///   - url: The machine URL to write to.
    func write(windowLayout: Data?, to url: URL) throws
    /// Write the state name information to the given URL
    /// - Parameters:
    ///   - stateNames: The names of the states.
    ///   - url: The machine URL to write to.
    func write(stateNames: StateNames, to url: URL) throws
    /// Write the given boilerplate to the given URL
    /// - Parameters:
    ///   - boilerplate: The boilerplate to write.
    ///   - url: The machine URL to write to.
    func write(boilerplate: any Boilerplate, to url: URL) throws
    /// Write the given state boilerplate to the given URL
    /// - Parameters:
    ///   - stateBoilerplate: The boilerplate to write.
    ///   - url: The machine URL to write to.
    ///   - stateName: The name of the state to write the boilerplate for.
    func write(stateBoilerplate: any Boilerplate, to url: URL, for stateName: String) throws
    /// Write the interface for the given LLFSM to the given URL.
    ///
    /// This method writes the language interface (if any)
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeInterface(for llfsm: LLFSM, to url: URL, isSuspensible: Bool) throws
    /// Write the state interface for the given LLFSM to the given URL.
    ///
    /// This method writes the language interface (if any)
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeStateInterface(for fsm: LLFSM, to url: URL, isSuspensible: Bool) throws
    /// Write the code for the given LLFSM to the given URL.
    ///
    /// This method writes the implementation code
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeCode(for llfsm: LLFSM, to url: URL, isSuspensible: Bool) throws
    /// Write the state interface for the given LLFSM to the given URL.
    ///
    /// This method writes the language interface (if any)
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeStateCode(for fsm: LLFSM, to url: URL, isSuspensible: Bool) throws
    /// Write the transition expressions for the given LLFSM to the given URL.
    ///
    /// This method writes the transition expressions
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeTransitionCode(for fsm: LLFSM, to url: URL, isSuspensible: Bool) throws
    /// Write a CMakefile for the given LLFSM to the given URL.
    ///
    /// This method creates a CMakefile to compile the
    /// given finite-state machine locally at the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeCMakeFile(for fsm: LLFSM, to url: URL, isSuspensible: Bool) throws
}

public extension OutputLanguage {
    /// Create a file wrapper for the given URL.
    ///
    /// This is used to create the file wrapper for the
    /// given URL in preparation for writing the FSM.
    ///
    /// - Parameter url: The URL to create the file wrapper at.
    @inlinable
    func create(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
    /// Create an arrangement file wrapper for the given URL.
    ///
    /// This is used to create the file wrapper for the
    /// given URL in preparation for writing the FSM
    /// arrangement.
    ///
    /// - Parameter url: The URL to create the file wrapper at.
    @inlinable
    func createArrangement(at url: URL) throws {
        try create(at: url)
    }
    /// Finalise writing.
    ///
    /// - Parameter url: The URL to finalise creating the file wrapper at.
    @inlinable
    func finalise(_ url: URL) throws {}
    /// Write the language information to the given URL.
    ///
    /// The default implementation creates a `Language`
    /// file inside the file wrapper denoted by the given URL.
    @inlinable
    func writeLanguage(to url: URL) throws {
        try url.write(content: name, to: .language)
    }
    /// Write the window layout to the given URL.
    ///
    /// - Parameters:
    ///   - windowLayout: The FSM window layout data.
    ///   - url: The URL to write to.
    @inlinable
    func write(windowLayout: Data?, to url: URL) throws {
        try windowLayout.map { try url.write($0, to: .windowLayout) }
    }
    /// Write the state name information to the given URL
    /// - Parameters:
    ///   - stateNames: The names of the states.
    ///   - url: The machine URL to write to.
    @inlinable
    func write(stateNames: StateNames, to url: URL) throws {
        try url.write(content: stateNames.joined(separator: "\n"), to: .states)
    }
    /// Default do-nothing CMakefile creator.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - url: The URL to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func writeCMakeFile(for fsm: LLFSM, to url: URL, isSuspensible: Bool) throws {}
}
