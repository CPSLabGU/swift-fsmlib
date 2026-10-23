//
//  StructuralToSectionedTests.swift
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

@Suite("Structural to sectioned transformation")
@MainActor
struct StructuralToSectionedTests {
    /// Every example machine and arrangement, with the test resource machine.
    nonisolated static let examples = TemplateParity.machineExamples + TemplateParity.arrangementExamples

    /// The machines of an example bundle, by instance name and machine name.
    private func machines(of example: ParityExample) throws -> [(instance: String, name: String, machine: Machine)] {
        if example.url.pathExtension == TemplateParity.arrangementExtension {
            return try ArrangementWrapper(url: example.url).arrangement.namedInstances.map {
                ($0.name, String($0.typeName), $0.machine)
            }
        }
        return [(example.name, example.name, try Machine(from: example.url))]
    }

    /// The section features of sectioned states and the structural sections they hold.
    private let sections: [(LLFSMFeature, StandardBoilerplateSection)] = [
        (.onEntry, .onEntry), (.onExit, .onExit), (.internal, .internal), (.onSuspend, .onSuspend), (.onResume, .onResume),
    ]

    @Test("every machine keeps its states, sections, labels, declarations and instances", arguments: examples)
    func preservesInformation(_ example: ParityExample) async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let source = try await TransformationTestSupport.structuralResource(for: example.url)
        let result = try await transformations.structuralToSectioned(source, arrangementName: example.name)
        let index = await KernelModelIndex(resource: result.resource)
        let arrangement = try #require(index.roots.first.flatMap(index.object))
        let sectioned = transformations.metamodels.sectioned
        let kernel = sectioned.kernel
        #expect(arrangement.eClass.id == sectioned.arrangementClass.id)
        #expect(arrangement.string(.name) == example.name)
        let expected = try machines(of: example)
        #expect(index.objects(.instances, of: arrangement).map { $0.string(.name) ?? "" } == expected.map(\.instance))
        var machineNames: [String] = []
        for entry in expected where !machineNames.contains(entry.name) { machineNames.append(entry.name) }
        let machineObjects = index.objects(.machines, of: arrangement)
        #expect(machineObjects.map { $0.string(.name) ?? "" } == machineNames)
        for instance in index.objects(.instances, of: arrangement) {
            let name = expected.first { $0.instance == instance.string(.name) }?.name
            #expect(index.target(.machine, of: instance)?.string(.name) == name)
        }
        for machineObject in machineObjects {
            let machine = try #require(expected.first { $0.name == machineObject.string(.name) }?.machine)
            let language = machine.language.name
            #expect(machineObject.string(.language) == language)
            let typer = ExpressionTyper(
                language: language, scope: ExpressionTyper.Scope(machine: machineObject.id, index: index, metamodel: kernel))
            let states = index.objects(.states, of: machineObject)
            #expect(states.map { $0.string(.name) ?? "" } == machine.llfsm.states.compactMap(machine.llfsm.stateName(for:)))
            #expect(machineObject.identifier(.initial) == states.first?.id)
            let suspendName = machine.llfsm.suspendState.flatMap(machine.llfsm.stateName(for:))
            #expect(index.target(.suspendState, of: machineObject)?.string(.name) == suspendName)
            for (stateID, state) in zip(machine.llfsm.states, states) {
                let activities = machine.stateActivities(for: stateID)
                for (feature, section) in sections {
                    let text = activities[section] ?? ""
                    let statements = index.objects(feature, of: state)
                    let place = "\(machineObject.string(.name) ?? "").\(state.string(.name) ?? "").\(feature.rawValue)"
                    if text.isEmpty {
                        #expect(statements.isEmpty, "\(place)")
                    } else if !text.allSatisfy(\.isWhitespace), let typed = typer.typedStatements(from: text) {
                        #expect(statements.count == typed.count, "\(place)")
                        #expect(!statements.contains { $0.eClass.id == kernel.opaqueStatementClass.id }, "\(place)")
                    } else {
                        #expect(statements.count == 1, "\(place)")
                        #expect(statements.first?.eClass.id == kernel.opaqueStatementClass.id, "\(place)")
                        #expect(statements.first?.string(.text) == text, "\(place)")
                        #expect(statements.first?.string(.language) == language, "\(place)")
                    }
                }
                let transitions = machine.llfsm.transitionsFrom(stateID).compactMap(machine.llfsm.transition(for:))
                let transitionObjects = index.objects(.transitions, of: state)
                #expect(transitionObjects.count == transitions.count)
                for (transition, object) in zip(transitions, transitionObjects) {
                    let label = try #require(index.target(.label, of: object))
                    #expect(index.target(.target, of: object)?.string(.name) == machine.llfsm.stateName(for: transition.target))
                    if typer.typedCondition(from: transition.label) != nil {
                        #expect(label.eClass.id != kernel.opaqueExpressionClass.id)
                    } else {
                        #expect(label.eClass.id == kernel.opaqueExpressionClass.id)
                        #expect(label.string(.text) == transition.label)
                        #expect(label.string(.language) == language)
                    }
                }
            }
            try expectDeclarations(of: machine, in: machineObject, index: index, kernel: kernel)
        }
    }

    /// Check that the machine and state boilerplate is kept as host declarations and declared variables.
    private func expectDeclarations(
        of machine: Machine,
        in machineObject: DynamicEObject,
        index: KernelModelIndex,
        kernel: KernelMetamodel
    ) throws {
        let language = machine.language
        let boilerplate = language.extractSections(from: machine.boilerplate)
        let variables = boilerplate[.variables] ?? ""
        let scan = VariableDeclarationScanner(language: language.name).scan(variables)
        let declared = index.objects(.variables, of: machineObject)
        #expect(declared.map { $0.string(.name) ?? "" } == scan.declarations.map(\.name))
        for (variable, (declaration, placement)) in zip(declared, zip(scan.declarations, scan.placements)) {
            #expect(index.target(.type, of: variable)?.string(.name) == declaration.type.name)
            #expect(variable.string(.declarationText) == placement.text)
            #expect(variable.int(.declarationLine) == placement.line)
            #expect(variable.string(.documentation) == placement.documentation)
        }
        func present(_ text: String?) -> String? { (text ?? "").isEmpty ? nil : text }
        func expectHosts(_ hosts: [DynamicEObject], of sections: [StandardBoilerplateSection: String]?,
                         declarations: String?, place: String) {
            let texts: [StandardBoilerplateSection] = [.includePath, .includes, .variables, .functions]
            guard let sections, texts.contains(where: { present(sections[$0]) != nil }) else {
                #expect(hosts.isEmpty, "\(place)")
                return
            }
            #expect(hosts.count == 1, "\(place)")
            let host = hosts.first
            #expect(host?.string(.language) == language.name, "\(place)")
            #expect(host?.string(.includePaths) == present(sections[.includePath]), "\(place)")
            #expect(host?.string(.includes) == present(sections[.includes]), "\(place)")
            #expect(host?.string(.declarations) == declarations, "\(place)")
            #expect(host?.string(.functions) == present(sections[.functions]), "\(place)")
        }
        let remainder = scan.declarations.isEmpty ? present(variables)
            : (scan.remainderLineCount == 0 ? nil : scan.remainder)
        let name = machineObject.string(.name) ?? ""
        expectHosts(index.objects(.hostDeclarations, of: machineObject), of: boilerplate,
                    declarations: remainder, place: name)
        for (stateID, state) in zip(machine.llfsm.states, index.objects(.states, of: machineObject)) {
            let sections = machine.stateBoilerplate[stateID].map { language.extractSections(from: $0) }
            expectHosts(index.objects(.hostDeclarations, of: state), of: sections,
                        declarations: present(sections?[.variables]), place: "\(name).\(state.string(.name) ?? "")")
        }
    }

    @Test("the timed labels of the traffic light type as state-time comparisons")
    func trafficLightTimes() async throws {
        let url = try FSMEcoreTestSupport.trafficLightMachineURL()
        let transformations = try await TransformationTestSupport.transformations()
        let result = try await transformations.structuralToSectioned(
            try await TransformationTestSupport.structuralResource(for: url))
        let index = await KernelModelIndex(resource: result.resource)
        let states = index.order.compactMap(index.object).filter { $0.eClass.id == transformations.metamodels.sectioned.stateClass.id }
        let red = try #require(states.first { $0.string(.name) == "Red" })
        let label = try #require(index.objects(.transitions, of: red).first.flatMap { index.target(.label, of: $0) })
        #expect(label.string(.operation) == KernelBinaryOperation.greaterThan.rawValue)
        let time = try #require(index.target(.left, of: label))
        #expect(time.eClass.id == transformations.metamodels.sectioned.stateTimeExpressionClass.id)
        #expect(time.string(.unit) == SectionedTimeUnit.seconds.rawValue)
        #expect(index.target(.right, of: label)?.int(.value) == 60)
        #expect(result.diagnostics.isEmpty)
    }

    @Test("the counters declare their integer variable, type their plain print and share machines")
    func counterTyping() async throws {
        let url = TemplateParity.examplesDirectory.appendingPathComponent("Counter2.arrangement")
        let transformations = try await TransformationTestSupport.transformations()
        let result = try await transformations.structuralToSectioned(
            try await TransformationTestSupport.structuralResource(for: url), arrangementName: "Counter")
        let variables = await TransformationTestSupport.objects(named: "Variable", in: result.resource)
        #expect(variables.compactMap { $0.string(.name) } == ["counter"])
        let types = await TransformationTestSupport.objects(named: "IntegerType", in: result.resource)
        #expect(types.compactMap { $0.string(.name) } == ["int"])
        #expect(types.first?.int(.lower) == Int(Int32.min))
        let prints = await TransformationTestSupport.objects(named: "Print", in: result.resource)
        #expect(prints.compactMap { $0.string(.text) } == ["Counter suspended."])
        let instances = await TransformationTestSupport.objects(named: "Instance", in: result.resource)
        #expect(instances.compactMap { $0.string(.name) } == ["Susp", "Instance1", "Instance2", "Instance3"])
        let machines = await TransformationTestSupport.objects(named: "Machine", in: result.resource)
        #expect(machines.compactMap { $0.string(.name) } == ["SuspendCounter", "Counter"])
    }

    @Test("the sectioned examples encode into valid kernel models", arguments: examples)
    func encodes(_ example: ParityExample) async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let sectioned = try await transformations.structuralToSectioned(
            try await TransformationTestSupport.structuralResource(for: example.url), arrangementName: example.name)
        guard try !machines(of: example).isEmpty else { return }
        let kernel = try await transformations.sectionedToKernel(sectioned.resource)
        let kernelMetamodel = transformations.metamodels.kernel
        let profile = await TransformationTestSupport.profile(for: kernel.resource, kernel: kernelMetamodel)
        let diagnostics = await KernelValidator(metamodel: kernelMetamodel, profile: profile).validate(kernel.resource)
        #expect(diagnostics.isEmpty, "\(diagnostics)")
    }

    @Test("a model without a structural root is rejected")
    func rejectsOtherModels() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let (_, kernelResource) = try await KernelFixtureTests.load(.turnTakingRelay)
        await #expect(throws: LLFSMTransformationError.missingRoot("Arrangement")) {
            try await transformations.structuralToSectioned(kernelResource)
        }
    }
}
