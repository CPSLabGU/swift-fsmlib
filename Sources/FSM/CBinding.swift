//
//  CBinding.swift
//
//  Created by Rene Hexel on 12/08/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Plain C language binding
public struct CBinding: OutputLanguage {
    /// The canonical name of the language binding.
    public let name = Format.c.rawValue

    /// Designated initialiser.
    @inlinable
    public init() {}

    /// C binding from URL and state name to number of transitions.
    ///
    /// - Parameters:
    ///   - machineWrapper: The MachineWrapper to examine.
    ///   - stateName: The name of the state to examine.
    /// - Returns: The number of transitions in the given state.
    @inlinable
    public func numberOfTransitions(for machineWrapper: MachineWrapper, stateName: StateName) -> Int {
        numberOfCTransitions(for: machineWrapper, state: stateName)
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
        expressionOfCTransition(transitionNumber, state: stateName, for: machineWrapper)
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
        targetOfCTransition(transitionNumber, state: stateName, for: machineWrapper, with: states)
    }

    /// Objective-C++ binding from URL, states to suspend state ID.
    ///
    /// - Parameters:
    ///   - machineWrapper: The MachineWrapper to examine.
    ///   - states: The states of the machine.
    /// - Returns: The suspend state ID of the given machine.
    @inlinable
    public func suspendState(for machineWrapper: MachineWrapper, states: [State]) -> StateID? {
        suspendStateOfCMachine(machineWrapper, states: states)
    }
    /// Objective-C++ binding from URL to machine boilerplate.
    ///
    /// - Parameter machineWrapper: The MachineWrapper to examine.
    /// - Returns: The boilerplate for the given machine.
    @inlinable
    public func boilerplate(for machineWrapper: MachineWrapper) -> any Boilerplate {
        boilerplateOfCMachine(at: machineWrapper)
    }

    /// Objective-C++ binding from URL and state name to state boilerplate.
    ///
    /// - Parameters:
    ///   - machineWrapper: The MachineWrapper to examine.
    ///   - stateName: The name of the state to examine.
    /// - Returns: The boilerplate for the given state.
    @inlinable
    public func stateBoilerplate(for machineWrapper: MachineWrapper, stateName: StateName) -> any Boilerplate {
        boilerplateofCState(stateName, of: machineWrapper)
    }
}

public extension CBinding {
    /// Add the given boilerplate to the given `MachineWrapper`.
    ///
    /// This function tries to convert the given boilerplate
    /// to a C lanaguage boilerplate and then adds it
    /// to the given `MachineWrapper`.
    ///
    /// - Parameters:
    ///   - boilerplate: The boilerplate to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    @inlinable
    func add(boilerplate: any Boilerplate, to wrapper: MachineWrapper) throws {
        CBoilerplate(boilerplate).add(to: wrapper)
    }
    /// Write the given state boilerplate to the given URL
    /// - Parameters:
    ///   - stateBoilerplate: The boilerplate to add.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - stateName: The name of the state to add the boilerplate for.
    func add(stateBoilerplate: any Boilerplate, to wrapper: MachineWrapper, for stateName: String) throws {
        CBoilerplate(stateBoilerplate).add(state: stateName, to: wrapper)
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
        let machineCode = cMachineInterface(for: llfsm, named: name, isSuspensible: isSuspensible)
        let fileWrapper = fileWrapper(named: "Machine_" + name + ".h", from: machineCode)
        wrapper.addFileWrapper(fileWrapper)
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
            let stateCode = cStateInterface(for: state, llfsm: fsm, named: name, isSuspensible: isSuspensible)
            let fileWrapper = fileWrapper(named: "State_" + state.name + ".h", from: stateCode)
            wrapper.addFileWrapper(fileWrapper)
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
        let machineCode = cMachineCode(for: llfsm, named: name, isSuspensible: isSuspensible)
        let fileWrapper = fileWrapper(named: "Machine_" + name + ".c", from: machineCode)
        wrapper.addFileWrapper(fileWrapper)
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
            let stateCode = cStateCode(for: state, llfsm: fsm, named: name, isSuspensible: isSuspensible)
            let fileWrapper = fileWrapper(named: "State_" + state.name + ".c", from: stateCode)
            wrapper.addFileWrapper(fileWrapper)
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
            transitions.enumerated().forEach { number, transitionID in
                guard let transition = fsm.transitionMap[transitionID] else {
                    fputs("Warning: orphaned transition \(number) (\(transitionID)) for \(state.name)\n", stderr)
                    return
                }
                let file = "State_\(state.name)_Transition_\(number).expr"
                let fileWrapper = fileWrapper(named: file, from: transition.label + "\n")
                wrapper.addFileWrapper(fileWrapper)
            }
        }
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
        let cmakeFragment = cMakeFragment(for: fsm, named: name, isSuspensible: isSuspensible)
        let fragmentWrapper = fileWrapper(named: "project.cmake", from: cmakeFragment)
        wrapper.addFileWrapper(fragmentWrapper)
        let cmakeLists = cMakeLists(for: fsm, named: name, boilerplate: boilerplate, isSuspensible: isSuspensible)
        let cmakeWrapper = fileWrapper(named: "CMakeLists.txt", from: cmakeLists)
        wrapper.addFileWrapper(cmakeWrapper)
    }
}

