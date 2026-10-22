//
//  LLFSMMetamodel.swift
//  FSMEcore
//
//  Created by Rene Hexel on 8/3/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation

/// LLFSMStructural metamodel metadata.
///
/// `LLFSMMetamodel` loads the bundled structural metamodel and keeps typed
/// references to the `EClass` definitions used by the codec layer. This avoids
/// repeating string-based classifier lookups throughout encoding and decoding
/// code, and it provides a single validation point for required metamodel
/// elements.
///
/// The stored `EClass` values correspond directly to the structural concepts
/// used by `swift-fsmlib`, such as machines, states, transitions, layout
/// entries, and arrangement instances.
public struct LLFSMMetamodel: Sendable {
    /// Loaded package for the LLFSMStructural metamodel.
    ///
    /// This package contains every classifier declared by the structural
    /// metamodel resource. Use it when reflective access is needed beyond the
    /// convenience properties exposed by this type.
    public let package: EPackage

    /// `EClass` for arrangement objects.
    ///
    /// This classifier describes the metamodel root used to group named
    /// machine instances.
    public let arrangementClass: EClass

    /// The `Instance` EClass.
    public let instanceClass: EClass

    /// The `Machine` EClass.
    public let machineClass: EClass

    /// The `LLFSM` EClass.
    public let llfsmClass: EClass

    /// The `State` EClass.
    public let stateClass: EClass

    /// The `StateActivities` EClass.
    public let stateActivitiesClass: EClass

    /// The `Transition` EClass.
    public let transitionClass: EClass

    /// The `Boilerplate` EClass.
    public let boilerplateClass: EClass

    /// The `StateBoilerplateEntry` EClass.
    public let stateBoilerplateEntryClass: EClass

    /// The `StateLayoutEntry` EClass.
    public let stateLayoutEntryClass: EClass

    /// The `StateLayout` EClass.
    public let stateLayoutClass: EClass

    /// The `TransitionLayoutEntry` EClass.
    public let transitionLayoutEntryClass: EClass

    /// The `TransitionLayout` EClass.
    public let transitionLayoutClass: EClass

    /// The `Point2D` EClass.
    public let point2DClass: EClass

    /// Load the bundled structural metamodel.
    ///
    /// This initialiser resolves the packaged `.ecore` resource from the
    /// module bundle and then delegates to `init(url:)` for parsing and
    /// validation.
    ///
    /// - Throws: Throw an error if the resource cannot be found or parsed.
    public init() async throws {
        guard let url = Bundle.module.url(
            forResource: "LLFSMStructural",
            withExtension: "ecore",
            subdirectory: "Resources"
        ) else {
            throw LLFSMMetamodelError.resourceNotFound
        }
        try await self.init(url: url)
    }

    /// Load the structural metamodel from a file URL.
    ///
    /// This initialiser parses the `.ecore` document, resolves the package, and
    /// verifies that every classifier required by the codec layer is present.
    /// It fails early if the metamodel shape does not match what `FSMEcore`
    /// expects.
    ///
    /// - Parameter url: URL of the `.ecore` document to load.
    /// - Throws: Throw an error if parsing fails or a required classifier is missing.
    public init(url: URL) async throws {
        package = try await EPackage(url: url)

        guard let arrangement = package.getEClass("Arrangement"),
              let instance = package.getEClass("Instance"),
              let machine = package.getEClass("Machine"),
              let llfsm = package.getEClass("LLFSM"),
              let state = package.getEClass("State"),
              let stateActivities = package.getEClass("StateActivities"),
              let transition = package.getEClass("Transition"),
              let boilerplate = package.getEClass("Boilerplate"),
              let stateBoilerplateEntry = package.getEClass("StateBoilerplateEntry"),
              let stateLayoutEntry = package.getEClass("StateLayoutEntry"),
              let stateLayout = package.getEClass("StateLayout"),
              let transitionLayoutEntry = package.getEClass("TransitionLayoutEntry"),
              let transitionLayout = package.getEClass("TransitionLayout"),
              let point2D = package.getEClass("Point2D")
        else {
            throw LLFSMMetamodelError.missingClass
        }

        arrangementClass = arrangement
        instanceClass = instance
        machineClass = machine
        llfsmClass = llfsm
        stateClass = state
        stateActivitiesClass = stateActivities
        transitionClass = transition
        boilerplateClass = boilerplate
        stateBoilerplateEntryClass = stateBoilerplateEntry
        stateLayoutEntryClass = stateLayoutEntry
        stateLayoutClass = stateLayout
        transitionLayoutEntryClass = transitionLayoutEntry
        transitionLayoutClass = transitionLayout
        point2DClass = point2D
    }

    /// Register the structural metamodel with a resource set.
    ///
    /// Registration makes the structural classifiers available to parsers
    /// and serialisers that use the resource set, so that XMI documents are
    /// read with the declared types of their features rather than with
    /// classes inferred from the document.
    ///
    /// - Parameter resourceSet: Resource set that should know the structural metamodel.
    public func register(in resourceSet: ResourceSet) async {
        await resourceSet.registerMetamodel(package, uri: package.nsURI)
    }
}

/// Errors raised while loading the LLFSM metamodel.
///
/// These cases distinguish between resource lookup failures and structural
/// validation failures so callers can report a more specific problem.
public enum LLFSMMetamodelError: Error, CustomStringConvertible {
    /// Missing bundled `.ecore` resource.
    ///
    /// This case indicates that the module bundle did not contain the expected
    /// structural metamodel resource.
    case resourceNotFound
    /// Missing required classifier definitions.
    ///
    /// This case indicates that the parsed metamodel did not expose every
    /// `EClass` needed by the codec layer.
    case missingClass
    /// Missing required structural feature.
    ///
    /// This case indicates that decoding expected a feature that was not present
    /// on the parsed object graph.
    case missingFeature(String)

    /// Human-readable error description.
    ///
    /// This description is suitable for surfacing loader failures in test
    /// output or diagnostics.
    public var description: String {
        switch self {
        case .resourceNotFound:
            return "LLFSMStructural.ecore resource not found in bundle"
        case .missingClass:
            return "One or more expected EClasses are missing from the LLFSMStructural metamodel"
        case .missingFeature(let name):
            return "Missing expected feature: \(name)"
        }
    }
}
