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

/// Provides access to the LLFSMStructural metamodel EClasses.
///
/// This struct loads the `LLFSMStructural.ecore` metamodel from the
/// bundled resources and provides convenient access to each EClass
/// definition for use in the codec layer.
public struct LLFSMMetamodel: Sendable {
    /// The loaded EPackage for the LLFSMStructural metamodel.
    public let package: EPackage

    /// The `Arrangement` EClass.
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

    /// Load the metamodel from the bundled `.ecore` resource.
    ///
    /// - Throws: An error if the resource cannot be found or loaded.
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

    /// Load the metamodel from a given URL.
    ///
    /// - Parameter url: The URL of the `.ecore` file to load.
    /// - Throws: An error if the file cannot be parsed or is missing expected classes.
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
}

/// Errors that may occur when loading the LLFSM metamodel.
public enum LLFSMMetamodelError: Error, CustomStringConvertible {
    /// The `.ecore` resource was not found in the bundle.
    case resourceNotFound
    /// One or more expected EClasses are missing from the metamodel.
    case missingClass
    /// A required EClass feature is missing.
    case missingFeature(String)

    /// A human-readable description of the error.
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
