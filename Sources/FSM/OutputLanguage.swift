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
    func createWrapper(at url: URL) throws -> MachineWrapper
    /// Create an arrangement at the given URL.
    ///
    /// This is used to create the file wrapper for the
    /// given URL in preparation for writing the FSM
    /// arrangement.
    ///
    /// - Parameter url: The URL to create the file wrapper at.
    func createArrangementWrapper(at url: URL) throws -> ArrangementWrapper
    /// Write the language information to the given URL
    /// - Parameter wrapper: The `FileWrapper` to add to.
    func addLanguage(to wrapper: FileWrapper) throws
    /// Write the FSM layout.
    ///
    /// - Parameters:
    ///   - layout: The state and transition layout
    ///   - wrapper: The `MachineWrapper` to add to.
    func add(layout: StateNameLayouts, to wrapper: MachineWrapper) throws
    /// Write the window layout.
    ///
    /// - Parameters:
    ///   - windowLayout: The window layout (ignord if `nil`)
    /// - Parameter wrapper: The `MachineWrapper` to add to.
    func add(windowLayout: Data?, to wrapper: MachineWrapper) throws
    /// Write the state name information to the given URL
    /// - Parameters:
    ///   - stateNames: The names of the states.
    ///   - wrapper: The `MachineWrapper` to add to.
    func add(stateNames: StateNames, to wrapper: MachineWrapper) throws
    /// Write the given boilerplate to the given URL
    /// - Parameters:
    ///   - boilerplate: The boilerplate to add.
    /// - Parameter wrapper: The `MachineWrapper` to add to.
    func add(boilerplate: any Boilerplate, to wrapper: MachineWrapper) throws
    /// Write the given state boilerplate to the given URL
    /// - Parameters:
    ///   - stateBoilerplate: The boilerplate to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - stateName: The name of the state to add the boilerplate for.
    func add(stateBoilerplate: any Boilerplate, to wrapper: MachineWrapper, for stateName: String) throws
    /// Write the interface for the given LLFSM to the given URL.
    ///
    /// This method adds the language interface (if any)
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addInterface(for llfsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write the state interface for the given LLFSM to the given URL.
    ///
    /// This method adds the language interface (if any)
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addStateInterface(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write the arrangment interface to the given URL.
    ///
    /// This method adds the arrangement interface (if any)
    /// for the given finite-state machine instances to the given URL.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances to arrange.
    ///   - wrapper: The `ArrangementWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addArrangementInterface(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws
    /// Write the code for the given LLFSM to the given URL.
    ///
    /// This method adds the implementation code
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addCode(for llfsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write the state interface for the given LLFSM to the given URL.
    ///
    /// This method adds the language interface (if any)
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addStateCode(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write the transition expressions for the given LLFSM to the given URL.
    ///
    /// This method adds the transition expressions
    /// for the given finite-state machine to the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addTransitionCode(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write the arrangment implementation to the given URL.
    ///
    /// This method adds the arrangement code (if any)
    /// for the given finite-state machine instances to the given URL.
    ///
    /// - Parameters:
    ///   - names: The names of the FSM instances.
    ///   - wrapper: The `ArrangementWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addArrangementCode(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws
    /// Write a CMakefile for the given LLFSM to the given URL.
    ///
    /// This method creates a CMakefile to compile the
    /// given finite-state machine locally at the given URL.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - boilerplate: The boilerplate for the machine.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addCMakeFile(for fsm: LLFSM, boilerplate: any Boilerplate, to wrapper: MachineWrapper, isSuspensible: Bool) throws
    /// Write a CMakefile for the given LLFSM arrangement to the given URL.
    ///
    /// This method creates a CMakefile to compile the
    /// given finite-state machine locally at the given URL.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances.
    ///   - wrapper: The `ArrangementWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addArrangementCMakeFile(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws
    /// Write a `Machines` file containing the names of the FSM instances.
    ///
    /// This method creates a file containing the names of the
    /// FSM instances used by the arrangement in the order
    /// in which they are arranged
    func addArrangementMachine(instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws
}

public extension OutputLanguage {
    /// Create a file wrapper for the given URL.
    ///
    /// This is used to create the file wrapper for the
    /// given URL in preparation for writing the FSM.
    ///
    /// - Parameter url: The URL to create the file wrapper at.
    @inlinable
    func createWrapper(at url: URL) throws -> MachineWrapper {
        let wrapper = MachineWrapper(directoryWithFileWrappers: [:], for: Machine())
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
    func createArrangementWrapper(at url: URL) throws -> ArrangementWrapper {
        let wrapper = ArrangementWrapper(directoryWithFileWrappers: [:], for: Arrangement(namedInstances: []))
        wrapper.preferredFilename = url.lastPathComponent
        return wrapper
    }
    /// Create a `FileWrapper` with language information.
    ///
    /// The default implementation creates a `Language`
    /// file inside the file wrapper denoted by the given URL.
    /// - Parameter wrapper: The `MachineWrapper` to create the file wrapper at.
    @inlinable
    func addLanguage(to wrapper: FileWrapper) throws {
        guard let data = name.data(using: .utf8) else { throw POSIXError(.EINVAL) }
        let fileWrapper = FileWrapper(regularFileWithContents: data)
        fileWrapper.preferredFilename = .language
        wrapper.replaceFileWrapper(fileWrapper)
    }
    /// Create a `FileWrapper` with layout information.
    ///
    /// - Parameters:
    ///   - layout: The FSM layout.
    ///   - wrapper: The `MachineWrapper` to create the file wrapper at.
    @inlinable
    func add(layout: StateNameLayouts, to wrapper: MachineWrapper) throws {
        let plist = dictionary(from: layout)
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        let fileWrapper = FileWrapper(regularFileWithContents: data)
        fileWrapper.preferredFilename = .layout
        wrapper.replaceFileWrapper(fileWrapper)
    }
    /// Create a `FileWrapper` with window layout information.
    ///
    /// - Parameters:
    ///   - windowLayout: The FSM window layout data.
    ///   - wrapper: The `MachineWrapper` to create the file wrapper at.
    @inlinable
    func add(windowLayout: Data?, to wrapper: MachineWrapper) throws {
        guard let windowLayout else { return }
        let fileWrapper = FileWrapper(regularFileWithContents: windowLayout)
        fileWrapper.preferredFilename = .windowLayout
        wrapper.replaceFileWrapper(fileWrapper)
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
    func add(stateNames: StateNames, to wrapper: MachineWrapper) throws {
        guard let data = stateNames.joined(separator: "\n").data(using: .utf8) else { throw POSIXError(.EINVAL) }
        let fileWrapper = FileWrapper(regularFileWithContents: data)
        fileWrapper.preferredFilename = .states
        wrapper.replaceFileWrapper(fileWrapper)
    }
    /// Default do-nothing CMakefile creator.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - wrapper: The `MachineWrapper` to create the file wrapper at.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addCMakeFile(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws {}
    /// Default `Machines` file creator.
    /// 
    /// This method creates a file containing the names of the
    /// FSM instances used by the arrangement in the order
    /// in which they are arranged.  Each line contains the
    /// name of an instance.
    ///
    /// - Parameters:
    ///   - instances: The arranged machine instances.
    ///   - wrapper: The arrangement wrapper to write to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addArrangementMachine(instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        guard let data = instances.map(\.name).joined(separator: "\n").data(using: .utf8) else { throw POSIXError(.EINVAL) }
        let fileWrapper = FileWrapper(regularFileWithContents: data)
        fileWrapper.preferredFilename = .machines
        wrapper.replaceFileWrapper(fileWrapper)
    }
}
