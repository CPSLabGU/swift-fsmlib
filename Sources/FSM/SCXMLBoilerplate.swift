//
//  SCXMLBoilerplate.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Data declaration in SCXML datamodel.
///
/// Represents a `<data>` element within a `<datamodel>` section,
/// storing a named variable with optional initial value expression or external source.
public struct DataDeclaration: Equatable, Hashable, Codable {
    /// Variable identifier (data id attribute).
    public var id: String

    /// Initial value expression (data expr attribute).
    public var expr: String?

    /// External data source URL (data src attribute).
    public var src: String?

    /// Inline content for complex data structures.
    public var content: String?

    /// Designated initializer for data declarations.
    ///
    /// - Parameters:
    ///   - id: Variable identifier
    ///   - expr: Initial value expression (optional)
    ///   - src: External source URL (optional)
    ///   - content: Inline content (optional)
    public init(id: String, expr: String? = nil, src: String? = nil, content: String? = nil) {
        self.id = id
        self.expr = expr
        self.src = src
        self.content = content
    }
}

/// External service invocation specification.
///
/// Represents an `<invoke>` element for calling external services or state machines.
public struct Invocation: Equatable, Hashable, Codable {
    /// Type of service to invoke (e.g., "scxml", "http://www.w3.org/TR/scxml/").
    public var type: String

    /// Source URL of external service/machine.
    public var src: String?

    /// Unique identifier for this invocation.
    public var id: String?

    /// Auto-forward flag (autoforward attribute).
    public var autoForward: Bool

    /// Designated initializer for invocations.
    ///
    /// - Parameters:
    ///   - type: Service type
    ///   - src: Source URL (optional)
    ///   - id: Invocation identifier (optional)
    ///   - autoForward: Auto-forward events flag (default: false)
    public init(type: String, src: String? = nil, id: String? = nil, autoForward: Bool = false) {
        self.type = type
        self.src = src
        self.id = id
        self.autoForward = autoForward
    }
}

/// History state type enumeration.
///
/// Specifies whether a history pseudo-state should remember
/// only direct children (shallow) or all nested descendants (deep).
public enum HistoryType: String, Equatable, Hashable, Codable {
    /// Shallow history: remembers direct child state only.
    case shallow

    /// Deep history: remembers nested descendant states.
    case deep
}

/// Section names for SCXML boilerplate.
public enum SCXMLSection: String, RawRepresentable, Hashable, Codable {
    case datamodel
    case initialScript
    case metadata
}

/// SCXML-specific boilerplate metadata.
///
/// This structure stores SCXML-specific configuration and metadata
/// including data model declarations, invocation specifications,
/// and tool-specific visual/layout information.
///
/// Conforms to the `Boilerplate` protocol to integrate with the existing
/// FSM machinery while adding SCXML-specific extensions.
public struct SCXMLBoilerplate: Boilerplate, Equatable, Codable {
    // MARK: - Boilerplate Protocol

    public typealias SectionName = SCXMLSection
    public var sections: [SCXMLSection: BoilerplateCode] = [:]

    // MARK: - SCXML Metadata Storage

    /// State-specific SCXML metadata (hierarchies, parallel states, final states, history).
    /// Stored by StateID to avoid polluting the core State structure.
    public var stateMetadata: SCXMLStateMetadataMap

    /// Transition-specific SCXML metadata (events, conditions, executable actions).
    /// Stored by TransitionID to avoid polluting the core Transition structure.
    public var transitionMetadata: SCXMLTransitionMetadataMap

    // MARK: - Data Model

    /// Data model declarations (datamodel/data elements).
    public var dataDeclarations: [DataDeclaration]

    // MARK: - Script Content

    /// Initial script executed at machine initialization.
    public var initialScript: String?

    // MARK: - Invocations

    /// Invocations mapped by state ID.
    ///
    /// Each state can have multiple invoke elements for external service calls.
    public var invocations: [String: [Invocation]]

    // MARK: - SCXML Metadata

    /// SCXML version (typically "1.0").
    public var scxmlVersion: String

    /// Datamodel type ("null", "ecmascript", "xpath", etc.).
    public var datamodel: String

    /// Binding semantics ("early" or "late").
    ///
    /// Early binding: data model initialized before state machine starts.
    /// Late binding: data model initialized when first accessed.
    public var binding: String

    /// Machine name attribute.
    public var name: String?

    /// Target language for code generation (fsm:language attribute).
    ///
    /// Specifies the target programming language when the SCXML document
    /// contains embedded C/C++ boilerplate for round-trip conversion.
    /// Typical values: "c", "c++", "objc", "objc++", nil for pure SCXML.
    public var targetLanguage: String?


    /// Generic boilerplate sections for round-trip conversion.
    ///
    /// This property stores boilerplate sections in a language-independent format,
    /// enabling round-trip conversion between any language binding and SCXML.
    /// Sections are stored in the fsm: namespace during XML serialization.
    public var genericSections: [StandardBoilerplateSection: String]?

    // MARK: - Layout and Visual Metadata

