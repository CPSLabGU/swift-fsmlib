//
//  LanguageBinding.swift
//
//  Created by Rene Hexel on 14/10/2016.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Standard boilerplate sections supported across all language bindings.
///
/// These sections define the common boilerplate structure used for both
/// machine-level and state-level code generation. Language bindings can
/// extract and create boilerplate using these standardized sections,
/// enabling format-independent conversion and round-trip preservation.
public enum StandardBoilerplateSection: String, CaseIterable, Codable {
    // Common sections (valid for both machines and states)

    /// Include path for header files
    case includePath
    /// Code containing `#include` or `import` directives
    case includes
    /// Variable and member declarations
    case variables
    /// Function and method definitions
    case functions

    // State activity sections

    /// Code executed when entering a state
    case onEntry
    /// Code executed when exiting a state
    case onExit
    /// Internal state processing code
    case `internal`
    /// Code executed when suspending a state machine
    case onSuspend
    /// Code executed when resuming a state machine
    case onResume
}

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

    // MARK: - Section-Based Boilerplate Access

    /// Extract all sections from machine boilerplate.
    ///
    /// This method extracts boilerplate sections into a standardized dictionary format,
    /// enabling format-independent conversion between language bindings.
    ///
    /// - Parameter boilerplate: The machine boilerplate to extract sections from.
    /// - Returns: Dictionary mapping section names to their content.
    func extractSections(from boilerplate: any Boilerplate) -> [StandardBoilerplateSection: String]

    /// Extract all sections from state boilerplate.
    ///
    /// This method extracts state-specific boilerplate sections into a standardized
    /// dictionary format.
    ///
    /// - Parameters:
    ///   - boilerplate: The state boilerplate to extract sections from.
    ///   - stateName: The name of the state.
    /// - Returns: Dictionary mapping section names to their content.
    func extractStateSections(
        from boilerplate: any Boilerplate,
        stateName: StateName
    ) -> [StandardBoilerplateSection: String]

    /// Create machine boilerplate from sections.
    ///
    /// This method creates a boilerplate object from a standardized sections dictionary.
    /// The default implementation builds a CBoilerplate with the provided sections.
    ///
    /// - Parameter sections: Dictionary mapping section names to their content.
    /// - Returns: Boilerplate object appropriate for this language binding.
    func createBoilerplate(from sections: [StandardBoilerplateSection: String]) -> any Boilerplate

    /// Create state boilerplate from sections.
    ///
    /// This method creates state-specific boilerplate from a standardized sections dictionary.
    /// The default implementation builds a CBoilerplate with the provided sections.
    ///
    /// - Parameters:
    ///   - sections: Dictionary mapping section names to their content.
    ///   - stateName: The name of the state.
    /// - Returns: State boilerplate object appropriate for this language binding.
    func createStateBoilerplate(
        from sections: [StandardBoilerplateSection: String],
        stateName: StateName
    ) -> any Boilerplate

    /// Convert machine boilerplate from another language binding.
    ///
    /// This method converts boilerplate from one language binding to another through
    /// the standardized sections dictionary. The default implementation extracts
    /// sections from the source and creates new boilerplate for this binding.
    ///
    /// - Parameters:
    ///   - source: The source boilerplate to convert.
    ///   - sourceLanguage: The language binding that created the source boilerplate.
    /// - Returns: Boilerplate object appropriate for this language binding.
    func convertBoilerplate(
        from source: any Boilerplate,
        sourceLanguage: any LanguageBinding
    ) -> any Boilerplate

    /// Convert state boilerplate from another language binding.
    ///
    /// This method converts state-specific boilerplate from one language binding to
    /// another through the standardized sections dictionary.
    ///
    /// - Parameters:
    ///   - source: The source state boilerplate to convert.
    ///   - sourceLanguage: The language binding that created the source boilerplate.
    ///   - stateName: The name of the state.
    /// - Returns: State boilerplate object appropriate for this language binding.
    func convertStateBoilerplate(
        from source: any Boilerplate,
        sourceLanguage: any LanguageBinding,
        stateName: StateName
    ) -> any Boilerplate
}

