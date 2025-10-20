//
//  CBinding.swift
//
//  Created by Rene Hexel on 12/08/2023.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Plain C language binding
public struct CBinding: OutputLanguage {
    /// The canonical name of the language binding.
    public let name = Format.c.rawValue

    /// Ordered list of activity sections for state boilerplate
    public static let activitySections: [StandardBoilerplateSection] = [.onEntry, .onExit, .internal, .onSuspend, .onResume]

    /// Designated initialiser.
    @inlinable
    public init() {}

    /// C binding from URL and state name to number of transitions.
    ///
    /// - Parameters:
    ///   - storage: The machine storage to examine.
    ///   - stateName: The name of the state to examine.
    /// - Returns: The number of transitions in the given state.
    @inlinable
    public func numberOfTransitions(for storage: any MachineStorage, stateName: StateName) -> Int {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return 0
        }
        return numberOfCTransitions(for: machineWrapper, state: stateName)
    }

    /// C binding from URL, state name, and transition to expression.
    ///
    /// - Parameters:
    ///   - transitionNumber: The transition number to examine.
    ///   - storage: The machine storage to examine.
    ///   - stateName: The name of the state to examine.
    /// - Returns: The expression of the given transition.
    @inlinable
    public func expression(of transitionNumber: Int, for storage: any MachineStorage, stateName: StateName) -> String {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return ""
        }
        return expressionOfCTransition(transitionNumber, state: stateName, for: machineWrapper)
    }

    /// C binding from URL, states, source state name, and transition to target state ID.
    ///
    /// - Parameters:
    ///   - transitionNumber: The transition number to examine.
    ///   - storage: The machine storage to examine.
    ///   - stateName: The name of the state to examine.
    ///   - states: The states of the machine.
    /// - Returns: The target state ID of the given transition.
    @inlinable
    public func target(of transitionNumber: Int, for storage: any MachineStorage, stateName: StateName, with states: [State]) -> StateID? {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return nil
        }
        return targetOfCTransition(transitionNumber, state: stateName, for: machineWrapper, with: states)
    }

    /// C binding from URL, states to suspend state ID.
    ///
    /// - Parameters:
    ///   - storage: The machine storage to examine.
    ///   - states: The states of the machine.
    /// - Returns: The suspend state ID of the given machine.
    @inlinable
    public func suspendState(for storage: any MachineStorage, states: [State]) -> StateID? {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return nil
        }
        return suspendStateOfCMachine(machineWrapper, states: states)
    }
    /// C binding from URL to machine boilerplate.
    ///
    /// - Parameter storage: The machine storage to examine.
    /// - Returns: The boilerplate for the given machine.
    @inlinable
    public func boilerplate(for storage: any MachineStorage) -> any Boilerplate {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return CBoilerplate()
        }
        return boilerplateOfCMachine(at: machineWrapper)
    }

    /// C binding from URL and state name to state boilerplate.
    ///
    /// - Parameters:
    ///   - storage: The machine storage to examine.
    ///   - stateName: The name of the state to examine.
    /// - Returns: The boilerplate for the given state.
    @inlinable
    public func stateBoilerplate(for storage: any MachineStorage, stateName: StateName) -> any Boilerplate {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return CBoilerplate()
        }
        return boilerplateofCState(stateName, of: machineWrapper)
    }

    // MARK: - Section-Based Boilerplate Access

    /// Extract all sections from CBoilerplate.
    ///
    /// - Parameter boilerplate: The boilerplate to extract sections from.
    /// - Returns: Dictionary mapping section names to their content.
    public func extractSections(from boilerplate: any Boilerplate) -> [StandardBoilerplateSection: String] {
        guard let cBoilerplate = boilerplate as? CBoilerplate else {
            return [:]  // Can't extract from unknown type
        }

        // CBoilerplate.sections now uses StandardBoilerplateSection directly
        return cBoilerplate.sections
    }

    /// Extract sections from state boilerplate.
    ///
    /// For CBinding, state sections use the same structure as machine sections.
    ///
    /// - Parameters:
    ///   - boilerplate: The state boilerplate to extract sections from.
    ///   - stateName: The name of the state.
    /// - Returns: Dictionary mapping section names to their content.
    public func extractStateSections(
        from boilerplate: any Boilerplate,
        stateName: StateName
    ) -> [StandardBoilerplateSection: String] {
        // For CBinding, state boilerplate uses same structure
        return extractSections(from: boilerplate)
    }

    /// Extract activities from CBoilerplate.
    /// Returns array exactly long enough to include the last non-nil section.
    @inlinable
    public func extractActivities(from boilerplate: any Boilerplate, stateName: StateName) -> [String]? {
        guard let cBoilerplate = boilerplate as? CBoilerplate else { return nil }

        // Find the last section that exists (is not nil)
        guard let lastIndex = Self.activitySections.lastIndex(where: { cBoilerplate.sections[$0] != nil }) else {
            return nil  // No sections exist
        }

        // Build array up to and including the last existing section
        return Self.activitySections.prefix(lastIndex + 1).map { cBoilerplate.sections[$0] ?? "" }
    }

    /// Create CBoilerplate from activities.
    /// Array length determines which sections exist.
    @inlinable
    public func createStateBoilerplate(from activities: [String], stateName: StateName) -> any Boilerplate {
        var boilerplate = CBoilerplate()

        for (activity, section) in zip(activities, Self.activitySections) {
            boilerplate.sections[section] = activity
        }

        return boilerplate
    }
}

