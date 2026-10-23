//
//  TemplateResourceAndRoundTripTests.swift
//  FSMEcoreTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing
@testable import FSM
@testable import FSMEcore

/// Tests that the verbatim resources of the templates match the Swift binding.
@Suite("Template infrastructure resources")
@MainActor
struct TemplateInfrastructureResourceTests {
    /// The directory below a template set that holds the infrastructure files.
    static let infrastructureDirectory = "infrastructure"

    /// The directory below the infrastructure files that holds the suspensible variants.
    static let suspensibleDirectory = "suspensible"

    /// The infrastructure files and the Swift functions that write them.
    ///
    /// - Parameter isSuspensible: Whether to list the suspensible variants.
    /// - Returns: The resource paths relative to the infrastructure directory and the expected text.
    static func expectedFiles(isSuspensible: Bool) -> [(path: String, text: String)] {
        [
            ("CLAction.h", objcppInfrastructureCLActionHeader()),
            ("CLTransition.h", objcppInfrastructureCLTransitionHeader()),
            ("CLState.h", objcppInfrastructureCLStateHeader()),
            (
                isSuspensible ? suspensibleDirectory + "/CLMachine.h" : "CLMachine.h",
                objcppInfrastructureCLMachineHeader(isSuspensible: isSuspensible)
            ),
            ("CLMacros.h", objcppInfrastructureCLMacrosHeader()),
            ("StateMachineVector.h", objcppInfrastructureStateMachineVectorHeader()),
            ("Machine_Common.h", objcppInfrastructureMachineCommonHeader()),
            ("StateMachineVector.cc", objcppInfrastructureStateMachineVectorImplementation()),
            ("SuspensibleMachine.cc", objcppInfrastructureSuspensibleMachineImplementation()),
        ]
    }

    @Test("Each infrastructure function equals its resource file", arguments: [true, false])
    func resourcesMatchFunctions(isSuspensible: Bool) throws {
        let (_, directory) = try StructuralTemplateEngine().templateSet(for: .objCX)
        let infrastructure = directory.appendingPathComponent(Self.infrastructureDirectory, isDirectory: true)
        for (path, text) in Self.expectedFiles(isSuspensible: isSuspensible) {
            let data = try Data(contentsOf: infrastructure.appendingPathComponent(path))
            #expect(data == Data(text.utf8), "\(path) differs from the Swift infrastructure text")
        }
    }
}

/// Tests that bundles written through the templates read back with the Swift readers.
///
/// The states, transitions and state activities must survive; everything the
/// readers recover beyond that, such as the suspend state, must be what they
/// recover from the bundle that the Swift binding writes.
@Suite("Template round trip")
@MainActor
struct TemplateRoundTripTests {
    /// The cases to read back: every example machine in each format with a Swift reader.
    nonisolated static var cases: [ParityCase] {
        [Format.c, .objCX, .scxml].flatMap { TemplateParity.cases(of: TemplateParity.machineExamples, in: $0) }
    }

    /// Describe the structure of a machine by state and transition names.
    ///
    /// - Parameter machine: The machine.
    /// - Returns: The state names, the transitions as source, label and target, and the suspend state name.
    nonisolated static func structure(of machine: Machine) -> (states: [String], transitions: [String], suspend: String?) {
        let llfsm = machine.llfsm
        let transitions = llfsm.transitions.compactMap { id -> String? in
            guard let transition = llfsm.transition(for: id) else { return nil }
            return [llfsm.stateName(for: transition.source) ?? "", transition.label,
                    llfsm.stateName(for: transition.target) ?? ""].joined(separator: "|")
        }
        return (llfsm.stateNames, transitions, llfsm.suspendState.flatMap { llfsm.stateName(for: $0) })
    }

    @Test("Template output reads back with the Swift readers", arguments: cases)
    func readBack(_ parityCase: ParityCase) async throws {
        let machine = try Machine(from: parityCase.example.url)
        let directory = try TemplateParity.makeDirectory("round-trip")
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = try await TemplateParity.writeTemplateMachine(machine, for: parityCase, in: directory)
        let decoded = try MachineStorageFactory.read(from: url).machine
        let original = Self.structure(of: machine)
        let readBack = Self.structure(of: decoded)
        #expect(readBack.states == original.states)
        #expect(readBack.transitions == original.transitions)
        if parityCase.format.isSingleFile {
            #expect(decoded.language.name == Format.scxml.rawValue)
            return
        }
        #expect(decoded.language.name == outputLanguage(for: parityCase.format)?.name)
        for stateID in machine.llfsm.states {
            guard let name = machine.llfsm.stateName(for: stateID),
                  let decodedID = decoded.llfsm.states.first(where: { decoded.llfsm.stateName(for: $0) == name })
            else { continue }
            for section in CBinding.activitySections {
                let expected = machine.stateActivities(for: stateID)[section] ?? ""
                #expect(decoded.stateActivities(for: decodedID)[section] ?? "" == expected, "\(section) of \(name)")
            }
        }
        let swiftDirectory = try TemplateParity.makeDirectory("round-trip-swift")
        defer { try? FileManager.default.removeItem(at: swiftDirectory) }
        let swiftURL = try TemplateParity.writeSwiftMachine(machine, for: parityCase, in: swiftDirectory)
        let swiftDecoded = Self.structure(of: try MachineStorageFactory.read(from: swiftURL).machine)
        #expect(readBack.suspend == swiftDecoded.suspend)
        #expect(readBack.transitions == swiftDecoded.transitions)
    }
}
