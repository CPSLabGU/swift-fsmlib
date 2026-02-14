//
//  ObjCPPBinding.swift
//
//  Created by Rene Hexel on 19/10/2016.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
// swiftlint:disable:this type_contents_order
import Foundation

/// Objective-C++ language binding
public struct ObjCPPBinding: OutputLanguage {
    /// The canonical name of the Objective-C++ binding.
    public let name = Format.objCX.rawValue

    /// Designated initialiser.
    @inlinable
    public init() {}

    /// Objective-C++ binding from URL and state name to number of transitions.
    ///
    /// - Parameters:
    ///   - machineWrapper: The MachineWrapper to examine.
    ///   - stateName: The name of the state to examine.
    /// - Returns: The number of transitions in the given state.
    @inlinable
    public func numberOfTransitions(for machineWrapper: MachineWrapper, stateName: StateName) -> Int {
        numberOfObjCPPTransitions(for: machineWrapper, state: stateName)
    }

    /// Objective-C++ binding from URL, state name, and transition to expression.
    ///
    /// - Parameters:
    ///   - transitionNumber: The transition number to examine.
    ///   - machineWrapper: The MachineWrapper to examine.
    ///   - stateName: The name of the state to examine.
    /// - Returns: The expression of the given transition.
    @inlinable
    public func expression(of transitionNumber: Int, for machineWrapper: MachineWrapper, stateName: StateName) -> String {
        expressionOfObjCPPTransition(transitionNumber, state: stateName, for: machineWrapper)
    }

    /// Objective-C++ binding from URL, states, source state name, and transition to target state ID.
    ///
    /// - Parameters:
    ///   - transitionNumber: The transition number to examine.
    ///   - machineWrapper: The MachineWrapper to examine.
    ///   - stateName: The name of the state to examine.
    ///   - states: The states of the machine.
    /// - Returns: The target state ID of the given transition.
    @inlinable
    public func target(of transitionNumber: Int, for machineWrapper: MachineWrapper, stateName: StateName, with states: [State]) -> StateID? {
        targetOfObjCPPTransition(transitionNumber, state: stateName, for: machineWrapper, with: states)
    }

    /// Objective-C++ binding from URL, states to suspend state ID.
    ///
    /// - Parameters:
    ///   - machineWrapper: The MachineWrapper to examine.
    ///   - states: The states of the machine.
    /// - Returns: The suspend state ID of the given machine.
    @inlinable
    public func suspendState(for machineWrapper: MachineWrapper, states: [State]) -> StateID? {
        suspendStateOfObjCPPMachine(machineWrapper, states: states)
    }

    /// Objective-C++ binding from URL to machine boilerplate.
    ///
    /// - Parameter machineWrapper: The MachineWrapper to examine.
    /// - Returns: The boilerplate for the given machine.
    @inlinable
    public func boilerplate(for machineWrapper: MachineWrapper) -> any Boilerplate {
        boilerplateofObjCPPMachine(for: machineWrapper)
    }

    /// Objective-C++ binding from URL and state name to state boilerplate.
    ///
    /// - Parameters:
    ///   - machineWrapper: The MachineWrapper to examine.
    ///   - stateName: The name of the state to examine.
    /// - Returns: The boilerplate for the given state.
    @inlinable
    public func stateBoilerplate(for machineWrapper: MachineWrapper, stateName: StateName) -> any Boilerplate {
        boilerplateofObjCPPState(stateName, of: machineWrapper)
    }

