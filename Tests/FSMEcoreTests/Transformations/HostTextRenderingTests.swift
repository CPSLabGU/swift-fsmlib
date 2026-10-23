//
//  HostTextRenderingTests.swift
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

/// The host text of a sample machine in one language.
struct HostTextSample: CustomTestStringConvertible, Sendable {
    /// The language of the machine.
    let language: String
    /// The labels of the transitions, in order.
    let labels: [String]
    /// The entry section of the first state.
    let entry: String
    /// The internal section of the first state.
    let `internal`: String
    /// The variables of the machine boilerplate.
    let variables: String

    var testDescription: String { language }

    /// The samples of every language family.
    static let all: [HostTextSample] = [
        HostTextSample(
            language: "c",
            labels: ["after(60)", "after_ms(100)", "timeout(4)", "!after(2)", "count < 3 && flag",
                     "(count + 1) * 2 == 4 || !flag", "flag ? count > 1 : count < 1", "Mode_on == mode"],
            entry: "count = 1;\nputs(\"go 100% \\\"done\\\"\");\nSUSPEND(&static_fsm_main);\nfflush(stdout);\n",
            internal: "printf(\"walking %s %d\\n\", flag ? \"true\" : \"false\", count);\n",
            variables: "Count\tcount;\nBool\tflag;\nMode\tmode;\n"),
        HostTextSample(
            language: "objc++",
            labels: ["after(60)", "after_ms(100)", "timeout(4)", "!after(2)", "count < 3 && flag",
                     "(count + 1) * 2 == 4 || !flag", "flag ? count > 1 : count < 1", "Mode::on == mode"],
            entry: "count = 1;\nputs(\"go 100% \\\"done\\\"\");\nsuspend_at(0);\nfflush(stdout);\n",
            internal: "printf(\"walking %s %d\\n\", flag ? \"true\" : \"false\", count);\n",
            variables: "Count\tcount;\nBool\tflag;\nMode\tmode;\n"),
        HostTextSample(
            language: "swift",
            labels: ["after(60)", "after_ms(100)", "timeout(4)", "!after(2)", "count < 3 && flag",
                     "(count + 1) * 2 == 4 || !flag", "flag ? count > 1 : count < 1", "Mode.on == mode"],
            entry: "count = 1\nprint(\"go 100% \\\"done\\\"\")\nsuspend(main)\nfflush(stdout);\n",
            internal: "print(\"walking\", flag, count)\n",
            variables: "var count: Count\nvar flag: Bool\nvar mode: Mode\n"),
        HostTextSample(
            language: "java",
            labels: ["after(60)", "after_ms(100)", "timeout(4)", "!after(2)", "count < 3 && flag",
                     "(count + 1) * 2 == 4 || !flag", "flag ? count > 1 : count < 1", "Mode.on == mode"],
            entry: "count = 1;\nSystem.out.println(\"go 100% \\\"done\\\"\");\nsuspend(main);\nfflush(stdout);\n",
            internal: "System.out.println(\"walking\" + \" \" + flag + \" \" + count);\n",
            variables: "int count;\nboolean flag;\nMode mode;\n"),
    ]
}

@Suite("Host text rendering")
@MainActor
struct HostTextRenderingTests {
    /// A sectioned arrangement with one machine in a language, whose labels and sections are typed.
    private func sample(language: String) async throws -> Resource {
        let builder = try await KernelModelBuilder.make()
        let system = builder.sectionedArrangement("Sample")
        let flagType = builder.booleanType(in: system)
        let countType = builder.integerType("Count", 0...9, in: system)
        let modeType = builder.enumerationType("Mode", ["on", "off"], in: system)
        let machine = builder.sectionedMachine("Sampler", in: system)
        builder.set(machine, .language, language)
        let count = builder.variable("count", countType, in: machine)
        let flag = builder.variable("flag", flagType, in: machine)
        let mode = builder.variable("mode", modeType, in: machine)
        let first = builder.sectionedState("First", in: machine)
        let second = builder.sectionedState("Second", in: machine)
        builder.set(machine, .initial, first)
        let instance = builder.sectionedInstance("main", of: machine, in: system)
        builder.section(.onEntry, of: first,
                        builder.assign(builder.ref(count), builder.int(1)),
                        builder.printLine("go 100% \"done\""),
                        builder.control(.suspend, instance),
                        builder.opaqueStatement("fflush(stdout);"))
        builder.section(.internal, of: first, builder.printLine("walking", [builder.ref(flag), builder.ref(count)]))
        let labels = [
            builder.binary(.greaterThan, builder.stateTime(.seconds), builder.int(60)),
            builder.binary(.lessThan, builder.int(100), builder.stateTime(.milliseconds)),
            builder.binary(.greaterOrEqual, builder.stateTime(.microseconds), builder.int(5)),
            builder.binary(.lessThan, builder.stateTime(.seconds), builder.int(3)),
            builder.binary(.conjunction, builder.binary(.lessThan, builder.ref(count), builder.int(3)), builder.ref(flag)),
            builder.binary(.disjunction,
                           builder.binary(.equal,
                                          builder.binary(.multiplication,
                                                         builder.binary(.addition, builder.ref(count), builder.int(1)),
                                                         builder.int(2)),
                                          builder.int(4)),
                           builder.unary(.negation, builder.ref(flag))),
            builder.conditional(builder.ref(flag), builder.binary(.greaterThan, builder.ref(count), builder.int(1)),
                                builder.binary(.lessThan, builder.ref(count), builder.int(1))),
            builder.binary(.equal, builder.literal("on", of: modeType), builder.ref(mode)),
        ]
        for label in labels { builder.sectionedTransition(from: first, to: second, when: label) }
        return await builder.resource()
    }