// Arrangments of C-language LLFSMs

public extension CBinding {
    /// Add the arrangment interface to the given `MachineWrapper`.
    ///
    /// This method adds the arrangement interface (if any)
    /// for the given finite-state machine instances to the given `MachineWrapper`.
    ///
    /// - Parameters:
    ///   - names: The names of the FSM instances.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addArrangementInterface(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        let commonInterface = cArrangementMachineInterface(for: instances, named: name, isSuspensible: isSuspensible)
        let commonWrapper = fileWrapper(named: "Machine_Common.h", from: commonInterface)
        wrapper.addFileWrapper(commonWrapper)
        let arrangementInterface = cArrangementInterface(for: instances, named: name, isSuspensible: isSuspensible)
        let arrangementWrapper = fileWrapper(named: "Arrangement_\(name).h", from: arrangementInterface)
        wrapper.addFileWrapper(arrangementWrapper)
        let staticInterface = cStaticArrangementInterface(for: instances, named: name, isSuspensible: isSuspensible)
        let staticWrapper = fileWrapper(named: "Static_Arrangement_\(name).h", from: staticInterface)
        wrapper.addFileWrapper(staticWrapper)
    }
    /// Add the arrangment implementation to the given .
    ///
    /// This method adds the arrangement code
    /// for the given finite-state machine instances to the given URL.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addArrangementCode(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        let commonCode = cArrangementMachineCode(for: instances, named: name, isSuspensible: isSuspensible)
        let commonWrapper = fileWrapper(named: "Machine_Common.c", from: commonCode)
        wrapper.addFileWrapper(commonWrapper)
        let arrangementCode = cArrangementCode(for: instances, named: name, isSuspensible: isSuspensible)
        let arrangementWrapper = fileWrapper(named: "Arrangement_\(name).c", from: arrangementCode)
        wrapper.addFileWrapper(arrangementWrapper)
        let staticCode = cStaticArrangementCode(for: instances, named: name, isSuspensible: isSuspensible)
        let staticWrapper = fileWrapper(named: "Static_Arrangement_\(name).c", from: staticCode)
        wrapper.addFileWrapper(staticWrapper)
        let mainCode = cStaticArrangementMainCode(for: instances, named: name, isSuspensible: isSuspensible)
        let mainWrapper = fileWrapper(named: "static_main.c", from: mainCode)
        wrapper.addFileWrapper(mainWrapper)
    }
    /// Add a CMakefile for the given LLFSM arrangement to the given `MachineWrapper`.
    ///
    /// This method creates a CMakefile to compile the
    /// given finite-state machine locally at the given `MachineWrapper`.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances.
    ///   - wrapper: The `MachineWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addArrangementCMakeFile(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        let cmakeFragment = cArrangementCMakeFragment(for: instances, named: name, isSuspensible: isSuspensible)
        let fragmentWrapper = fileWrapper(named: "project.cmake", from: cmakeFragment)
        wrapper.addFileWrapper(fragmentWrapper)
        let cmakeLists = cArrangementCMakeLists(for: instances, named: name, isSuspensible: isSuspensible)
        let cmakeWrapper = fileWrapper(named: "CMakeLists.txt", from: cmakeLists)
        wrapper.addFileWrapper(cmakeWrapper)
    }
}