    /// Objective-C++ binding from URL and state name to number of transitions.
    ///
    /// This URL-based closure provides backward compatibility for reading
    /// transition counts directly from a machine directory URL. Given a
    /// machine URL and a state name, it returns the number of transitions
    /// associated with that state by inspecting the corresponding transition
    /// files on disk.
    public let numberOfTransitions: (URL, StateName) -> Int = { url, s in
        numberOfObjCPPTransitionsFor(machine: url, state: s)
    }
    /// Objective-C++ binding from URL, state name, and transition to expression.
    ///
    /// This URL-based curried closure returns the transition expression for a
    /// given state and transition number. The first invocation takes a machine
    /// URL and state name, returning a second closure that accepts a transition
    /// index and produces the corresponding Boolean expression string read
    /// from the transition file on disk.
    public let expressionOfTransition: (URL, StateName) -> (Int) -> String = { url, s in { number in
        expressionOfObjCPPTransitionFor(machine: url, state: s, transition: number)
    }
    }
    /// Objective-C++ binding from URL, states, source state name, and transition to target state ID.
    ///
    /// This URL-based curried closure resolves the target state ID for a given
    /// transition. The first invocation accepts a machine URL, the array of
    /// known states, and a source state name, returning a second closure that
    /// takes a transition index and produces the optional `StateID` of the
    /// target state. The target is determined by reading the transition target
    /// file from disk and matching the name against the provided states.
    public let targetOfTransition: (URL, [State], StateName) -> (Int) -> StateID? = { url, ss, s in
        { number in
            targetOfObjCPPTransitionFor(machine: url, states: ss, state: s, transition: number)
        }
    }
    /// Objective-C++ binding from URL, states to suspend state ID.
    ///
    /// This URL-based closure resolves the suspend state ID from a machine
    /// directory. Given a machine URL and the array of known states, it reads
    /// the suspend state name from the machine directory and returns the
    /// corresponding `StateID`, or `nil` if no suspend state is defined or
    /// the name does not match any known state.
    public let suspendState: (URL, [State]) -> StateID? = { url, ss in
        suspendStateOfObjCPPMachine(url, states: ss)
    }

    /// Objective-C++ binding from URL to machine boilerplate.
    ///
    /// This URL-based closure reads the boilerplate code from a machine
    /// directory URL. It inspects the standard Objective-C++ boilerplate
    /// files (such as includes, variables, and function sections) within
    /// the machine directory and returns them as a consolidated
    /// `Boilerplate` instance.
    public let boilerplate: (URL) -> any Boilerplate = { url in
        boilerplateofObjCPPMachine(at: url)
    }

    /// Objective-C++ binding from URL and state name to state boilerplate.
    ///
    /// This URL-based closure reads the state-level boilerplate from a
    /// machine directory for a given state name. It locates and parses
    /// the Objective-C++ state boilerplate files (such as state-specific
    /// includes, variables, and method sections) and returns them as a
    /// consolidated `Boilerplate` instance.
    public var stateBoilerplate: (URL, StateName) -> any Boilerplate = { url, stateName in
        boilerplateofObjCPPState(at: url, state: stateName)
    }
}

