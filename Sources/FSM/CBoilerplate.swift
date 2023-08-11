//
//  CBoilerplate.swift
//
//  Created by Rene Hexel on 7/10/2015.
//  Copyright © 2015, 2016, 2023 Rene Hexel. All rights reserved.
//

/// Boilerplate for C-based machines.
public struct CBoilerplate: Boilerplate, Equatable, Codable {
    /// C Language boilerplate sections.
    ///
    /// The sections for machines and states
    /// of languages derived from C.
    public var sections: [SectionName : BoilerplateCode] = [
        .includes: "",
        .variables: "",
        .functions: "",
    ]

    /// Designated initialiser.
    @inlinable
    public init() {}
}

public extension CBoilerplate {
    /// Boilerplate section names.
    enum SectionName: String, RawRepresentable, Hashable, Equatable, Codable, CaseIterable {
        /// The code containing `#include` directives.
        case includes
        /// The code containing variable definitions.
        case variables
        /// The code containing function definitions.
        case functions
    }
}
