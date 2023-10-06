//
//  OutputLanguage.swift
//
//  Created by Rene Hexel on 12/8/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation
import SystemPackage

/// A language binding that can be used to generate code.
public protocol OutputLanguage: LanguageBinding {
    /// Create a file wrapper at the given URL.
    ///
    /// This is used to create the file wrapper for the
    /// given URL in preparation for writing the FSM.
    func create(at url: URL) throws -> MachineWrapper
    /// Create an arrangement at the given URL.
    ///
    /// This is used to create the file wrapper for the
    /// given URL in preparation for writing the FSM
    /// arrangement.
    ///
    /// - Parameter url: The URL to create the file wrapper at.
    func createArrangement(at url: URL) throws -> ArrangementWrapper
    /// Finalise writing.
    ///
    /// - Parameters:
    ///   - wrapper: The `MachineWrapper` to write to.
    ///   - url: The `URL` to write to.
    func finalise(_ wrapper: MachineWrapper, writingTo url: URL) throws
    /// Write the language information to the given URL
    /// - Parameter wrapper: The `MachineWrapper` to write to.
    func writeLanguage(to wrapper: MachineWrapper) throws
    /// Write the FSM layout.
    ///
    /// - Parameters:
    ///   - layout: The state and transition layout
    /// - Parameter wrapper: The `MachineWrapper` to write to.
    func write(layout: StateNameLayouts, to wrapper: MachineWrapper) throws
    /// Write the window layout.
    ///
    /// - Parameters:
    ///   - windowLayout: The window layout (ignord if `nil`)
    /// - Parameter wrapper: The `MachineWrapper` to write to.
    func write(windowLayout: Data?, to wrapper: MachineWrapper) throws
    /// Write the state name information to the given URL
    /// - Parameters:
    ///   - stateNames: The names of the states.
    ///   - wrapper: The `MachineWrapper` to write to.
    func write(stateNames: StateNames, to wrapper: MachineWrapper) throws
    /// Write the given boilerplate to the given URL
    /// - Parameters:
    ///   - boilerplate: The boilerplate to write.
    /// - Parameter wrapper: The `MachineWrapper` to write to.
    func write(boilerplate: any Boilerplate, to wrapper: MachineWrapper) throws
    /// Write the given state boilerplate to the given URL
    /// - Parameters:
    ///   - stateBoilerplate: The boilerplate to write.
    ///   - wrapper: The `MachineWrapper` to write to.
    ///   - stateName: The name of the state to write the boilerplate for.
    func write(stateBoilerplate: any Boilerplate, to wrapper: MachineWrapper, for stateName: String) throws
    /// Write the interface for the given LLFSM to the given URL.
    ///
    /// This method writes the language interface (if any)
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - wrapper: The `MachineWrapper` to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeInterface(for llfsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write the state interface for the given LLFSM to the given URL.
    ///
    /// This method writes the language interface (if any)
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - wrapper: The `MachineWrapper` to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeStateInterface(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write the arrangment interface to the given URL.
    ///
    /// This method writes the arrangement interface (if any)
    /// for the given finite-state machine instances to the given URL.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances to arrange.
    ///   - wrapper: The `ArrangementWrapper` to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeArrangementInterface(for instances: [Instance], to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write the code for the given LLFSM to the given URL.
    ///
    /// This method writes the implementation code
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - wrapper: The `MachineWrapper` to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeCode(for llfsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write the state interface for the given LLFSM to the given URL.
    ///
    /// This method writes the language interface (if any)
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - wrapper: The `MachineWrapper` to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeStateCode(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write the transition expressions for the given LLFSM to the given URL.
    ///
    /// This method writes the transition expressions
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - wrapper: The `MachineWrapper` to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeTransitionCode(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write the arrangment implementation to the given URL.
    ///
    /// This method writes the arrangement code (if any)
    /// for the given finite-state machine instances to the given URL.
    ///
    /// - Parameters:
    ///   - names: The names of the FSM instances.
    ///   - wrapper: The `ArrangementWrapper` to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeArrangementCode(for instances: [Instance], to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write a CMakefile for the given LLFSM to the given URL.
    ///
    /// This method creates a CMakefile to compile the
    /// given finite-state machine locally at the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - boilerplate: The boilerplate for the machine.
    ///   - wrapper: The `MachineWrapper` to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeCMakeFile(for fsm: LLFSM, boilerplate: any Boilerplate, to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write a CMakefile for the given LLFSM arrangement to the given URL.
    ///
    /// This method creates a CMakefile to compile the
    /// given finite-state machine locally at the given URL.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances.
    ///   - wrapper: The `ArrangementWrapper` to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func writeArrangementCMakeFile(for instances: [Instance], to wrapper: MachineWrapper, isSuspensible: Bool) throws
}

public extension OutputLanguage {
    /// Create a file wrapper for the given URL.
    ///
    /// This is used to create the file wrapper for the
    /// given URL in preparation for writing the FSM.
    ///
    /// - Parameter url: The URL to create the file wrapper at.
    @inlinable
    func create(at url: URL) throws -> MachineWrapper {
        let wrapper = MachineWrapper(directoryWithFileWrappers: [:])
        wrapper.preferredFilename = url.lastPathComponent
        return wrapper
    }
    /// Create an arrangement file wrapper for the given URL.
    ///
    /// This is used to create the file wrapper for the
    /// given URL in preparation for writing the FSM
    /// arrangement.
    ///
    /// - Parameter url: The URL to create the file wrapper at.
    @inlinable
    func createArrangement(at url: URL) throws -> ArrangementWrapper {
        try create(at: url)
    }
    /// Finalise writing.
    ///
    /// - Parameters:
    ///   - wrapper: The `MachineWrapper` to write to.
    ///   - url: The `URL` to write to.
    @inlinable
    func finalise(_ wrapper: MachineWrapper, writingTo url: URL) throws {
        try wrapper.write(to: url, options: .atomic, originalContentsURL: nil)
    }
    /// Create a `FileWrapper` with language information.
    ///
    /// The default implementation creates a `Language`
    /// file inside the file wrapper denoted by the given URL.
    /// - Parameter wrapper: The `MachineWrapper` to create the file wrapper at.
    @inlinable
    func writeLanguage(to wrapper: MachineWrapper) throws {
        guard let data = name.data(using: .utf8) else { throw POSIXError(.EINVAL) }
        let fileWrapper = FileWrapper(regularFileWithContents: data)
        fileWrapper.preferredFilename = .language
        wrapper.addFileWrapper(fileWrapper)
    }
    /// Create a `FileWrapper` with layout information.
    ///
    /// - Parameters:
    ///   - layout: The FSM layout.
    ///   - wrapper: The `MachineWrapper` to create the file wrapper at.
    @inlinable
    func write(layout: StateNameLayouts, to wrapper: MachineWrapper) throws {
        let plist = dictionary(from: layout)
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let fileWrapper = FileWrapper(regularFileWithContents: data)
        fileWrapper.preferredFilename = .layout
        wrapper.addFileWrapper(fileWrapper)
    }
    /// Create a `FileWrapper` with window layout information.
    ///
    /// - Parameters:
    ///   - windowLayout: The FSM window layout data.
    ///   - wrapper: The `MachineWrapper` to create the file wrapper at.
    @inlinable
    func write(windowLayout: Data?, to wrapper: MachineWrapper) throws {
        guard let windowLayout else { return }
        let fileWrapper = FileWrapper(regularFileWithContents: windowLayout)
        fileWrapper.preferredFilename = .windowLayout
        wrapper.addFileWrapper(fileWrapper)
    }
    /// Create a `FileWrapper` with the names of the states.
    ///
    /// This is the default implementation that creates a simple
    /// text file with the names of the states, one per line.
    ///
    /// - Parameters:
    ///   - stateNames: The names of the states.
    ///   - wrapper: The `MachineWrapper` to create the file wrapper at.
    @inlinable
    func write(stateNames: StateNames, to wrapper: MachineWrapper) throws {
        guard let data = stateNames.joined(separator: "\n").data(using: .utf8) else { throw POSIXError(.EINVAL) }
        let fileWrapper = FileWrapper(regularFileWithContents: data)
        fileWrapper.preferredFilename = .states
        wrapper.addFileWrapper(fileWrapper)
    }
    /// Default do-nothing CMakefile creator.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to write.
    ///   - wrapper: The `MachineWrapper` to create the file wrapper at.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func writeCMakeFile(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws {}
}
