//
//  RoundTripFidelityTests.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Testing
@testable import FSM
@testable import FSMEcore

/// The information that the sectioned and kernel levels keep for a faithful
/// round trip of structural models.
@Suite("Round-trip fidelity")
@MainActor
struct RoundTripFidelityTests {
    /// The include path of the counter example, as its bundle holds it.
    private func counterIncludePath() throws -> String {
        let machine = try Machine(from: TemplateParity.examplesDirectory.appendingPathComponent("Counter.machine"))
        let includePath = try #require(machine.language.extractSections(from: machine.boilerplate)[.includePath])
        #expect(includePath.contains("\n"))
        return includePath
    }

    /// The state variables of the state `Initial` of the counter example.
    static let initialStateVariables = """
        //
        // State_Initial_Variables.h
        //
        // Automatically created through MiCASE -- do not change manually!
        //
        const char *\tstate_name;\t///< Name of the State

        """

    /// The sectioned model of the counter example machine.
    private func counter() async throws -> (transformations: LLFSMTransformations, sectioned: Resource) {
        let transformations = try await TransformationTestSupport.transformations()
        let url = TemplateParity.examplesDirectory.appendingPathComponent("Counter.machine")
        let source = try await TransformationTestSupport.structuralResource(for: url)
        let sectioned = try await transformations.structuralToSectioned(source, arrangementName: "Counter")
        return (transformations, sectioned.resource)
    }

    /// The only object of a class in a resource.
    private func only(_ className: String, named name: String, in resource: Resource) async throws -> DynamicEObject {
        let objects = await TransformationTestSupport.objects(named: className, in: resource)
        return try #require(objects.first { $0.string(.name) == name })
    }

    /// Checks that include paths and functions are carried to the kernel and back.
    ///
    /// - Throws: Any error raised by the transformations.
    @Test("include paths and functions are carried to the kernel and back")
    func includePathsAndFunctions() async throws {
        let (transformations, sectioned) = try await counter()
        let includePath = try counterIncludePath()
        var index = await KernelModelIndex(resource: sectioned)
        let machine = try await only("Machine", named: "Counter", in: sectioned)
        let host = try #require(index.objects(.hostDeclarations, of: machine).first)
        #expect(index.objects(.hostDeclarations, of: machine).count == 1)
        #expect(host.string(.includePaths) == includePath)
        #expect(host.string(.includes) == "#include <stdio.h>\n")
        #expect(host.string(.functions) == "\n")
        let kernel = try await transformations.sectionedToKernel(sectioned)
        let kernelMachine = try await only("Machine", named: "Counter", in: kernel.resource)
        index = await KernelModelIndex(resource: kernel.resource)
        let kernelHost = try #require(index.objects(.hostDeclarations, of: kernelMachine).first)
        #expect(kernelHost.string(.includePaths) == includePath)
        #expect(kernelHost.string(.functions) == "\n")
        let rebuilt = try await transformations.kernelToSectioned(kernel.resource)
        let rebuiltMachine = try await only("Machine", named: "Counter", in: rebuilt.resource)
        index = await KernelModelIndex(resource: rebuilt.resource)
        let rebuiltHost = try #require(index.objects(.hostDeclarations, of: rebuiltMachine).first)
        #expect(rebuiltHost.string(.includePaths) == includePath)
        #expect(rebuiltHost.string(.functions) == "\n")
        let structural = try await transformations.sectionedToStructural(sectioned)
        guard case .machine(_, let decoded) = try await StructuralRoundTrip.decode(structural.resource) else {
            Issue.record("The counter did not come back as a machine")
            return
        }
        let sections = decoded.language.extractSections(from: decoded.boilerplate)
        #expect(sections[.includePath] == includePath)
        #expect(sections[.functions] == "\n")
        #expect(!structural.diagnostics.warnings.map(\.kind).contains(.notRecovered(.includePath, owner: "Counter")))
    }