/// Default implementations
public extension LanguageBinding {
    /// Compare two language bindings for equality.
    /// - Parameters:
    ///   - lhs: The left-hand side language binding to compare.
    ///   - rhs: The right-hand side language binding to compare.
    /// - Returns: `true` if the two language bindings are equal.
    @inlinable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.name == rhs.name
    }

    /// Return the window layout for the given machine.
    /// - Parameter machineWrapper: The MachineWrapper.
    /// - Returns: The window layout for the given machine (or `nil`).
    @inlinable
    func windowLayout(for machineWrapper: MachineWrapper) -> Data? {
        machineWrapper.fileWrappers?[.windowLayout]?.regularFileContents
    }

    // MARK: - Default Section-Based Implementations

    /// Default implementation: Build CBoilerplate with sections.
    ///
    /// This default implementation creates a CBoilerplate object populated with
    /// the provided sections. Language bindings can override this to create
    /// their own boilerplate types.
    func createBoilerplate(from sections: [StandardBoilerplateSection: String]) -> any Boilerplate {
        var boilerplate = CBoilerplate()
        for (section, content) in sections {
            if let sectionName = CBoilerplate.SectionName(rawValue: section.rawValue) {
                boilerplate.sections[sectionName] = content
            }
        }
        return boilerplate
    }

    /// Default implementation: Build CBoilerplate with sections for states.
    ///
    /// This default implementation creates a CBoilerplate object for state-specific
    /// boilerplate. For most language bindings, state boilerplate uses the same
    /// structure as machine boilerplate.
    func createStateBoilerplate(
        from sections: [StandardBoilerplateSection: String],
        stateName: StateName
    ) -> any Boilerplate {
        // Default: states use same structure as machines
        return createBoilerplate(from: sections)
    }

    /// Default implementation: Convert boilerplate through sections dictionary.
    ///
    /// This default implementation converts boilerplate from one language binding
    /// to another by extracting sections from the source and creating new boilerplate
    /// for this binding.
    func convertBoilerplate(
        from source: any Boilerplate,
        sourceLanguage: any LanguageBinding
    ) -> any Boilerplate {
        let sections = sourceLanguage.extractSections(from: source)
        return createBoilerplate(from: sections)
    }

    /// Default implementation: Convert state boilerplate through sections.
    ///
    /// This default implementation converts state-specific boilerplate from one
    /// language binding to another by extracting sections and creating new
    /// state boilerplate.
    func convertStateBoilerplate(
        from source: any Boilerplate,
        sourceLanguage: any LanguageBinding,
        stateName: StateName
    ) -> any Boilerplate {
        let sections = sourceLanguage.extractStateSections(from: source, stateName: stateName)
        return createStateBoilerplate(from: sections, stateName: stateName)
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
/// This method reads the content of the language file and
/// maps it to a language binding.
///
/// - Note: this function will return a default language binding.
///         Use `languageBindingIfAvailable(for:)` instead
///         if you want to receive a `nil` value if no language binding
///         has been registered.
///
/// - Parameter wrapper: The directory wrapper containing the language file.
/// - Returns: The language binding for the given wrapper..
@inlinable
public func languageBinding(for wrapper: DirectoryWrapper) -> any LanguageBinding {
    languageBinding(for: wrapper.stringContents(of: .language))
}

/// Return the language binding for the given FileWrapper.
///
/// This method reads the content of the language file and
/// maps it to a language binding.
///
/// - Note: this function will return `nil` if no binding is available.
///         Use `languageBinding(for:)` instead
///         if you want to receive a default value if no language binding
///         has been registered.
///
/// - Parameter wrapper: The file wrapper containing the language file.
/// - Returns: The language binding for the given wrapper., or `nil` if not available.
@inlinable
public func languageBindingIfAvailable(for wrapper: FileWrapper) -> (any LanguageBinding)? {
    wrapper.stringContents(of: .language).map(languageBinding(for:))
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