/// Extension providing methods for adding C boilerplate, interfaces, code,
/// and CMake files to a MachineDirectoryWrapper for C-based finite-state machines.
/// These methods facilitate the serialisation and code generation process
/// for C language targets, including support for suspensible machines.
public extension CBinding {
    /// Add the given boilerplate to the given machine storage.
    ///
    /// This function tries to convert the given boilerplate
    /// to a C lanaguage boilerplate and then adds it
    /// to the given machine storage.
    ///
    /// - Parameters:
    ///   - boilerplate: The boilerplate to add.
    ///   - storage: The machine storage to add to.
    @inlinable
    func add(boilerplate: any Boilerplate, to storage: any MachineStorage) throws {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return
        }
        CBoilerplate(boilerplate).add(to: machineWrapper)
    }
    /// Write the given state boilerplate to the given URL
    /// - Parameters:
    ///   - stateBoilerplate: The boilerplate to add.
    ///   - storage: The machine storage to add to.
    ///   - stateName: The name of the state to add the boilerplate for.
    func add(stateBoilerplate: any Boilerplate, to storage: any MachineStorage, for stateName: String) throws {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return
        }
        CBoilerplate(stateBoilerplate).add(state: stateName, to: machineWrapper)
    }
    /// Add the interface for the given LLFSM to the given machine storage.
    ///
    /// This method adds the language interface (if any)
    /// for the given finite-state machine to the given machine storage.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - storage: The machine storage to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addInterface(for llfsm: LLFSM, to storage: any MachineStorage, isSuspensible: Bool) throws {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return
        }
        let name = storage.name
        let machineCode = cMachineInterface(for: llfsm, named: name, isSuspensible: isSuspensible)
        let fileWrapper = fileWrapper(named: "Machine_" + name + ".h", from: machineCode)
        machineWrapper.replaceFileWrapper(fileWrapper)
    }
    /// Add the state interface for the given LLFSM to the given machine storage.
    ///
    /// This method adds the language interface (if any)
    /// for the given finite-state machine to the given machine storage.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - storage: The machine storage to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addStateInterface(for fsm: LLFSM, to storage: any MachineStorage, isSuspensible: Bool) throws {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return
        }
        let name = storage.name
        for stateID in fsm.states {
            guard let state = fsm.stateMap[stateID] else {
                fputs("Warning: orphaned state ID \(stateID) for \(name)\n", stderr)
                continue
            }
            let stateCode = cStateInterface(for: state, llfsm: fsm, named: name, isSuspensible: isSuspensible)
            let fileWrapper = fileWrapper(named: "State_" + state.name + ".h", from: stateCode)
            machineWrapper.replaceFileWrapper(fileWrapper)
        }
    }
    /// Add the code for the given LLFSM to the given machine storage.
    ///
    /// This method adds the implementation code
    /// for the given finite-state machine to the given machine storage.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - storage: The machine storage to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addCode(for llfsm: LLFSM, to storage: any MachineStorage, isSuspensible: Bool) throws {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return
        }
        let name = storage.name
        let machineCode = cMachineCode(for: llfsm, named: name, isSuspensible: isSuspensible)
        let fileWrapper = fileWrapper(named: "Machine_" + name + ".c", from: machineCode)
        machineWrapper.replaceFileWrapper(fileWrapper)
    }
    /// Add the state code for the given LLFSM to the given machine storage.
    ///
    /// This method adds the language interface (if any)
    /// for the given finite-state machine to the given machine storage.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - storage: The machine storage to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addStateCode(for fsm: LLFSM, to storage: any MachineStorage, isSuspensible: Bool) throws {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return
        }
        let name = storage.name
        for stateID in fsm.states {
            guard let state = fsm.stateMap[stateID] else {
                fputs("Warning: orphaned state ID \(stateID) for \(name)\n", stderr)
                continue
            }
            let stateCode = cStateCode(for: state, llfsm: fsm, named: name, isSuspensible: isSuspensible)
            let fileWrapper = fileWrapper(named: "State_" + state.name + ".c", from: stateCode)
            machineWrapper.replaceFileWrapper(fileWrapper)
        }
    }
    /// Add the transition expressions for the given LLFSM to the given machine storage.
    ///
    /// This method adds the transition expressions
    /// for the given finite-state machine to the given machine storage.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - storage: The machine storage to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addTransitionCode(for fsm: LLFSM, to storage: any MachineStorage, isSuspensible: Bool) throws {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return
        }
        let name = storage.name
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
                let labelExpression = transition.label.hasSuffix("\n") ? transition.label : transition.label + "\n"
                let fileWrapper = fileWrapper(named: file, from: labelExpression)
                machineWrapper.replaceFileWrapper(fileWrapper)
            }
        }
    }
    /// Add a CMakefile for the given LLFSM to the given machine storage.
    ///
    /// This method creates a CMakefile to compile the
    /// given finite-state machine locally and adds it
    /// to the given machine storage.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine to add.
    ///   - boilerplate: The boilerplate containing the include paths.
    ///   - storage: The machine storage to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addCMakeFile(for fsm: LLFSM, boilerplate: any Boilerplate, to storage: any MachineStorage, isSuspensible: Bool) throws {
        guard let machineWrapper = storage.fileWrapper as? MachineDirectoryWrapper else {
            return
        }
        let name = storage.name
        let cmakeFragment = cMakeFragment(for: fsm, named: name, isSuspensible: isSuspensible)
        let fragmentWrapper = fileWrapper(named: "project.cmake", from: cmakeFragment)
        machineWrapper.replaceFileWrapper(fragmentWrapper)
        let cmakeLists = cMakeLists(for: fsm, named: name, boilerplate: boilerplate, isSuspensible: isSuspensible)
        let cmakeWrapper = fileWrapper(named: "CMakeLists.txt", from: cmakeLists)
        machineWrapper.replaceFileWrapper(cmakeWrapper)
    }
}