    /// Checks that state boilerplate becomes host declarations of the state, which the kernel merges into the machine.
    ///
    /// - Throws: Any error raised by the transformations.
    @Test("state boilerplate becomes host declarations of the state, which the kernel merges into the machine")
    func stateHostDeclarations() async throws {
        let (transformations, sectioned) = try await counter()
        var index = await KernelModelIndex(resource: sectioned)
        let initial = try await only("State", named: "Initial", in: sectioned)
        let hosts = index.objects(.hostDeclarations, of: initial)
        #expect(hosts.count == 1)
        #expect(hosts.first?.string(.declarations) == Self.initialStateVariables)
        #expect(hosts.first?.string(.includes) == "\n")
        #expect(hosts.first?.string(.functions) == "\n")
        let machine = try await only("Machine", named: "Counter", in: sectioned)
        let stateHosts = index.objects(.states, of: machine).flatMap { index.objects(.hostDeclarations, of: $0) }
        let kernel = try await transformations.sectionedToKernel(sectioned)
        #expect(kernel.diagnostics.warnings.map(\.kind).contains(.notRecovered(.stateBoilerplate, owner: "Counter")))
        let kernelMachine = try await only("Machine", named: "Counter", in: kernel.resource)
        index = await KernelModelIndex(resource: kernel.resource)
        let kernelHosts = index.objects(.hostDeclarations, of: kernelMachine)
        #expect(kernelHosts.count == 1 + stateHosts.count)
        #expect(kernelHosts.dropFirst().map { $0.string(.declarations) } == stateHosts.map { $0.string(.declarations) })
        let structural = try await transformations.kernelToStructural(kernel.resource)
        #expect(structural.diagnostics.warnings.map(\.kind).contains(.notRecovered(.stateBoilerplate, owner: "Counter")))
    }

    /// Checks that recognised declarations keep their comment, text and line through the kernel.
    ///
    /// - Throws: Any error raised by the transformations.
    @Test("recognised declarations keep their comment, text and line through the kernel")
    func declarationTexts() async throws {
        let (transformations, sectioned) = try await counter()
        let variable = try await only("Variable", named: "counter", in: sectioned)
        #expect(variable.string(.documentation) == "Bean counter")
        #expect(variable.string(.declarationText) == "int\tcounter;\t///< Bean counter")
        #expect(variable.int(.declarationLine) == 6)
        let kernel = try await transformations.sectionedToKernel(sectioned)
        let rebuilt = try await transformations.kernelToSectioned(kernel.resource)
        for resource in [kernel.resource, rebuilt.resource] {
            let copy = try await only("Variable", named: "counter", in: resource)
            #expect(copy.string(.documentation) == "Bean counter")
            #expect(copy.string(.declarationText) == "int\tcounter;\t///< Bean counter")
            #expect(copy.int(.declarationLine) == 6)
        }
    }

    /// A sectioned C machine with one variable, its declaration text and host declarations in a language.
    private func declaredSample(hostLanguage: String) async throws -> Resource {
        let builder = try await KernelModelBuilder.make()
        let system = builder.sectionedArrangement("Declared")
        let int = builder.integerType("int", HostSyntax.intRange, in: system)
        let machine = builder.sectionedMachine("Declared", in: system)
        builder.set(machine, .language, "c")
        let count = builder.variable("count", int, in: machine)
        builder.set(count, .declarationText, "int  count; ///< kept")
        builder.set(count, .declarationLine, 1)
        builder.variable("other", int, in: machine)
        builder.hostDeclarations(in: machine, language: hostLanguage, includes: "", declarations: "// first\n// last\n")
        let state = builder.sectionedState("Only", in: machine)
        builder.set(machine, .initial, state)
        builder.sectionedInstance("Declared", of: machine, in: system)
        return await builder.resource()
    }

