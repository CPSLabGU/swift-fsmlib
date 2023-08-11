//
//  ObjCPPBinding.swift
//
//  Created by Rene Hexel on 19/10/2016.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Objective-C++ language binding
public struct ObjCPPBinding: LanguageBinding {
    /// Objective-C++ binding from URL and state name to number of transitions
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
        boilerplateofCPPMachine(at: url)
    }

    /// Objective-C++ binding from URL and state name to state boilerplate.
    public var stateBoilerplate: (URL, StateName) -> any Boilerplate = { url, stateName in
        boilerplateofCPPState(at: url, state: stateName)
    }

    /// Designated initialiser.
    @inlinable
    public init() {}
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

/// Return the boilerplate for a given machine.
/// - Parameter machine: The machine URL.
/// - Returns: The boilerplate for the given machine.
@inlinable
public func boilerplateofCPPMachine(at machine: URL) -> any Boilerplate {
    let name = machine.deletingPathExtension().lastPathComponent
    var boilerplate = CBoilerplate()
    boilerplate.sections[.includePath] = machine.stringContents(of: "IncludePath")
    boilerplate.sections[.includes]    = machine.stringContents(of: "\(name)_Includes.h")
    boilerplate.sections[.variables]   = machine.stringContents(of: "\(name)_Variables.h")
    boilerplate.sections[.functions]   = machine.stringContents(of: "\(name)_Methods.h")
    return boilerplate
}

/// Return the boilerplate for a given state.
public func boilerplateofCPPState(at machine: URL, state: StateName) -> any Boilerplate {
    let name = machine.deletingPathExtension().lastPathComponent
    var boilerplate = CBoilerplate()
    boilerplate.sections[.includes]  = machine.stringContents(of: "State_\(name)_Includes.h")
    boilerplate.sections[.variables] = machine.stringContents(of: "State_\(name)_Variables.h")
    boilerplate.sections[.functions] = machine.stringContents(of: "State_\(name)_Methods.h")
    return boilerplate
}

