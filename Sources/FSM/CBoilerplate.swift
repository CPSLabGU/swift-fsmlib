//
//  CBoilerplate.swift
//
//  Created by Rene Hexel on 7/10/2015.
//  Copyright © 2015, 2016, 2023, 2025 Rene Hexel. All rights reserved.
//

/// Boilerplate for C-based machines.
///
/// This struct encapsulates the boilerplate code sections required for
/// generating C-based finite-state machines, including includes, variables,
/// functions, and state actions. It provides a mapping from section names to
/// code fragments, supporting serialisation and code generation for C and
/// C-derived languages.
///
/// - Note: Use this struct to manage and inject language-specific boilerplate
///         when generating C or C++ FSMs, ensuring consistency and
///         extensibility for new code sections.
public struct CBoilerplate: Boilerplate, Equatable, Codable {
    /// C Language boilerplate sections.
    ///
    /// The sections for machines and states
    /// of languages derived from C.
    public var sections: [SectionName: BoilerplateCode] = {
        SectionName.allCases.reduce(into: [:]) { $0[$1] = "" }
    }()

    /// Designated initialiser.
    @inlinable
    public init() {}
}

/// Extension providing additional boilerplate section names for C-like languages.
///
/// This extension defines the various section names used in CBoilerplate,
/// including include paths, variable and function definitions, and action
/// sections. It is used for organising and generating boilerplate code for
/// FSMs targeting C or C-like languages.
///
/// - Note: Used for code generation and section management in CBoilerplate.
public extension CBoilerplate {
    /// Boilerplate section names.
    enum SectionName: String, RawRepresentable, Hashable, Equatable, Codable, CaseIterable {
        /// The include path.
        case includePath
        /// The code containing `#include` directives.
        case includes
        /// The code containing variable definitions.
        case variables
        /// The code containing function definitions.
        case functions
        /// The code containing the onEntry action.
        case onEntry
        /// The code containing the onExit action.
        case onExit
        /// The code containing the internal action.
        case `internal`
        /// The code containing the onSuspend action.
        case onSuspend
        /// The code containing the onResume action.
        case onResume
    }
}