    /// Checks that declaration texts are put back at their line and other variables follow in canonical form.
    ///
    /// - Throws: Any error raised by the transformations.
    @Test("declaration texts are put back at their line, other variables follow in canonical form")
    func mergedDeclarations() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let result = try await transformations.sectionedToStructural(try await declaredSample(hostLanguage: "c"))
        let arrangement = try #require(try await StructuralRoundTrip.decode(result.resource).arrangementValue)
        let machine = try #require(arrangement.namedInstances.first?.machine)
        #expect(machine.language.extractSections(from: machine.boilerplate)[.variables]
            == "// first\nint  count; ///< kept\n// last\nint\tother;\n")
        #expect(result.diagnostics.warnings.map(\.kind).contains(.notRecovered(.declarationFormatting, owner: "Declared")))
    }

    /// Checks that declaration texts held by host declarations of another language are written in canonical form.
    ///
    /// - Throws: Any error raised by the transformations.
    @Test("declaration texts held by host declarations of another language are written in canonical form")
    func otherLanguageDeclarations() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let result = try await transformations.sectionedToStructural(try await declaredSample(hostLanguage: "swift"))
        let arrangement = try #require(try await StructuralRoundTrip.decode(result.resource).arrangementValue)
        let machine = try #require(arrangement.namedInstances.first?.machine)
        #expect(machine.language.extractSections(from: machine.boilerplate)[.variables]
            == "// first\n// last\nint\tcount;\nint\tother;\n")
        #expect(result.diagnostics.warnings.map(\.kind).contains(.notRecovered(.declarationFormatting, owner: "Declared")))
    }

    /// A sectioned C machine whose state has a self loop and, optionally, sections of only white space.
    private func blankSample(withBlankSections: Bool) async throws -> Resource {
        let builder = try await KernelModelBuilder.make()
        let system = builder.sectionedArrangement("Blank")
        builder.set(system, .language, "c")
        let machine = builder.sectionedMachine("Blank", in: system)
        builder.set(machine, .language, "c")
        let state = builder.sectionedState("Only", in: machine)
        let other = builder.sectionedState("Other", in: machine)
        builder.set(machine, .initial, state)
        if withBlankSections {
            builder.section(.internal, of: state, builder.opaqueStatement("\n"))
            builder.section(.onExit, of: state, builder.opaqueStatement(" \t\n"))
            builder.section(.onEntry, of: other, builder.opaqueStatement("\n\n"))
        }
        builder.sectionedTransition(from: state, to: other, when: builder.opaqueExpression(" "))
        builder.sectionedTransition(from: other, to: state, when: builder.bool(true))
        builder.sectionedInstance("Blank", of: machine, in: system)
        return await builder.resource()
    }

    /// Checks that sections and labels of only white space stay opaque with their exact text.
    ///
    /// - Throws: Any error raised by the transformations.
    @Test("sections and labels of only white space stay opaque with their exact text")
    func whiteSpace() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let structural = try await transformations.sectionedToStructural(try await blankSample(withBlankSections: true))
        guard case .machine(_, let machine) = try await StructuralRoundTrip.decode(structural.resource) else {
            Issue.record("The sample did not come back as a machine")
            return
        }
        let states = machine.llfsm.states
        #expect(machine.stateActivities(for: states[0])[.internal] == "\n")
        #expect(machine.stateActivities(for: states[0])[.onExit] == " \t\n")
        #expect(machine.stateActivities(for: states[1])[.onEntry] == "\n\n")
        #expect(machine.llfsm.transitions.compactMap(machine.llfsm.label(for:)) == [" ", "true"])
        let sectioned = try await transformations.structuralToSectioned(structural.resource, arrangementName: "Blank")
        let index = await KernelModelIndex(resource: sectioned.resource)
        let only = try await only("State", named: "Only", in: sectioned.resource)
        let kernel = transformations.metamodels.kernel
        for (feature, text) in [(LLFSMFeature.internal, "\n"), (.onExit, " \t\n")] {
            let statements = index.objects(feature, of: only)
            #expect(statements.count == 1)
            #expect(statements.first?.eClass.id == kernel.opaqueStatementClass.id)
            #expect(statements.first?.string(.text) == text)
        }
        let label = try #require(index.objects(.transitions, of: only).first.flatMap { index.target(.label, of: $0) })
        #expect(label.eClass.id == kernel.opaqueExpressionClass.id)
        #expect(label.string(.text) == " ")
    }

    /// Checks that a label of only white space is a valid opaque label of the relaxed profile.
    ///
    /// - Throws: Any error raised by the transformations.
    @Test("a label of only white space is a valid opaque label of the relaxed profile")
    func whiteSpaceLabel() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let encoded = try await transformations.sectionedToKernel(try await blankSample(withBlankSections: true))
        let kernel = transformations.metamodels.kernel
        let diagnostics = await KernelValidator(metamodel: kernel, profile: .relaxed).validate(encoded.resource)
        #expect(diagnostics.isEmpty, "\(diagnostics)")
        let labels = await TransformationTestSupport.objects(named: "OpaqueExpression", in: encoded.resource)
        #expect(labels.map { $0.string(.text) } == [" "])
    }

    /// Checks that the encoding leaves out opaque statements of only white space.
    ///
    /// - Parameter elides: Whether the encoding elides empty sections.
    /// - Throws: Any error raised by the transformations.
    @Test("the encoding leaves out opaque statements of only white space", arguments: [true, false])
    func blankStatementsElided(_ elides: Bool) async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let options = SectionedToKernelOptions(elideEmptySections: elides)
        let blank = try await transformations.sectionedToKernel(
            try await blankSample(withBlankSections: true), options: options)
        let plain = try await transformations.sectionedToKernel(
            try await blankSample(withBlankSections: false), options: options)
        #expect(await ModelDump.text(of: blank.resource) == ModelDump.text(of: plain.resource))
        #expect(await TransformationTestSupport.objects(named: "OpaqueStatement", in: blank.resource).isEmpty)
    }
}

/// Convenience access to the arrangement of a structural round-trip model.
private extension StructuralRoundTrip.Model {
    /// The arrangement of an arrangement model, or `nil` for a single machine.
    var arrangementValue: Arrangement? {
        if case .arrangement(let arrangement) = self { return arrangement }
        return nil
    }
}
