//
//  ObjCPPBinding.swift
//
//  Created by Rene Hexel on 19/10/2016.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Objective-C++ language binding
public struct ObjCPPBinding: OutputLanguage {
    /// The canonical name of the Objective-C++ binding.
    public let name = Format.objCX.rawValue

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
    public let numberOfTransitions: (URL, StateName) -> Int = { url, s in
        numberOfObjCPPTransitionsFor(machine: url, state: s)
    }
    /// Objective-C++ binding from URL, state name, and transition to expression
    public let expressionOfTransition: (URL, StateName) -> (Int) -> String = {
        url, s in { number in
            expressionOfObjCPPTransitionFor(machine: url, state: s, transition: number)
        }
    }
    /// Objective-C++ binding from URL, states, source state name, and transition to target state ID
    public let targetOfTransition: (URL, [State], StateName) -> (Int) -> StateID? = { url, ss, s in
        { number in
            targetOfObjCPPTransitionFor(machine: url, states: ss, state: s, transition: number)
        }
    }
    /// Objective-C++ binding from URL, states to suspend state ID
    public let suspendState: (URL, [State]) -> StateID? = { url, ss in
        suspendStateOfObjCPPMachine(url, states: ss)
    }

    /// Objective-C++ binding from URL to machine boilerplate.
    public let boilerplate: (URL) -> any Boilerplate = { url in
        boilerplateofObjCPPMachine(at: url)
    }

    /// Objective-C++ binding from URL and state name to state boilerplate.
    public var stateBoilerplate: (URL, StateName) -> any Boilerplate = { url, stateName in
        boilerplateofObjCPPState(at: url, state: stateName)
    }

    /// Designated initialiser.
    @inlinable
    public init() {}
}

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
        let staticInterfaceWrapper = fileWrapper(named: "Static_Arrangement_\(name).h", from: staticInterface)
        wrapper.replaceFileWrapper(staticInterfaceWrapper)
        let staticCode = objcppStaticArrangementCode(for: instances, named: name, isSuspensible: isSuspensible)
        let staticCodeWrapper = fileWrapper(named: "Static_Arrangement_\(name).c", from: staticCode)
        wrapper.replaceFileWrapper(staticCodeWrapper)
        let staticMain = objcppStaticArrangementMainCode(for: instances, named: name, isSuspensible: isSuspensible)
        let staticMainWrapper = fileWrapper(named: "static_main.c", from: staticMain)
        wrapper.replaceFileWrapper(staticMainWrapper)
        let staticCMakeFragment = objcppStaticArrangementCMakeFragment(for: instances, named: name, isSuspensible: isSuspensible)
        let staticCMakeFragmentWrapper = fileWrapper(named: "static_project.cmake", from: staticCMakeFragment)
        wrapper.replaceFileWrapper(staticCMakeFragmentWrapper)
        let staticCMakeLists = objcppStaticArrangementCMakeLists(for: instances, named: name, isSuspensible: isSuspensible)
        let staticCMakeListsWrapper = fileWrapper(named: "Static_CMakeLists.txt", from: staticCMakeLists)
        wrapper.replaceFileWrapper(staticCMakeListsWrapper)
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
        return content.trimmingCharacters(in:.whitespacesAndNewlines)
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
    return expression.trimmingCharacters(in:.whitespacesAndNewlines)
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
///   - machmachineWrapperine: The MachineWrapper.
/// - Returns: The boilerplate for the given machine.
@inlinable
public func boilerplateofObjCPPState(_ state: StateName, of machineWrapper: MachineWrapper) -> any Boilerplate {
    var boilerplate = CBoilerplate()
    for (section, fileName) in objCPPStateBoilerplateFileMappings(for: state) {
        boilerplate.sections[section] = machineWrapper.stringContents(of: fileName)
    }
    return boilerplate
}
