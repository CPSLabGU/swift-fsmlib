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
    public var sections: [SectionName : BoilerplateCode] = {
        SectionName.allCases.reduce(into: [:]) { $0[$1] = "" }
    }()

    /// Designated initialiser.
    @inlinable
    public init() {}
}

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