// Arrangments of C-language LLFSMs

/// Extension providing methods for adding arrangement interfaces, code,
/// and CMake files to a MachineDirectoryWrapper for arrangements of C-based
/// finite-state machines. These methods facilitate the serialisation and
/// code generation process for arrangements of FSMs in C.
public extension CBinding {
    /// Add the arrangment interface to the given `MachineDirectoryWrapper`.
    ///
    /// This method adds the arrangement interface (if any)
    /// for the given finite-state machine instances to the given `MachineDirectoryWrapper`.
    ///
    /// - Parameters:
    ///   - names: The names of the FSM instances.
    ///   - wrapper: The `MachineDirectoryWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addArrangementInterface(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        let commonInterface = cArrangementMachineInterface(for: instances, named: name, isSuspensible: isSuspensible)
        let commonWrapper = fileWrapper(named: "Machine_Common.h", from: commonInterface)
        wrapper.replaceFileWrapper(commonWrapper)
        let arrangementInterface = cArrangementInterface(for: instances, named: name, isSuspensible: isSuspensible)
        let arrangementWrapper = fileWrapper(named: "Arrangement_\(name).h", from: arrangementInterface)
        wrapper.replaceFileWrapper(arrangementWrapper)
        let staticInterface = cStaticArrangementInterface(for: instances, named: name, isSuspensible: isSuspensible)
        let staticWrapper = fileWrapper(named: "Static_Arrangement.h", from: staticInterface)
        wrapper.replaceFileWrapper(staticWrapper)
    }
    /// Add the arrangment implementation to the given .
    ///
    /// This method adds the arrangement code
    /// for the given finite-state machine instances to the given URL.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances.
    ///   - wrapper: The `MachineDirectoryWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    func addArrangementCode(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        let commonCode = cArrangementMachineCode(for: instances, named: name, isSuspensible: isSuspensible)
        let commonWrapper = fileWrapper(named: "Machine_Common.c", from: commonCode)
        wrapper.replaceFileWrapper(commonWrapper)
        let arrangementCode = cArrangementCode(for: instances, named: name, isSuspensible: isSuspensible)
        let arrangementWrapper = fileWrapper(named: "Arrangement_\(name).c", from: arrangementCode)
        wrapper.replaceFileWrapper(arrangementWrapper)
        let staticCode = cStaticArrangementCode(for: instances, named: name, isSuspensible: isSuspensible)
        let staticWrapper = fileWrapper(named: "Static_Arrangement_\(name).c", from: staticCode)
        wrapper.replaceFileWrapper(staticWrapper)
        let mainCode = cStaticArrangementMainCode(for: instances, named: name, isSuspensible: isSuspensible)
        let mainWrapper = fileWrapper(named: "static_main.c", from: mainCode)
        wrapper.replaceFileWrapper(mainWrapper)
    }
    /// Add a CMakefile for the given LLFSM arrangement to the given `MachineDirectoryWrapper`.
    ///
    /// This method creates a CMakefile to compile the
    /// given finite-state machine locally at the given `MachineDirectoryWrapper`.
    ///
    /// - Parameters:
    ///   - instances: The FSM instances.
    ///   - wrapper: The `MachineDirectoryWrapper` to add to.
    ///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
    @inlinable
    func addArrangementCMakeFile(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        let name = wrapper.name
        let cmakeFragment = cArrangementCMakeFragment(for: instances, named: name, isSuspensible: isSuspensible)
        let fragmentWrapper = fileWrapper(named: "project.cmake", from: cmakeFragment)
        wrapper.replaceFileWrapper(fragmentWrapper)
        let cmakeLists = cArrangementCMakeLists(for: instances, named: name, isSuspensible: isSuspensible)
        let cmakeWrapper = fileWrapper(named: "CMakeLists.txt", from: cmakeLists)
        wrapper.replaceFileWrapper(cmakeWrapper)
    }
}