    @Test("typed labels, sections and declarations are written in the syntax of the language",
          arguments: HostTextSample.all)
    func rendering(_ expected: HostTextSample) async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let result = try await transformations.sectionedToStructural(try await sample(language: expected.language))
        guard case .arrangement(let arrangement) = try await StructuralRoundTrip.decode(result.resource),
              let machine = arrangement.namedInstances.first?.machine else {
            Issue.record("The sample did not come back as an arrangement")
            return
        }
        #expect(machine.language.name == languageBinding(for: expected.language).name)
        #expect(machine.llfsm.transitions.compactMap(machine.llfsm.label(for:)) == expected.labels)
        let first = try #require(machine.llfsm.states.first)
        let activities = machine.stateActivities(for: first)
        #expect(activities[.onEntry] == expected.entry)
        #expect(activities[.internal] == expected.internal)
        #expect(machine.language.extractSections(from: machine.boilerplate)[.variables] == expected.variables)
        #expect(result.diagnostics.warnings.map(\.kind) == [
            .notRecovered(.includePath, owner: "Sampler"), .notRecovered(.layout, owner: "Sampler"),
            .notRecovered(.declarationFormatting, owner: "Sampler"),
        ])
    }

    @Test("the C text of typed labels and sections types back to the same nodes")
    func typesBack() async throws {
        let builder = try await KernelModelBuilder.make()
        let system = builder.sectionedArrangement("Typed")
        let int = builder.integerType("int", HostSyntax.intRange, in: system)
        let bool = builder.booleanType("bool", in: system)
        let machine = builder.sectionedMachine("Typed", in: system)
        builder.set(machine, .language, "c")
        let count = builder.variable("count", int, in: machine)
        let flag = builder.variable("flag", bool, in: machine)
        let state = builder.sectionedState("Only", in: machine)
        builder.set(machine, .initial, state)
        builder.sectionedInstance("main", of: machine, in: system)
        builder.section(.onEntry, of: state, builder.assign(builder.ref(count), builder.int(1)),
                        builder.printLine("go 100%"), builder.printLine("done"))
        let labels = [
            builder.binary(.greaterThan, builder.stateTime(.seconds), builder.int(60)),
            builder.binary(.greaterThan, builder.stateTime(.milliseconds), builder.int(100)),
            builder.binary(.conjunction, builder.binary(.lessThan, builder.ref(count), builder.int(3)), builder.ref(flag)),
            builder.binary(.subtraction, builder.ref(count),
                           builder.binary(.subtraction, builder.int(1), builder.int(2))),
            builder.conditional(builder.ref(flag), builder.binary(.greaterThan, builder.ref(count), builder.int(1)),
                                builder.binary(.lessThan, builder.ref(count), builder.int(1))),
        ]
        for label in labels.dropLast(2) { builder.sectionedTransition(from: state, to: state, when: label) }
        builder.sectionedTransition(
            from: state, to: state, when: builder.binary(.greaterThan, labels[3], builder.int(0)))
        builder.sectionedTransition(from: state, to: state, when: labels[4])
        let source = await builder.resource()
        let transformations = try await TransformationTestSupport.transformations()
        let structural = try await transformations.sectionedToStructural(source)
        let sectioned = try await transformations.structuralToSectioned(structural.resource, arrangementName: "Typed")
        func dump(_ resource: Resource) async -> [String] {
            await ModelDump.text(of: resource).split(separator: "\n").map(String.init)
                .filter { $0.contains("/states[") }
        }
        let rebuilt = await dump(sectioned.resource)
        let original = await dump(source)
        #expect(rebuilt == original, "\(Set(rebuilt).symmetricDifference(original).sorted())")
    }

    @Test("typed nodes of a language that no module writes stop the transformation")
    func unsupportedLanguage() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let source = try await sample(language: "cobol")
        await #expect(throws: LLFSMTransformationError.self) {
            try await transformations.sectionedToStructural(source)
        }
    }

    @Test("opaque text of a language that no module writes is kept byte for byte")
    func opaqueOnly() async throws {
        let builder = try await KernelModelBuilder.make()
        let system = builder.sectionedArrangement("Opaque")
        builder.set(system, .language, "cobol")
        let machine = builder.sectionedMachine("Opaque", in: system)
        let state = builder.sectionedState("Only", in: machine)
        builder.set(machine, .initial, state)
        builder.section(.onEntry, of: state, builder.opaqueStatement("  DISPLAY 'HI'.\n\n"))
        builder.sectionedTransition(from: state, to: state, when: builder.opaqueExpression(" X > 1 "))
        builder.sectionedInstance("Opaque", of: machine, in: system)
        let transformations = try await TransformationTestSupport.transformations()
        let result = try await transformations.sectionedToStructural(await builder.resource())
        guard case .machine(let name, let decoded) = try await StructuralRoundTrip.decode(result.resource) else {
            Issue.record("The standalone arrangement did not come back as a machine")
            return
        }
        #expect(name == "Opaque")
        #expect(decoded.llfsm.transitions.compactMap(decoded.llfsm.label(for:)) == [" X > 1 "])
        let only = try #require(decoded.llfsm.states.first)
        #expect(decoded.stateActivities(for: only)[.onEntry] == "  DISPLAY 'HI'.\n\n")
    }

    @Test("kernel models of the fresh sectioned fixtures become structural machines",
          arguments: [SectionedSample.sectionedCrossing, .suspendResumeSampler])
    func kernelChain(_ sample: SectionedSample) async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let kernel = try await transformations.sectionedToKernel(try await sample.resource())
        let result = try await transformations.kernelToStructural(kernel.resource)
        guard case .arrangement(let arrangement) = try await StructuralRoundTrip.decode(result.resource) else {
            Issue.record("The fixture did not come back as an arrangement")
            return
        }
        var labels: [String] = []
        var sections: [String: String] = [:]
        for instance in arrangement.namedInstances {
            let machine = instance.machine
            #expect(machine.language.name == LLFSMTransformations.defaultLanguage)
            labels += machine.llfsm.transitions.compactMap(machine.llfsm.label(for:))
            for state in machine.llfsm.states {
                let name = machine.llfsm.stateName(for: state) ?? ""
                for (section, text) in machine.stateActivities(for: state) where !text.isEmpty {
                    sections["\(name).\(section.rawValue)"] = text
                }
            }
        }
        switch sample {
        case .sectionedCrossing:
            #expect(arrangement.namedInstances.map(\.name) == ["main"])
            #expect(labels == ["request", "after(2)", "after(4)"])
            #expect(sections["Go.onEntry"] == "walkLit = false;\nprintf(\"go\\n\");\n")
            #expect(sections["Stop.internal"] == "printf(\"walking %s\\n\", walkLit ? \"true\" : \"false\");\n")
            #expect(result.diagnostics.warnings.map(\.kind) == [
                .notRecovered(.includePath, owner: "Crossing"), .notRecovered(.layout, owner: "Crossing"),
                .notRecovered(.declarationFormatting, owner: "Crossing"),
                .notRecovered(.sharedDeclarations, owner: "SectionedCrossing"),
            ])
        default:
            #expect(arrangement.namedInstances.map(\.name) == ["worker", "supervisor"])
            #expect(labels == ["after_ms(100)", "samples >= 100", "pauseRequested",
                               "!pauseRequested && in_state(worker, Suspended)"])
            #expect(sections["Sampling.internal"] == "printf(\"sampling %d\\n\", samples);\n")
            #expect(sections["Holding.onEntry"] == "SUSPEND(&static_fsm_worker);\n")
            #expect(sections["Holding.onExit"] == "RESUME(&static_fsm_worker);\n")
            #expect(result.diagnostics.warnings.map(\.kind) == [
                .notRecovered(.includePath, owner: "Sampler"), .notRecovered(.layout, owner: "Sampler"),
                .notRecovered(.includePath, owner: "Supervisor"), .notRecovered(.layout, owner: "Supervisor"),
                .notRecovered(.sharedDeclarations, owner: "SuspendResumeSampler"),
            ])
        }
    }
}