/// Extension providing methods for adding Objective-C++ boilerplate,
/// interfaces, code, and CMake files to wrappers for Objective-C++-based
/// finite-state machines and arrangements.
///
/// These methods facilitate the serialisation, code generation, and build
/// system integration for Objective-C++ language targets, including support
/// for suspensible machines and arrangements.
///
/// - Note: This extension is intended for use with Objective-C++ bindings and
///         is not applicable to pure C or Swift FSMs.
public extension ObjCPPBinding {
    /// Add the given boilerplate to the given `MachineWrapper`.
    ///
    /// This function tries to convert the given boilerplate
    /// to an Objective-C++ boilerplate and then adds it
    /// to the given `MachineWrapper`.
    ///
    /// - Parameters:
    ///   - boilerplate: The boilerplate to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    @inlinable
    func add(boilerplate: any Boilerplate, to wrapper: MachineWrapper) throws {
        CBoilerplate(boilerplate).add(to: wrapper)
        // Add ObjC++ specific files (VarRefs.mm and FuncRefs.mm)
        addObjCPPMachineBoilerplate(boilerplate, to: wrapper)
    }
    /// Write the given state boilerplate to the given URL
    /// - Parameters:
    ///   - stateBoilerplate: The boilerplate to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - stateName: The name of the state to add the boilerplate for.
    func add(stateBoilerplate: any Boilerplate, to wrapper: MachineWrapper, for stateName: String) throws {
        CBoilerplate(stateBoilerplate).add(state: stateName, to: wrapper)
        // Add ObjC++ specific files (VarRefs.mm and FuncRefs.mm)
        addObjCPPStateBoilerplate(stateBoilerplate, to: wrapper, for: stateName)
    }
    /// Add the interface for the given LLFSM to the given `MachineWrapper`.
    ///
    /// This method adds the language interface (if any)
    /// for the given finite-state machine to the given `MachineWrapper`.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addInterface(for llfsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        let header = objcppMachineHeader(for: llfsm, named: name)
        let fileWrapper = fileWrapper(named: "\(name).h", from: header)
        wrapper.replaceFileWrapper(fileWrapper)
    }
    /// Add the state interface for the given LLFSM to the given `MachineWrapper`.
    ///
    /// This method adds the language interface (if any)
    /// for the given finite-state machine to the given `MachineWrapper`.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addStateInterface(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        for stateID in fsm.states {
            guard let state = fsm.stateMap[stateID] else {
                fputs("Warning: orphaned state ID \(stateID) for \(name)\n", stderr)
                continue
            }
            let header = objcppStateHeader(for: state, llfsm: fsm, named: name)
            let fileWrapper = fileWrapper(named: "State_\(state.name).h", from: header)
            wrapper.replaceFileWrapper(fileWrapper)
        }
    }
    /// Add the code for the given LLFSM to the given `MachineWrapper`.
    ///
    /// This method adds the implementation code
    /// for the given finite-state machine to the given `MachineWrapper`.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addCode(for llfsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        let impl = objcppMachineImplementation(for: llfsm, named: name)
        let fileWrapper = fileWrapper(named: "\(name).mm", from: impl)
        wrapper.replaceFileWrapper(fileWrapper)
    }
    /// Add the state code for the given LLFSM to the given `MachineWrapper`.
    ///
    /// This method adds the language interface (if any)
    /// for the given finite-state machine to the given `MachineWrapper`.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addStateCode(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        for stateID in fsm.states {
            guard let state = fsm.stateMap[stateID] else {
                fputs("Warning: orphaned state ID \(stateID) for \(name)\n", stderr)
                continue
            }
            let impl = objcppStateImplementation(for: state, llfsm: fsm, named: name)
            let fileWrapper = fileWrapper(named: "State_\(state.name).mm", from: impl)
            wrapper.replaceFileWrapper(fileWrapper)
        }
    }
    /// Add the transition expressions for the given LLFSM to the given `MachineWrapper`.
    ///
    /// This method adds the transition expressions
    /// for the given finite-state machine to the given `MachineWrapper`.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addTransitionCode(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        for (i, stateID) in fsm.states.enumerated() {
            guard let state = fsm.stateMap[stateID] else {
                fputs("Warning: orphaned state \(i) ID \(stateID) for \(name)\n", stderr)
                continue
            }
            let transitions = fsm.transitionsFrom(stateID)
            for (j, transitionID) in transitions.enumerated() {
                guard let transition = fsm.transitionMap[transitionID] else { continue }
                let expr = transition.label.hasSuffix("\n") ? transition.label : transition.label + "\n"
                let fileWrapper = fileWrapper(named: "State_\(state.name)_Transition_\(j).expr", from: expr)
                wrapper.replaceFileWrapper(fileWrapper)
            }
        }
    }
    /// Add the arrangement interface for the given instances to the given `ArrangementWrapper`.
    ///
    /// This method adds the arrangement interface (if any)
    /// for the given finite-state machine instances to the given `ArrangementWrapper`.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances to arrange.
    ///   - wrapper: The `ArrangementWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addArrangementInterface(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        let header = objcppArrangementHeader(for: instances, named: name, isSuspensible: isSuspensible)
        let fileWrapper = fileWrapper(named: "Arrangement_\(name).h", from: header)
        wrapper.replaceFileWrapper(fileWrapper)
    }
    /// Add the arrangement code for the given instances to the given `ArrangementWrapper`.
    ///
    /// This method adds the arrangement code (if any)
    /// for the given finite-state machine instances to the given `ArrangementWrapper`.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances to arrange.
    ///   - wrapper: The `ArrangementWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addArrangementCode(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        let impl = objcppArrangementImplementation(for: instances, named: name, isSuspensible: isSuspensible)
        let fileWrapper = fileWrapper(named: "Arrangement_\(name).mm", from: impl)
        wrapper.replaceFileWrapper(fileWrapper)
    }
    /// Add a CMakefile for the given LLFSM to the given `MachineWrapper`.
    ///
    /// This method creates a CMakefile to compile the
    /// given finite-state machine locally and adds it
    /// to the given `MachineWrapper`.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - boilerplate: The boilerplate containing the include paths.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addCMakeFile(for fsm: LLFSM, boilerplate: any Boilerplate, to wrapper: MachineWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        let cmakeFragment = objcppCMakeFragment(for: fsm, named: name, isSuspensible: isSuspensible)
        let fragmentWrapper = fileWrapper(named: "project.cmake", from: cmakeFragment)
        wrapper.replaceFileWrapper(fragmentWrapper)
        let cmakeLists = objcppCMakeLists(for: fsm, named: name, boilerplate: boilerplate, isSuspensible: isSuspensible)
        let cmakeWrapper = fileWrapper(named: "CMakeLists.txt", from: cmakeLists)
        wrapper.replaceFileWrapper(cmakeWrapper)
    }
    /// Add a CMakefile for the given LLFSM arrangement to the given `ArrangementWrapper`.
    ///
    /// This method creates a CMakefile to compile the
    /// given finite-state machine arrangement locally and adds it
    /// to the given `ArrangementWrapper`.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances.
    ///   - wrapper: The `ArrangementWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addArrangementCMakeFile(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        let cmakeFragment = objcppArrangementCMakeFragment(for: instances, named: name, isSuspensible: isSuspensible)
        let fragmentWrapper = fileWrapper(named: "project.cmake", from: cmakeFragment)
        wrapper.replaceFileWrapper(fragmentWrapper)
        let cmakeLists = objcppArrangementCMakeLists(for: instances, named: name, isSuspensible: isSuspensible)
        let cmakeWrapper = fileWrapper(named: "CMakeLists.txt", from: cmakeLists)
        wrapper.replaceFileWrapper(cmakeWrapper)
        // Static arrangement support
        let staticInterface = objcppStaticArrangementInterface(for: instances, named: name, isSuspensible: isSuspensible)
        let staticInterfaceWrapper = fileWrapper(named: "Static_Arrangement.h", from: staticInterface)
        wrapper.replaceFileWrapper(staticInterfaceWrapper)
        let staticCode = objcppStaticArrangementCode(for: instances, named: name, isSuspensible: isSuspensible)
        let staticCodeWrapper = fileWrapper(named: "Static_Arrangement_\(name).mm", from: staticCode)
        wrapper.replaceFileWrapper(staticCodeWrapper)
        let staticMain = objcppStaticArrangementMainCode(for: instances, named: name, isSuspensible: isSuspensible)
        let staticMainWrapper = fileWrapper(named: "static_main.cc", from: staticMain)
        wrapper.replaceFileWrapper(staticMainWrapper)
        // Add infrastructure headers and implementations
        let infrastructureWrapper = FileWrapper(directoryWithFileWrappers: [:])
        infrastructureWrapper.preferredFilename = "infrastructure"
        // Add header files
        infrastructureWrapper.replaceFileWrapper(fileWrapper(named: "CLAction.h", from: objcppInfrastructureCLActionHeader()))
        infrastructureWrapper.replaceFileWrapper(fileWrapper(named: "CLTransition.h", from: objcppInfrastructureCLTransitionHeader()))
        infrastructureWrapper.replaceFileWrapper(fileWrapper(named: "CLState.h", from: objcppInfrastructureCLStateHeader()))
        infrastructureWrapper.replaceFileWrapper(fileWrapper(named: "CLMachine.h", from: objcppInfrastructureCLMachineHeader(isSuspensible: isSuspensible)))
        infrastructureWrapper.replaceFileWrapper(fileWrapper(named: "CLMacros.h", from: objcppInfrastructureCLMacrosHeader()))
        infrastructureWrapper.replaceFileWrapper(fileWrapper(named: "StateMachineVector.h", from: objcppInfrastructureStateMachineVectorHeader()))
        infrastructureWrapper.replaceFileWrapper(fileWrapper(named: "Machine_Common.h", from: objcppInfrastructureMachineCommonHeader()))
        // Add implementation files
        infrastructureWrapper.replaceFileWrapper(fileWrapper(named: "StateMachineVector.cc", from: objcppInfrastructureStateMachineVectorImplementation()))
        if isSuspensible {
            infrastructureWrapper.replaceFileWrapper(fileWrapper(named: "SuspensibleMachine.cc", from: objcppInfrastructureSuspensibleMachineImplementation()))
        }
        wrapper.replaceFileWrapper(infrastructureWrapper)
    }
}

