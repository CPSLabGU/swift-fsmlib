//
//  LanguageBinding.swift
//
//  Created by Rene Hexel on 14/10/2016.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Import/Export binding for a particular programming language
public protocol LanguageBinding {
    /// The canonical name of the language binding.
    var name: String { get }
    /// Binding from machine URL and state name to number of transitions
    var numberOfTransitions: (URL, StateName) -> Int { get }
    /// Binding to get expression from URL, state, and transition number
    var expressionOfTransition: (URL, StateName) -> (Int) -> String { get }
    /// Binding from URL, states, source state name, and transition to target state ID
    var targetOfTransition: (URL, [State], StateName) -> (Int) -> StateID? { get }
    /// Binding from URL, states to suspend state ID
    var suspendState: (URL, [State]) -> StateID? { get }
    /// Binding from URL to machine Boilerplate
    var boilerplate: (URL) -> any Boilerplate { get }
    /// Binding from URL and state name to state Boilerplate
    var stateBoilerplate: (URL, StateName) -> any Boilerplate { get }
}

/// Return the language binding for the given URL
///
/// - Parameter url: The URL of the machine.
/// - Returns: The language binding for the given URL.
public func languageBinding(for url: URL) -> any LanguageBinding {
    guard let language = url.stringContents(of: .language).lines.first?.trimmed.lowercased(),
          let format = Format(rawValue: language),
          let binding = formatToLanguageBinding[format] else {
        return ObjCPPBinding()
    }
    return binding
}
