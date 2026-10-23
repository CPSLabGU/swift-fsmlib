//
//  TemplateParityTests.swift
//  FSMEcoreTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing
@testable import FSM
@testable import FSMEcore

/// Byte for byte parity of the structural templates with the Swift language bindings.
///
/// Every example machine and arrangement is written once with the Swift
/// binding of a format and once through the templates, for both suspensibility
/// settings, and the two renditions must hold the same files with the same bytes.
@Suite("Template parity")
@MainActor
struct TemplateParityTests {
    /// Compare the renditions of a machine.
    ///
    /// - Parameter parityCase: The machine, format and suspensibility to compare.
    func compareMachine(_ parityCase: ParityCase) async throws {
        let machine = try Machine(from: parityCase.example.url)
        let swiftDirectory = try TemplateParity.makeDirectory("swift")
        let templateDirectory = try TemplateParity.makeDirectory("template")
        defer {
            try? FileManager.default.removeItem(at: swiftDirectory)
            try? FileManager.default.removeItem(at: templateDirectory)
        }
        let swiftURL = try TemplateParity.writeSwiftMachine(machine, for: parityCase, in: swiftDirectory)
        let templateURL = try await TemplateParity.writeTemplateMachine(machine, for: parityCase, in: templateDirectory)
        try TemplateParity.expectIdentical(
            try TemplateParity.files(at: templateURL), try TemplateParity.files(at: swiftURL), case: parityCase)
    }

    /// Compare the renditions of an arrangement.
    ///
    /// - Parameter parityCase: The arrangement, format and suspensibility to compare.
    func compareArrangement(_ parityCase: ParityCase) async throws {
        let arrangement = try ArrangementWrapper(url: parityCase.example.url).arrangement
        let language = try #require(outputLanguage(for: parityCase.format))
        let binding = try await TemplateBinding.make(
            for: arrangement, named: parityCase.example.name, format: parityCase.format,
            isSuspensible: parityCase.isSuspensible)
        let templateDirectory = try TemplateParity.makeDirectory("template")
        var directories = [templateDirectory]
        defer { directories.forEach { try? FileManager.default.removeItem(at: $0) } }
        let templateURL = try TemplateParity.writeArrangement(
            arrangement, language: binding, for: parityCase, in: templateDirectory)
        func swiftRendition() throws -> [String: Data] {
            let directory = try TemplateParity.makeDirectory("swift")
            directories.append(directory)
            let url = try TemplateParity.writeArrangement(
                arrangement, language: language, for: parityCase, in: directory)
            return try TemplateParity.files(at: url)
        }
        var renditions = 1
        try TemplateParity.expectIdentical(
            try TemplateParity.files(at: templateURL), try swiftRendition(), case: parityCase,
            alternatives: {
                guard renditions < TemplateParity.arrangementRenditions else { return nil }
                renditions += 1
                return try swiftRendition()
            },
            allowsReorderedLines: Set(arrangement.namedInstances.map(\.typeFile)).count > 1)
    }

    @Test("C machines", arguments: TemplateParity.cases(of: TemplateParity.machineExamples, in: .c))
    func cMachine(_ parityCase: ParityCase) async throws {
        try await compareMachine(parityCase)
    }

    @Test("Objective-C++ machines", arguments: TemplateParity.cases(of: TemplateParity.machineExamples, in: .objCX))
    func objcppMachine(_ parityCase: ParityCase) async throws {
        try await compareMachine(parityCase)
    }

    @Test("SCXML machines", arguments: TemplateParity.cases(of: TemplateParity.machineExamples, in: .scxml))
    func scxmlMachine(_ parityCase: ParityCase) async throws {
        try await compareMachine(parityCase)
    }

    @Test("C arrangements", arguments: TemplateParity.cases(of: TemplateParity.arrangementExamples, in: .c))
    func cArrangement(_ parityCase: ParityCase) async throws {
        try await compareArrangement(parityCase)
    }

    @Test(
        "Objective-C++ arrangements",
        arguments: TemplateParity.cases(of: TemplateParity.arrangementExamples, in: .objCX))
    func objcppArrangement(_ parityCase: ParityCase) async throws {
        try await compareArrangement(parityCase)
    }
}

/// Parity of the layout file for every kind of additional layout property.
@Suite("Template layout parity")
@MainActor
struct TemplateLayoutParityTests {
    /// Create a machine whose layouts exercise every property list value type and path length.
    ///
    /// - Returns: The machine.
    static func makeMachine() -> Machine {
        let (machine, stateID) = LayoutPropertyEncodingTests.makeMachine()
        let other = State(name: "Other & <More>")
        var transitions: [Transition] = []
        var layouts: TransitionLayouts = [:]
        for count in 0...5 {
            let transition = Transition(label: "t\(count)", source: stateID, target: other.id)
            transitions.append(transition)
            let points = (0..<count).map { Point2D(Double($0) * 10.5 - 3, 0.1 * Double($0 + 1)) }
            layouts[transition.id] = TransitionLayout(points)
        }
        machine.llfsm = LLFSM(states: machine.llfsm.states.compactMap { machine.llfsm.stateMap[$0] } + [other],
                              transitions: transitions, suspendState: nil)
        machine.transitionLayout = layouts
        var otherLayout = StateLayout(index: 1)
        otherLayout.extraProperties = ["empty": [String: Any](), "none": [Any](), "blob": Data(repeating: 7, count: 200)]
        machine.stateLayout[other.id] = otherLayout
        machine.windowLayout = Data([0x3C, 0x00, 0xFF, 0x0A, 0xE2, 0x82, 0xAC])
        return machine
    }

    @Test("Layout and window layout files match for every property type", arguments: [Format.c, .objCX].map(\.rawValue))
    func layoutFiles(formatName: String) async throws {
        let format = try #require(Format(rawValue: formatName))
        let machine = Self.makeMachine()
        let directory = try TemplateParity.makeDirectory("layout")
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Layouts.machine")
        try machine.write(to: url, language: try #require(outputLanguage(for: format)), isSuspensible: true)
        let binding = try await TemplateBinding.make(for: machine, named: "Layouts", format: format, isSuspensible: true)
        for fileName in ["Layout.plist", "WindowLayout.plist"] {
            let swift = try Data(contentsOf: url.appendingPathComponent(fileName))
            let template = try #require(binding.files[fileName])
            #expect(template == swift, "\(fileName):\n\(TemplateParity.unifiedDiff(String(decoding: swift, as: UTF8.self), String(decoding: template, as: UTF8.self), from: "swift", to: "template"))")
        }
    }
}