/// Return the number of transitions based on the content of the State.h file
/// - Parameter content: The content of the `State.h` file
/// - Returns: The number of transitions in the given state.
@inlinable
public func numberOfObjCPPTransitionsIn(header content: String) -> Int {
    guard let numString = string(containedIn: content, matching: #/numberOfTransitions.*return[^0-9]*([0-9][0-9]*)/#),
          let numberOfTransitions = Int(numString) else { return 0 }
    return numberOfTransitions
}


/// Return the target state index of the given transition
/// based on the content of the `State.h` file.
/// - Parameters:
///   - i: The transition number.
///   - content: The content of the `State.h` file.
/// - Returns:
@inlinable
public func targetStateIndexOfObjCPPTransition(_ i: Int, inHeader content: String) -> Int? {
    // swiftlint:disable:next force_try
    guard let numString = string(containedIn: content, matching: try! Regex("Transition_\(i).*int.*toState.*=[^0-9]*([0-9]*)")),
          let targetStateIndex = Int(numString) else { return nil }
    return targetStateIndex
}


/// Read the content of the `State.h` file.
/// - Parameters:
///   - machine: The machine URL.
///   - state: The name of the state to examine.
/// - Returns: The content of the `State.h` file.
@inlinable
public func contentOfObjCPPStateFor(machine: URL, state: StateName) -> String? {
    let file = "State_\(state).h"
    let url = machine.appendingPathComponent(file)
    do {
        let content = try NSString(contentsOf: url, usedEncoding: nil)
        return content as String
    } catch {
        fputs("Cannot read '\(file): \(error.localizedDescription)'\n", stderr)
        return nil
    }
}

/// Read the content of the `State.h` file.
/// - Parameters:
///   - machineWrapper: The machine wrapper.
///   - state: The name of the state to examine.
/// - Returns: The content of the `State.h` file.
@inlinable
public func contentOfObjCPPState(for machineWrapper: MachineWrapper, state: StateName) -> String? {
    machineWrapper.stringContents(of: "State_\(state).h")
}


/// Read the content of the State.h file and return the number of transitions
/// - Parameters:
///   - m: The machine URL.
///   - s: The name of the state to examine.
/// - Returns: The number of transitions leaving the given state.
@inlinable
public func numberOfObjCPPTransitionsFor(machine m: URL, state s: StateName) -> Int {
    guard let content = contentOfObjCPPStateFor(machine: m, state: s) else { return 0 }
    return numberOfObjCPPTransitionsIn(header: content)
}

/// Read the content of the State.h file and return the number of transitions
/// - Parameters:
///   - machine: The machine Wrapper.
///   - state: The name of the state to examine.
/// - Returns: The number of transitions leaving the given state.
@inlinable
public func numberOfObjCPPTransitions(for wrapper: MachineWrapper, state name: StateName) -> Int {
    guard let content = contentOfObjCPPState(for: wrapper, state: name) else { return 0 }
    return numberOfObjCPPTransitionsIn(header: content)
}

/// Read State_%@_Transition_%ld.expr and return the transition expression
/// - Parameters:
///   - machine: The machine URL.
///   - state: The name of the state to examine.
///   - number: The transition number.
/// - Returns: The transition expression.
@inlinable
public func expressionOfObjCPPTransitionFor(machine: URL, state: StateName, transition number: Int) -> String {
    let file = "State_\(state)_Transition_\(number).expr"
    let url = machine.appendingPathComponent(file)
    do {
        let content = try NSString(contentsOf: url, usedEncoding: nil)
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        fputs("Cannot read '\(file): \(error.localizedDescription)'\n", stderr)
        return "true"
    }
}

/// Read State_%@_Transition_%ld.expr and return the transition expression
/// - Parameters:
///   - number: The transition number.
///   - state: The name of the state to examine.
///   - machineWrapper: The MachineWrapper.
/// - Returns: The transition expression.
@inlinable
public func expressionOfObjCPPTransition(_ number: Int, state: StateName, for machineWrapper: MachineWrapper) -> String {
    let file = "State_\(state)_Transition_\(number).expr"
    guard let expression = machineWrapper.stringContents(of: file) else {
        fputs("Cannot read '\(file)'\n", stderr)
        return "true"
    }
    return expression.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Return the target state ID for a given transition
/// - Parameters:
///   - m: URL for the machine in question.
///   - states: Array of states to examine.
///   - name: The name of the state to search for.
///   - number:The sequence number of the transition to examine.
/// - Returns: The State ID if found, `nil` otherwise.
@inlinable
public func targetOfObjCPPTransitionFor(machine m: URL, states: [State], state name: StateName, transition number: Int) -> StateID? {
    guard let content = contentOfObjCPPStateFor(machine: m, state: name),
          let i = targetStateIndexOfObjCPPTransition(number, inHeader: content),
          i >= 0 && i < states.count else { return nil }
    let targetState = states[i]
    return targetState.id
}

/// Return the target state ID for a given transition
/// - Parameters:
///   - number:The sequence number of the transition to examine.
///   - name: The name of the state to search for.
///   - machineWrapper: The MachineWrapper to examine.
///   - states: Array of states to examine.
/// - Returns: The State ID if found, `nil` otherwise.
@inlinable
public func targetOfObjCPPTransition(_ number: Int, state name: StateName, for machineWrapper: MachineWrapper, with states: [State]) -> StateID? {
    guard let content = contentOfObjCPPState(for: machineWrapper, state: name),
          let i = targetStateIndexOfObjCPPTransition(number, inHeader: content),
          i >= 0 && i < states.count else { return nil }
    let targetState = states[i]
    return targetState.id
}

/// Read the content of the <Machine>.mm file
/// - Parameter machine: The machine URL.
/// - Returns: The content of the machine, or `nil` if not found.
@inlinable
public func contentOfObjCPPImplementationFor(machine: URL) -> String? {
    let name = machine.deletingPathExtension().lastPathComponent
    let file = "\(name).mm"
    let url = machine.appendingPathComponent(file)
    do {
        let content = try NSString(contentsOf: url, usedEncoding: nil)
        return content as String
    } catch {
        fputs("Cannot read '\(file): \(error.localizedDescription)'\n", stderr)
        return nil
    }
}

/// Read the content of the <Machine>.mm file
/// - Parameter machineWrapper: The MachineWrapper.
/// - Returns: The content of the machine, or `nil` if not found.
@inlinable
public func contentOfObjCPPImplementation(for machineWrapper: MachineWrapper) -> String? {
    let file = "\(machineWrapper.name).mm"
    guard let content = machineWrapper.stringContents(of: file) else {
        fputs("Cannot read '\(file)'\n", stderr)
        return nil
    }
    return content
}

/// Return the target state index of the given transition
/// based on the content of the State.h file
/// - Parameter content: The content to examine.
/// - Returns: The target state index.
@inlinable
public func suspendStateIndexOfObjCPPMachine(inImplementation content: String) -> Int? {
    guard let numString = string(containedIn: content, matching: #/setSuspendState[^0-9]*([0-9]*)/#),
        let targetStateIndex = Int(numString) else { return nil }
    return targetStateIndex
}

/// Return the suspend state ID for a given machine
/// - Parameters:
///   - m: The machine URL.
///   - states: The states the machine is composed of.
/// - Returns: The suspend state ID, or `nil` if nonexistent.
@inlinable
public func suspendStateOfObjCPPMachine(_ m: URL, states: [State]) -> StateID? {
    guard let content = contentOfObjCPPImplementationFor(machine: m),
          let i = suspendStateIndexOfObjCPPMachine(inImplementation: content),
          i >= 0 && i < states.count else { return nil }
    let suspendState = states[i]
    return suspendState.id
}

/// Return the suspend state ID for a given machine
/// - Parameters:
///   - machineWrapper: The MachineWrapper to examine.
///   - states: The states the machine is composed of.
/// - Returns: The suspend state ID, or `nil` if nonexistent.
@inlinable
public func suspendStateOfObjCPPMachine(_ machineWrapper: MachineWrapper, states: [State]) -> StateID? {
    guard let content = contentOfObjCPPImplementation(for: machineWrapper),
          let i = suspendStateIndexOfObjCPPMachine(inImplementation: content),
          i >= 0 && i < states.count else { return nil }
    let suspendState = states[i]
    return suspendState.id
}

/// Return the mappings of machine boilerplate sections to filenames.
///
/// This function returns the file names relative to the machine URL
/// for the sections of the given machine.
///
/// - Parameter name: The name of the machine the boilerplate belongs to.
/// - Returns: The mappings from section to filename.
@usableFromInline
func objCPPboilerplateFileMappings(for machineName: String) -> [CBoilerplate.BoilerplateFileMapping] {
    [
        (.includePath, Filename.includePath),
        (.includes,  "\(machineName)_Includes.h"),
        (.variables, "\(machineName)_Variables.h"),
        (.functions, "\(machineName)_Methods.h")
    ]
}

/// Return the boilerplate for a given machine.
/// - Parameter machine: The machine URL.
/// - Returns: The boilerplate for the given machine.
@inlinable
public func boilerplateofObjCPPMachine(at machine: URL) -> any Boilerplate {
    let name = machine.deletingPathExtension().lastPathComponent
    var boilerplate = CBoilerplate()
    for (section, fileName) in objCPPboilerplateFileMappings(for: name) {
        boilerplate.sections[section] = machine.stringContents(of: fileName)
    }
    return boilerplate
}

/// Return the boilerplate for a given machine MachineWrapper.
///
/// - Parameter machine: The machine URL.
/// - Returns: The boilerplate for the given machine.
@inlinable
public func boilerplateofObjCPPMachine(for machineWrapper: MachineWrapper) -> any Boilerplate {
    var boilerplate = CBoilerplate()
    for (section, fileName) in objCPPboilerplateFileMappings(for: machineWrapper.name) {
        boilerplate.sections[section] = machineWrapper.stringContents(of: fileName)
    }
    return boilerplate
}

/// Return the mappings of state boilerplate sections to filenames.
///
/// This function returns the file names relative to the machine URL
/// for the sections of the given state.
///
/// - Parameter state: The name of the state the boilerplate belongs to.
/// - Returns: The mappings from section to filename.
@usableFromInline
func objCPPStateBoilerplateFileMappings(for state: String) -> [CBoilerplate.BoilerplateFileMapping] {
    [
        (.includes,  "State_\(state)_Includes.h"),
        (.variables, "State_\(state)_Variables.h"),
        (.variables, "State_\(state)_Variables.h"),
        (.functions, "State_\(state)_Methods.h"),
        (.onEntry,   "State_\(state)_OnEntry.mm"),
        (.onExit,    "State_\(state)_OnExit.mm"),
        (.internal,  "State_\(state)_Internal.mm"),
        (.onSuspend, "State_\(state)_OnSuspend.mm"),
        (.onResume,  "State_\(state)_OnResume.mm")
    ]
}

/// Return the boilerplate for a given state.
///
/// - Parameters:
///   - machine: The machine URL.
///   - state: The name of the state to examine.
/// - Returns: The boilerplate for the given state.
@inlinable
public func boilerplateofObjCPPState(at machine: URL, state: StateName) -> any Boilerplate {
    var boilerplate = CBoilerplate()
    for (section, fileName) in objCPPboilerplateFileMappings(for: state) {
        boilerplate.sections[section] = machine.stringContents(of: fileName)
    }
    return boilerplate
}

/// Return the boilerplate for a given machine MachineWrapper.
///
/// - Parameters:
///   - state: The name of the state to examine.
///   - machineWrapper: The MachineWrapper.
/// - Returns: The boilerplate for the given machine.
@inlinable
public func boilerplateofObjCPPState(_ state: StateName, of machineWrapper: MachineWrapper) -> any Boilerplate {
    var boilerplate = CBoilerplate()
    for (section, fileName) in objCPPStateBoilerplateFileMappings(for: state) {
        boilerplate.sections[section] = machineWrapper.stringContents(of: fileName)
    }
    return boilerplate
}

/// Add ObjC++ machine-level boilerplate files (VarRefs.mm and FuncRefs.mm)
@usableFromInline
func addObjCPPMachineBoilerplate(_ boilerplate: any Boilerplate, to wrapper: MachineWrapper) {
    let machineName = wrapper.name
    let cBoilerplate = CBoilerplate(boilerplate)

    // Generate Machine_X_VarRefs.mm from variables section
    let varRefsContent = objcppVarRefsContent(
        from: cBoilerplate.sections[.variables] ?? "",
        className: machineName,
        variableName: "_m"
    )
    let varRefsWrapper = FileWrapper(regularFileWithContents: Data(varRefsContent.utf8))
    varRefsWrapper.preferredFilename = "\(machineName)_VarRefs.mm"
    wrapper.replaceFileWrapper(varRefsWrapper)

    // Generate Machine_X_FuncRefs.mm from functions section
    let funcRefsFileName = "\(machineName)_FuncRefs.mm"
    let funcRefsContent = objcppFuncRefsContent(from: cBoilerplate.sections[.functions] ?? "", fileName: funcRefsFileName)
    let funcRefsWrapper = FileWrapper(regularFileWithContents: Data(funcRefsContent.utf8))
    funcRefsWrapper.preferredFilename = funcRefsFileName
    wrapper.replaceFileWrapper(funcRefsWrapper)
}

/// Add ObjC++ state-level boilerplate files (VarRefs.mm and FuncRefs.mm)
@usableFromInline
func addObjCPPStateBoilerplate(_ boilerplate: any Boilerplate, to wrapper: MachineWrapper, for stateName: String) {
    let cBoilerplate = CBoilerplate(boilerplate)

    // Generate State_X_VarRefs.mm from variables section
    let varRefsContent = objcppVarRefsContent(
        from: cBoilerplate.sections[.variables] ?? "",
        className: stateName,
        variableName: "_s"
    )
    let varRefsWrapper = FileWrapper(regularFileWithContents: Data(varRefsContent.utf8))
    varRefsWrapper.preferredFilename = "State_\(stateName)_VarRefs.mm"
    wrapper.replaceFileWrapper(varRefsWrapper)

    // Generate State_X_FuncRefs.mm from functions section
    let funcRefsFileName = "State_\(stateName)_FuncRefs.mm"
    let funcRefsContent = objcppFuncRefsContent(from: cBoilerplate.sections[.functions] ?? "", fileName: funcRefsFileName)
    let funcRefsWrapper = FileWrapper(regularFileWithContents: Data(funcRefsContent.utf8))
    funcRefsWrapper.preferredFilename = funcRefsFileName
    wrapper.replaceFileWrapper(funcRefsWrapper)
}

/// Generate VarRefs.mm content from variables section
@usableFromInline
func objcppVarRefsContent(from variables: String, className: String, variableName: String) -> String {
    // Convert variable declarations to references
    // e.g., "int counter;" becomes "int &counter = _m->counter;"
    let varRefs = variables.split(separator: "\n").compactMap { line -> String? in
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("//") else { return trimmed.isEmpty ? nil : String(line) }

        // Match pattern: type varName; or type varName; ///< comment
        if let match = trimmed.range(of: #"^([^;]+?)\s+(\w+)\s*;(.*)$"#, options: .regularExpression) {
            let matched = String(trimmed[match])
            let parts = matched.components(separatedBy: ";")
            if parts.count >= 1 {
                let declPart = parts[0].trimmingCharacters(in: .whitespaces)
                let comment = parts.count > 1 ? parts[1...].joined(separator: ";") : ""
                // Find last word in declaration (the variable name)
                let declComponents = declPart.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                if let varName = declComponents.last, declComponents.count >= 2 {
                    let type = declComponents.dropLast().joined(separator: "\t")
                    return "\(type)\t&\(varName) = \(variableName)->\(varName);\(comment)"
                }
            }
        }
        return String(line)
    }.joined(separator: "\n")

    let fileName = variableName == "_m" ? "\(className)_VarRefs.mm" : "State_\(className)_VarRefs.mm"
    return """
    //
    // \(fileName)
    //
    // Automatically created through MiCASE -- do not change manually!
    //
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wunused-variable"
    #pragma clang diagnostic ignored "-Wshadow"

    \(className) *\(variableName) = static_cast<\(className) *>(_\(variableName == "_m" ? "machine" : "state"));

    \(varRefs.isEmpty ? "" : varRefs + "\n")
    #pragma clang diagnostic pop
    """
}

/// Generate FuncRefs.mm content from functions section
@usableFromInline
func objcppFuncRefsContent(from functions: String, fileName: String = "FuncRefs.mm") -> String {
    return """
    //
    // \(fileName)
    //
    // Automatically created through MiCASE -- do not change manually!
    //
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wc++98-compat"

    \(functions.isEmpty ? "" : functions + "\n")#pragma clang diagnostic pop
    """
}
