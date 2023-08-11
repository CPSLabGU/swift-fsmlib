//
//  Boilerplate.swift
//
//  Created by Rene Hexel on 7/10/2015.
//  Copyright © 2015, 2016, 2023 Rene Hexel. All rights reserved.
//

/// Boilerplate code
public typealias BoilerplateCode = String

/// Protocol representing generic language boilerplate
public protocol Boilerplate {
    /// Section names for boilerplate code.
    associatedtype SectionName: RawRepresentable, Hashable where SectionName.RawValue == String
    /// Boilerplate sections
    var sections: [SectionName : BoilerplateCode] { get mutating set }
}
