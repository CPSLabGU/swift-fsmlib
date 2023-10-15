//
//  LanguageBinding.swift
//
//  Created by Rene Hexel on 14/10/2016.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Import/Export binding for a particular programming language
public protocol LanguageBinding: Equatable {
    /// The canonical name of the language binding.
    var name: String { get }
    /// Return the number of transitions for the given state.
    ///
    /// - Parameters:
    ///   - machineWrapper: The machine wrapper to read from.
    ///   - stateName: The name of the state to examine.
    /// - Returns: The number of transitions leaving the given state.
    func numberOfTransitions(for machineWrapper: MachineWrapper, stateName: StateName) -> Int
    /// Return the expression of the given transition.
    ///
    /// This returns the expression of the transition at the given index
    /// in the sequence of transitions leaving the given state.
    ///
    /// - Parameters:
    ///   - transitionNumber: The index of the transition to examine.
    ///   - machineWrapper: The machine wrapper to read from.
    ///   - stateName: The name of the state to examine.
    /// - Returns: The expression of the given transition.
    func expression(of transitionNumber: Int, for machineWrapper: MachineWrapper, stateName: StateName) -> String
    /// Return the target state ID of the given transition.
    ///
    /// - Parameters:
    ///   - transitionNumber: The index of the transition to examine.
    ///   - machineWrapper: The machine wrapper to read from.
    ///   - stateName: The name of the state to examine.
    ///   - states: The states of the machine.
    /// - Returns: The target state ID of the given transition.
    func target(of transitionNumber: Int, for machineWrapper: MachineWrapper, stateName: StateName, with states: [State]) -> StateID?
    /// Return the suspend state ID for the given machine.
    ///
    /// - Parameters:
    ///   - machineWrapper: The machine wrapper to read from.
    ///   - states: The states of the machine.
    /// - Returns: The suspend state ID for the given machine.
    func suspendState(for machineWrapper: MachineWrapper, states: [State]) -> StateID?
    /// Return the boilerplate for the given machine.
    /// - Parameter machineWrapper: The machine wrapper to read from.
    /// - Returns: The boilerplate for the given machine.
    func boilerplate(for machineWrapper: MachineWrapper) -> any Boilerplate
    /// Return the boilerplate for the given state.
    ///
    /// - Parameters:
    ///   - machineWrapper: The machine wrapper to read from.
    ///   - stateName: The name of the state to examine.
    /// - Returns: The boilerplate for the given state.
    func stateBoilerplate(for machineWrapper: MachineWrapper, stateName: StateName) -> any Boilerplate
    /// Return the window layout for the given machine.
    ///
    /// - Parameter machineWrapper: The machine wrapper to read from.
    /// - Returns: The window layout for the given machine.
    func windowLayout(for machineWrapper: MachineWrapper) -> Data?
}

/// Default implementations
public extension LanguageBinding {
    /// Compare two language bindings for equality.
    /// - Parameters:
    ///   - lhs: The left-hand side language binding to compare.
    ///   - rhs: The right-hand side language binding to compare.
    /// - Returns: `true` if the two language bindings are equal.
    @inlinable static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }

    /// Return the window layout for the given machine.
    /// - Parameter machineWrapper: The MachineWrapper.
    /// - Returns: The window layout for the given machine (or `nil`).
    @inlinable
    func windowLayout(for machineWrapper: MachineWrapper) -> Data? {
        machineWrapper.fileWrappers?[.windowLayout]?.regularFileContents
    }
}

/// Return the language binding for the given URL
///
/// - Parameter url: The URL of the machine.
/// - Returns: The language binding for the given URL.
@inlinable
public func languageBinding(for url: URL) -> any LanguageBinding {
    languageBinding(for: url.stringContents(of: .language))
}

/// Return the language binding for the given MachineWrapper.
///
/// - Parameter wrapper: The machine wrapper.
/// - Returns: The language binding for the given wrapper..
@inlinable
public func languageBinding(for wrapper: MachineWrapper) -> any LanguageBinding {
    languageBinding(for: wrapper.stringContents(of: .language))
}

/// Return the language binding for the given language
///
/// - Parameter languageName: The language file contents for the machine.
/// - Returns: The language binding for the given URL.
@inlinable
public func languageBinding(for languageName: String?) -> any LanguageBinding {
    guard let language = languageName?.lines.first?.trimmed.lowercased(),
          let format = Format(rawValue: language),
          let binding = formatToLanguageBinding[format] else {
        return ObjCPPBinding()
    }
    return binding
}

/// Compare two optional language bindings for equality.
///
/// - Parameters:
///   - lhs: The left-hand side language binding to compare.
///   - rhs: The right-hand side language binding to compare.
/// - Returns: `true` if the two language bindings are equal or both `nil`.
@inlinable
public func == (lhs: (any LanguageBinding)?, rhs: (any LanguageBinding)?) -> Bool {
    lhs?.name == rhs?.name
}

/// Compare two optional language bindings for inequality.
///
/// - Parameters:
///   - lhs: The left-hand side language binding to compare.
///   - rhs: The right-hand side language binding to compare.
/// - Returns: `true` if the two language bindings are different.
@inlinable
public func != (lhs: (any LanguageBinding)?, rhs: (any LanguageBinding)?) -> Bool {
    !(lhs == rhs)
}