/// Return the number of transitions based on the content of the `State.h` file.
///
/// This function parses the provided header content
/// to determine the number of transitions defined
/// for a state in a C-language finite-state machine.
/// It searches for specific preprocessor definitions
/// or return statements that indicate the number of transitions.
///
/// - Parameter content: The content of the `State.h` file.
/// - Returns: The number of transitions in the given state.
@inlinable
public func numberOfCTransitionsIn(header content: String) -> Int {
    if let numString = string(containedIn: content, matching: #/#define.*_NUMBER_OF_TRANSITIONS[^0-9]*([0-9][0-9]*)/#),
       let numberOfTransitions = Int(numString) {
        return numberOfTransitions
    }
    guard let numString = string(containedIn: content, matching: #/numberOfTransitions.*return[^0-9]*([0-9][0-9]*)/#),
          let numberOfTransitions = Int(numString) else { return 0 }
    return numberOfTransitions
}

/// Return the target state index of the given transition
///
/// This function parses the header or implementation content to extract the target state index
/// for a specific transition. It supports both old-style ObjCPP format (in .h files) with
/// `toState = X` and new-style C format (in .c files) with `machine->states[X]`.
///
/// - Parameters:
///   - i: The transition number.
///   - headerContent: The content of the `State.h` file.
///   - implContent: The content of the `State.c` file (optional).
/// - Returns: The target state index if found, or `nil` otherwise.
@inlinable
public func targetStateIndexOfCTransition(_ i: Int, inHeader headerContent: String, implementation implContent: String? = nil) -> Int? {
    // Try old-style ObjCPP format in header: Transition_X(..., int toState = Y)
    // swiftlint:disable:next force_try
    if let numString = string(containedIn: headerContent, matching: try! Regex("Transition_\(i).*int.*toState.*=[^0-9]*([0-9]*)")),
       let targetStateIndex = Int(numString) {
        return targetStateIndex
    }
    // Try new-style C format in implementation: return machine->states[X];
    // This appears in State_X.c files in check_transitions functions
    if let implContent {
        // Look for pattern like: #include "State_X_Transition_Y.expr" ... ) return machine->states[Z];
        // Use [\s\S] to match any character including newlines
        // swiftlint:disable:next force_try
        if let numString = string(containedIn: implContent, matching: try! Regex("State_.*_Transition_\(i)\\.expr[\\s\\S]*?return\\s+machine->states\\[(\\d+)\\]")),
           let targetStateIndex = Int(numString) {
            return targetStateIndex
        }
    }
    return nil
}

/// Read the content of the `State.h` file.
///
/// This function attempts to read the contents
/// of the state header file for the specified state
/// from the provided machine wrapper.
/// If the `State.h` file cannot be read,
/// an error message is printed and `nil` is returned.
///
/// - Parameters:
///   - machineWrapper: The MachineDirectoryWrapper containing the state files.
///   - state: The name of the state to examine.
/// - Returns: The content of the `State.h` file as a string, or `nil` if the file cannot be read.
@inlinable
public func contentOfCState(for machineWrapper: MachineDirectoryWrapper, state: StateName) -> String? {
    let file = "State_\(state).h"
    guard let content = machineWrapper.stringContents(of: file) else {
        fputs("Error: cannot read '\(file)'\n", stderr)
        return nil
    }
    return content
}

/// Read the content of the `State.c` file.
///
/// This function attempts to read the contents
/// of the state implementation file for the specified state
/// from the provided machine wrapper.
/// If the `State.c` file cannot be read,
/// an error message is printed and `nil` is returned.
///
/// - Parameters:
///   - machineWrapper: The MachineDirectoryWrapper containing the state files.
///   - state: The name of the state to examine.
/// - Returns: The content of the `State.c` file as a string, or `nil` if the file cannot be read.
@inlinable
public func contentOfCStateImplementation(for machineWrapper: MachineDirectoryWrapper, state: StateName) -> String? {
    let file = "State_\(state).c"
    guard let content = machineWrapper.stringContents(of: file) else {
        fputs("Error: cannot read '\(file)'\n", stderr)
        return nil
    }
    return content
}

/// Read the content of the State.h file and return the number of transitions
/// - Parameters:
///   - machineWrapper: The MachineDirectoryWrapper.
///   - name: The name of the state to examine.
/// - Returns: The number of transitions leaving the given state.
@inlinable
public func numberOfCTransitions(for machineWrapper: MachineDirectoryWrapper, state name: StateName) -> Int {
    guard let content = contentOfCState(for: machineWrapper, state: name) else { return 0 }
    return numberOfCTransitionsIn(header: content)
}

/// Read State_%@_Transition_%ld.expr and return the transition expression
/// - Parameters:
///   - number: The transition number.
///   - state: The name of the state to examine.
///   - machineWrapper: The MachineDirectoryWrapper.
/// - Returns: The transition expression.
@inlinable
public func expressionOfCTransition(_ number: Int, state: StateName, for machineWrapper: MachineDirectoryWrapper) -> String {
    let file = "State_\(state)_Transition_\(number).expr"
    guard let content = machineWrapper.stringContents(of: file) else {
        fputs("Error: cannot read '\(file)'\n", stderr)
        return "true"
    }
    return content.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// Return the target state ID for a given transition
/// - Parameters:
///   - number:The sequence number of the transition to examine.
///   - name: The name of the state to search for.
///   - machineWrapper: MachineDirectoryWrapper for the machine in question.
///   - states: Array of states to examine.
/// - Returns: The State ID if found, `nil` otherwise.
@inlinable
public func targetOfCTransition(_ number: Int, state name: StateName, for machineWrapper: MachineDirectoryWrapper, with states: [State]) -> StateID? {
    guard let headerContent = contentOfCState(for: machineWrapper, state: name) else { return nil }
    let implContent = contentOfCStateImplementation(for: machineWrapper, state: name)
    guard let i = targetStateIndexOfCTransition(number, inHeader: headerContent, implementation: implContent),
          i >= 0 && i < states.count else { return nil }
    let targetState = states[i]
    return targetState.id
}

/// Read the content of the <Machine>.c file
/// - Parameter machineWrapper: The MachineDirectoryWrapper.
/// - Returns: The content of the machine, or `nil` if not found.
public func contentOfCImplementation(for machineWrapper: MachineDirectoryWrapper) -> String? {
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
    if let numString = string(containedIn: content, matching: #/suspend_state = [^0-9]*([0-9]*)/#),
       let targetStateIndex = Int(numString) {
        return targetStateIndex
    }
    guard let numString = string(containedIn: content, matching: #/setSuspendState[^0-9]*([0-9]*)/#),
        let targetStateIndex = Int(numString) else { return nil }
    return targetStateIndex
}

/// Return the suspend state ID for a given machine
/// - Parameters:
///   - machineWrapper: The MachineDirectoryWrapper.
///   - states: The states the machine is composed of.
/// - Returns: The suspend state ID, or `nil` if nonexistent.
@inlinable
public func suspendStateOfCMachine(_ machineWrapper: MachineDirectoryWrapper, states: [State]) -> StateID? {
    guard let content = contentOfCImplementation(for: machineWrapper),
          let i = suspendStateIndexOfCMachine(inImplementation: content),
          i >= 0 && i < states.count else { return nil }
    let suspendState = states[i]
    return suspendState.id
}
