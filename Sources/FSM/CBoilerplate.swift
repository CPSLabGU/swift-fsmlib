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
    public var sections: [StandardBoilerplateSection: BoilerplateCode] = {
        StandardBoilerplateSection.allCases.reduce(into: [:]) { $0[$1] = "" }
    }()

    /// Designated initialiser.
    @inlinable
    public init() {}
}

// CBoilerplate now uses StandardBoilerplateSection from LanguageBinding.swift
// This eliminates duplication and provides a common section vocabulary across all language bindings.