/// Return the number of transitions based on the content of the State.h file
/// - Parameter content: The content of the `State.h` file
/// - Returns: The number of transitions in the given state.
@inlinable
public func numberOfCTransitionsIn(header content: String) -> Int {
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
public func targetStateIndexOfCTransition(_ i: Int, inHeader content: String) -> Int? {
    guard let numString = string(containedIn: content, matching: try! Regex("Transition_\(i).*int.*toState.*=[^0-9]*([0-9]*)")),
          let targetStateIndex = Int(numString) else { return nil }
    return targetStateIndex
}


/// Read the content of the `State.h` file.
/// - Parameters:
///   - machineWrapper: The MachineWrapper.
///   - state: The name of the state to examine.
/// - Returns: The content of the `State.h` file.
@inlinable
public func contentOfCState(for machineWrapper: MachineWrapper, state: StateName) -> String? {
    let file = "State_\(state).h"
    guard let content = machineWrapper.stringContents(of: file) else {
        fputs("Error: cannot read '\(file)'\n", stderr)
        return nil
    }
    return content
}

/// Read the content of the State.h file and return the number of transitions
/// - Parameters:
///   - machineWrapper: The MachineWrapper.
///   - name: The name of the state to examine.
/// - Returns: The number of transitions leaving the given state.
@inlinable
public func numberOfCTransitions(for machineWrapper: MachineWrapper, state name: StateName) -> Int {
    guard let content = contentOfCState(for: machineWrapper, state: name) else { return 0 }
    return numberOfCTransitionsIn(header: content)
}


/// Read State_%@_Transition_%ld.expr and return the transition expression
/// - Parameters:
///   - number: The transition number.
///   - state: The name of the state to examine.
///   - machineWrapper: The MachineWrapper.
/// - Returns: The transition expression.
@inlinable
public func expressionOfCTransition(_ number: Int, state: StateName, for machineWrapper: MachineWrapper) -> String {
    let file = "State_\(state)_Transition_\(number).expr"
    guard let content = machineWrapper.stringContents(of: file) else {
        fputs("Error: cannot read '\(file)'\n", stderr)
        return "true"
    }
    return content.trimmingCharacters(in:.whitespacesAndNewlines)
}

/// Return the target state ID for a given transition
/// - Parameters:
///   - number:The sequence number of the transition to examine.
///   - name: The name of the state to search for.
///   - machineWrapper: MachineWrapper for the machine in question.
///   - states: Array of states to examine.
/// - Returns: The State ID if found, `nil` otherwise.
@inlinable
public func targetOfCTransition(_ number: Int, state name: StateName, for machineWrapper: MachineWrapper, with states: [State]) -> StateID? {
    guard let content = contentOfCState(for: machineWrapper, state: name),
          let i = targetStateIndexOfCTransition(number, inHeader: content),
          i >= 0 && i < states.count else { return nil }
    let targetState = states[i]
    return targetState.id
}

/// Read the content of the <Machine>.c file
/// - Parameter machineWrapper: The MachineWrapper.
/// - Returns: The content of the machine, or `nil` if not found.
public func contentOfCImplementation(for machineWrapper: MachineWrapper) -> String? {
    let file = "Machine_\(machineWrapper.name).c"
    guard let content = machineWrapper.stringContents(of: file) else {
        fputs("Error: cannot read '\(file)'\n", stderr)
        return nil
    }
    return content
}

/// Return the target state index of the given transition
/// based on the content of the State.h file
/// - Parameter content: The content to examine.
/// - Returns: The target state index.
@inlinable
public func suspendStateIndexOfCMachine(inImplementation content: String) -> Int? {
    guard let numString = string(containedIn: content, matching: #/setSuspendState[^0-9]*([0-9]*)/#),
        let targetStateIndex = Int(numString) else { return nil }
    return targetStateIndex
}

/// Return the suspend state ID for a given machine
/// - Parameters:
///   - machineWrapper: The MachineWrapper.
///   - states: The states the machine is composed of.
/// - Returns: The suspend state ID, or `nil` if nonexistent.
@inlinable
public func suspendStateOfCMachine(_ machineWrapper: MachineWrapper, states: [State])  -> StateID? {
    guard let content = contentOfCImplementation(for: machineWrapper),
          let i = suspendStateIndexOfCMachine(inImplementation: content),
          i >= 0 && i < states.count else { return nil }
    let suspendState = states[i]
    return suspendState.id
}