    /// Tool-specific visual metadata (layout, colors, etc.).
    ///
    /// Stored as a generic dictionary to support various tools
    /// (ScxmlEditor, Qt Creator, etc.) without coupling to specific formats.
    public var visualMetadata: [String: String]

    // MARK: - Unknown Elements Preservation

    /// Unknown XML elements preserved for round-trip fidelity.
    ///
    /// Stores elements not recognized during parsing to ensure
    /// lossless conversion when writing back to SCXML.
    public var unknownElements: [String: String]

    // MARK: - Initialization

    /// Default initializer for SCXML boilerplate.
    public init() {
        self.sections = [:]
        self.stateMetadata = [:]
        self.transitionMetadata = [:]
        self.dataDeclarations = []
        self.initialScript = nil
        self.invocations = [:]
        self.scxmlVersion = "1.0"
        self.datamodel = "null"
        self.binding = "early"
        self.name = nil
        self.targetLanguage = nil
        self.genericSections = nil
        self.visualMetadata = [:]
        self.unknownElements = [:]
    }

    /// Designated initializer for SCXML boilerplate.
    ///
    /// - Parameters:
    ///   - stateMetadata: State metadata map (default: empty)
    ///   - transitionMetadata: Transition metadata map (default: empty)
    ///   - dataDeclarations: Data model declarations (default: empty)
    ///   - initialScript: Initial script content (default: nil)
    ///   - invocations: Invocation mappings (default: empty)
    ///   - scxmlVersion: SCXML version (default: "1.0")
    ///   - datamodel: Datamodel type (default: "null")
    ///   - binding: Binding semantics (default: "early")
    ///   - name: Machine name (default: nil)
    ///   - targetLanguage: Target language for code generation (default: nil)
    ///   - genericSections: Generic boilerplate sections (default: nil)
    ///   - visualMetadata: Visual metadata (default: empty)
    ///   - unknownElements: Unknown elements (default: empty)
    public init(
        stateMetadata: SCXMLStateMetadataMap = [:],
        transitionMetadata: SCXMLTransitionMetadataMap = [:],
        dataDeclarations: [DataDeclaration] = [],
        initialScript: String? = nil,
        invocations: [String: [Invocation]] = [:],
        scxmlVersion: String = "1.0",
        datamodel: String = "null",
        binding: String = "early",
        name: String? = nil,
        targetLanguage: String? = nil,
        genericSections: [StandardBoilerplateSection: String]? = nil,
        visualMetadata: [String: String] = [:],
        unknownElements: [String: String] = [:]
    ) {
        self.sections = [:]
        self.stateMetadata = stateMetadata
        self.transitionMetadata = transitionMetadata
        self.dataDeclarations = dataDeclarations
        self.initialScript = initialScript
        self.invocations = invocations
        self.scxmlVersion = scxmlVersion
        self.datamodel = datamodel
        self.binding = binding
        self.name = name
        self.targetLanguage = targetLanguage
        self.genericSections = genericSections
        self.visualMetadata = visualMetadata
        self.unknownElements = unknownElements
    }

    // MARK: - Boilerplate Protocol Methods

    /// Add boilerplate to machine wrapper (SCXML stores metadata separately).
    public func add(to wrapper: MachineDirectoryWrapper) {
        // SCXML boilerplate is primarily metadata, not file-based sections
        // Actual SCXML generation happens during write phase
    }

    /// Add state boilerplate to machine wrapper.
    public func add(state: String, to wrapper: MachineDirectoryWrapper) {
        // SCXML state metadata is handled separately
    }
}

/// Extension providing convenience access to SCXML metadata.
extension SCXMLBoilerplate {
    /// Check if the datamodel uses scripting (ECMAScript, XPath, etc.).
    public var hasScriptingDatamodel: Bool {
        datamodel != "null"
    }

    /// Get all invocation IDs across all states.
    public var allInvocationIds: Set<String> {
        Set(invocations.values.flatMap { $0 }.compactMap { $0.id })
    }

    /// Get data declaration by ID.
    ///
    /// - Parameter id: Data identifier to find
    /// - Returns: Data declaration if found, nil otherwise
    public func dataDeclaration(for id: String) -> DataDeclaration? {
        dataDeclarations.first { $0.id == id }
    }

    /// Add or update a data declaration.
    ///
    /// - Parameter declaration: Data declaration to add or update
    public mutating func setDataDeclaration(_ declaration: DataDeclaration) {
        if let index = dataDeclarations.firstIndex(where: { $0.id == declaration.id }) {
            dataDeclarations[index] = declaration
        } else {
            dataDeclarations.append(declaration)
        }
    }

    /// Remove data declaration by ID.
    ///
    /// - Parameter id: Data identifier to remove
    /// - Returns: true if declaration was removed, false if not found
    @discardableResult
    public mutating func removeDataDeclaration(for id: String) -> Bool {
        if let index = dataDeclarations.firstIndex(where: { $0.id == id }) {
            dataDeclarations.remove(at: index)
            return true
        }
        return false
    }
}
