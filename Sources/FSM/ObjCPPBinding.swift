//
//  ObjCPPBinding.swift
//
//  Created by Rene Hexel on 19/10/2016.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Return an substring contained in a matching, bracketed
/// regular expression pattern.
///
/// - Parameters:
///   - content: The string to examine.
///   - expr: The regular expression pattern to match.
/// - Returns: The substring contained in the first bracketed expression.
func string(containedIn content: String, matching expr: String) -> String? {
    let nsContent = NSString(string: content)
    let regex = try! NSRegularExpression(pattern: expr, options: .anchorsMatchLines)
    guard let match = regex.firstMatch(in: content, options: [], range: NSRange(location: 0, length: nsContent.length)) else {
        return nil
    }
    let range = match.range(at: 1)
    let matchedString = nsContent.substring(with: range)
    return matchedString
}


/// Return the number of transitions based on the content of the State.h file
/// - Parameter content: The content of the `State.h` file
/// - Returns: The number of transitions in the given state.
public func numberOfObjCPPTransitionsIn(header content: String) -> Int {
    guard let numString = string(containedIn: content, matching: "numberOfTransitions.*return[^0-9]*([0-9][0-9]*)"),
          let numberOfTransitions = Int(numString) else { return 0 }
    return numberOfTransitions
}


/// Return the target state index of the given transition
/// based on the content of the `State.h` file.
/// - Parameters:
///   - i: The transition number.
///   - content: The content of the `State.h` file.
/// - Returns:
public func targetStateIndexOfObjCPPTransition(_ i: Int, inHeader content: String) -> Int? {
    guard let numString = string(containedIn: content, matching: "Transition_\(i).*int.*toState.*=[^0-9]*([0-9]*)"),
          let targetStateIndex = Int(numString) else { return nil }
    return targetStateIndex
}


/// Read the content of the `State.h` file.
/// - Parameters:
///   - machine: The machine URL.
///   - state: The name of the state to examine.
/// - Returns: The content of the `State.h` file.
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
public func expressionOfObjCPPTransitionFor(machine: URL, state: StateName, transition number: Int) -> String {
    let file = "State_\(state)_Transition_\(number).expr.h"
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
public func targetOfObjCPPTransitionFor(machine m: URL, states: [State], state name: StateName, transition number: Int) -> StateID? {
    guard let content = contentOfObjCPPStateFor(machine: m, state: name),
          let i = targetStateIndexOfObjCPPTransition(number, inHeader: content),
          i >= 0 && i < states.count else { return nil }
    let targetState = states[i]
    return targetState.id
}


/// Read the content of the <Machine>.mm file
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
public func suspendStateIndexOfObjCPPMachine(inImplementation content: String) -> Int? {
    guard let numString = string(containedIn: content, matching: "setSuspendState[^0-9]*([0-9]*)"),
        let targetStateIndex = Int(numString) else { return nil }
    return targetStateIndex
}


/// Return the suspend state ID for a given machine
public func suspendStateOfObjCPPMachine(_ m: URL, states: [State]) -> StateID? {
    guard let content = contentOfObjCPPImplementationFor(machine: m),
          let i = suspendStateIndexOfObjCPPMachine(inImplementation: content),
          i >= 0 && i < states.count else { return nil }
    let suspendState = states[i]
    return suspendState.id
}





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
}
