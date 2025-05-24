//
//  Boilerplate.swift
//
//  Created by Rene Hexel on 7/10/2015.
//  Copyright © 2015, 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Boilerplate code
public typealias BoilerplateCode = String

/// Protocol representing generic language boilerplate for code generation.
///
/// This protocol defines the requirements for boilerplate code used in
/// language bindings for finite-state machines. It specifies the structure
/// for managing boilerplate sections, mapping section names to code, and
/// adding boilerplate to machine wrappers. Conforming types provide the
/// necessary code fragments for different parts of generated source files.
///
/// - Note: Boilerplate conformers are used to inject language-specific code
///         into generated files, supporting extensibility for new languages
///         and custom code sections.
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

/// Extension providing additional boilerplate section names for C-like languages.
///
/// This extension defines the various section names used in CBoilerplate,
/// including include paths, variable and function definitions, and action
/// sections. It is used for organising and generating boilerplate code for
/// FSMs targeting C or C-like languages.
public extension Boilerplate {
    /// Return all section keys.
    ///
    /// This property returns the keys of the sections dictionary,
    /// representing the names of the boilerplate sections
    /// as Strings.
    @inlinable var sectionNames: [String] {
        sections.keys.map(\.rawValue)
    }
    /// Conversion initialiser from another boilerplate instance.
    ///
    /// Creates a new boilerplate by copying all sections from
    /// the provided boilerplate instance.  This is useful for
    /// duplicating or adapting boilerplate content for different
    /// finite-state machines (FSMs) or language bindings.
    ///
    /// Use this initialiser when you need to create a variant of an existing boilerplate for reuse or modification.
    ///
    /// - Parameter boilerplate: The boilerplate instance to convert from.
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
