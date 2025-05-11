//
//  Boilerplate.swift
//
//  Created by Rene Hexel on 7/10/2015.
//  Copyright © 2015, 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Boilerplate code
public typealias BoilerplateCode = String

/// Protocol representing generic language boilerplate
public protocol Boilerplate {
    /// Section names for boilerplate code.
    associatedtype SectionName: RawRepresentable, Hashable where SectionName.RawValue == String
    /// Mapping from file to Boilerplate section.
    typealias BoilerplateFileMapping = (SectionName, Filename)
    /// Boilerplate sections
    var sections: [SectionName: BoilerplateCode] { get mutating set }
    /// Designated initialiser.
    init()
    /// Conversion  initialiser.
    /// - Parameter boilerplate: The boilerplate to convert from.
    init(_ boilerplate: any Boilerplate)
    /// Raw value section accessor.
    /// - Parameter sectionName: The name of the section to get boilerplate code for.
    /// - Returns: The boilerplate code for the given section name (empty if not found).
    func getSection(named sectionName: String) -> BoilerplateCode
    /// Add the boilerplate to the given `MachineWrapper`.
    /// - Parameter wrapper: The `MachineWrapper` to add the boilerplate to.
    func add(to wrapper: MachineWrapper)
    /// Add the boilerplate for a given state to the given `MachineWrapper`.
    /// - Parameters:
    ///   - state: The state to write the boilerplate for.
    ///   - wrapper: The `MachineWrapper` add to.
    func add(state: String, to wrapper: MachineWrapper)
}

public extension Boilerplate {
    /// Conversion  initialiser.
    /// - Parameter boilerplate: The boilerplate to convert from.
    @inlinable
    init(_ boilerplate: any Boilerplate) {
        self.init()
        for section in sections.keys {
            sections[section] = boilerplate.getSection(named: section.rawValue)
        }
    }
    /// Raw value section accessor.
    /// - Parameter sectionName: The name of the section to get boilerplate code for.
    /// - Returns: The boilerplate code for the given section name (empty if not found).
    @inlinable
    func getSection(named sectionName: String) -> BoilerplateCode {
        SectionName(rawValue: sectionName).flatMap { sections[$0] } ?? ""
    }
}
