//
//  KernelValidatorTests.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Testing
@testable import FSMEcore

/// A small, well-formed kernel model that the rule tests modify.
///
/// The arrangement `Mini` declares a Boolean type, an integer type `Count`
/// with range 0...9, a signed integer type `Delta` with range -3...3, an
/// enumeration `Mode` and an array type `Pair` of two Booleans. It shares a
/// variable `x` of type `Count` and an external Boolean `sensor`. Machine `M`
/// has a local `y` of type `Count`, an initial state `A` and a state `B`;
/// `A` moves to `B` when `sensor` holds and `B` returns to `A`. Instance `i`
/// runs `M`.
struct MiniModel {
    /// The builder that owns the model objects.
    let builder: KernelModelBuilder
    /// The root arrangement.
    let arrangement: EUUID
    /// The Boolean type.
    let flag: EUUID
    /// The integer type `Count` with range 0...9.
    let count: EUUID
    /// The signed integer type `Delta` with range -3...3.
    let delta: EUUID
    /// The enumeration type `Mode`.
    let mode: EUUID
    /// The array type `Pair` of two Booleans.
    let pair: EUUID
    /// The shared variable `x` of type `Count`.
    let x: EUUID
    /// The external Boolean variable `sensor`.
    let sensor: EUUID
    /// The machine `M`.
    let machine: EUUID
    /// The local variable `y` of machine `M`.
    let y: EUUID
    /// The initial state `A`.
    let a: EUUID
    /// The state `B`.
    let b: EUUID
    /// The transition from `A` to `B`.
    let toB: EUUID
    /// The transition from `B` to `A`.
    let toA: EUUID
    /// The instance `i` that runs machine `M`.
    let instance: EUUID

    /// Builds the well-formed model.
    ///
    /// - Throws: An error if the kernel metamodel cannot be loaded.
    init() async throws {
        let builder = try await KernelModelBuilder.make()
        self.builder = builder
        arrangement = builder.arrangement("Mini")
        flag = builder.booleanType(in: arrangement)
        count = builder.integerType("Count", 0...9, in: arrangement)
        delta = builder.integerType("Delta", -3...3, in: arrangement)
        mode = builder.enumerationType("Mode", ["on", "off"], in: arrangement)
        pair = builder.arrayType("Pair", of: flag, size: 2, in: arrangement)
        x = builder.variable("x", count, in: arrangement)
        sensor = builder.variable("sensor", flag, in: arrangement, external: true)
        machine = builder.machine("M", in: arrangement)
        y = builder.variable("y", count, in: machine)
        a = builder.state("A", in: machine)
        b = builder.state("B", in: machine)
        builder.initial(a, of: machine)
        toB = builder.transition(from: a, to: b, when: builder.ref(sensor))
        toA = builder.transition(from: b, to: a, when: builder.bool(true))
        instance = builder.instance("i", of: machine, in: arrangement)
    }

    /// Validate the model under a profile.
    ///
    /// - Parameter profile: The validation profile to apply.
    /// - Returns: The diagnostics reported for the model.
    func validate(_ profile: ValidationProfile = .strict) async -> [KernelDiagnostic] {
        let resource = await builder.resource()
        return await KernelValidator(metamodel: builder.kernel, profile: profile).validate(resource)
    }

    /// The rule codes reported under a profile, in order.
    ///
    /// - Parameter profile: The validation profile to apply.
    /// - Returns: The code of each reported diagnostic.
    func codes(_ profile: ValidationProfile = .strict) async -> [String] {
        await validate(profile).map(\.code)
    }

    /// Replace the label of transition `A → B`.
    ///
    /// - Parameter expression: The expression that becomes the new label.
    func label(_ expression: EUUID) {
        builder.set(toB, .label, expression)
    }
}

/// Tests for the kernel validator: structure.
@Suite("Kernel validator: structure")
struct KernelValidatorStructureTests {
    /// The unmodified model is valid under both profiles.
    @Test("the unmodified model is valid under both profiles")
    func validModel() async throws {
        let model = try await MiniModel()
        #expect(await model.validate(.strict).isEmpty)
        #expect(await model.validate(.relaxed).isEmpty)
    }

    /// A missing mandatory attribute or reference is reported.
    @Test("a missing mandatory attribute or reference is reported")
    func missingMandatoryFeatures() async throws {
        let model = try await MiniModel()
        model.builder.unset(model.b, .name)
        model.builder.unset(model.toA, .label)
        let diagnostics = await model.validate()
        #expect(diagnostics.map(\.code) == ["STRUCT", "STRUCT"])
        #expect(diagnostics.allSatisfy { $0.message.contains("mandatory") })
    }

    /// An arrangement without instances violates the lower bound.
    @Test("an arrangement without instances violates the lower bound")
    func missingInstances() async throws {
        let model = try await MiniModel()
        model.builder.unset(model.arrangement, .instances)
        #expect(await model.codes() == ["STRUCT"])
    }

    /// An unresolved reference is reported.
    @Test("an unresolved reference is reported")
    func unresolvedReference() async throws {
        let model = try await MiniModel()
        model.builder.set(model.toA, .target, EUUID())
        let diagnostics = await model.validate()
        #expect(diagnostics.map(\.code) == ["STRUCT"])
        #expect(diagnostics.first?.message.contains("does not resolve") == true)
    }

    /// A reference to an object of the wrong class is reported.
    @Test("a reference to an object of the wrong class is reported")
    func wrongReferenceClass() async throws {
        let model = try await MiniModel()
        model.builder.set(model.toA, .target, model.y)
        #expect(await model.codes().contains("STRUCT"))
    }

    /// An unknown enumeration literal is reported.
    @Test("an unknown enumeration literal is reported")
    func unknownLiteral() async throws {
        let model = try await MiniModel()
        let expression = model.builder.binary(.conjunction, model.builder.bool(true), model.builder.bool(true))
        model.builder.set(expression, .operation, "exclusiveOr")
        model.label(expression)
        #expect(await model.codes() == ["STRUCT"])
    }

    /// A transition to a state of another machine is reported.
    @Test("a transition to a state of another machine is reported")
    func foreignTarget() async throws {
        let model = try await MiniModel()
        let other = model.builder.machine("N", in: model.arrangement)
        let c = model.builder.state("C", in: other)
        model.builder.initial(c, of: other)
        model.builder.set(model.toA, .target, c)
        let diagnostics = await model.validate()
        #expect(diagnostics.map(\.code) == ["STRUCT"])
        #expect(diagnostics.first?.path == "/Mini/machines[M]/states[B]/transitions[0]")
    }

    /// A binding must name a local variable of the instance's machine.
    @Test("a binding must name a local variable of the instance's machine")
    func bindingToSharedVariable() async throws {
        let model = try await MiniModel()
        model.builder.binding(model.y, to: model.builder.int(4), for: model.instance)
        #expect(await model.validate().isEmpty)
        model.builder.binding(model.x, to: model.builder.int(4), for: model.instance)
        #expect(await model.codes() == ["STRUCT"])
    }

    /// A root that is not an arrangement is reported.
    @Test("a root that is not an arrangement is reported")
    func rootNotArrangement() async throws {
        let builder = try await KernelModelBuilder.make()
        let state = builder.make(builder.kernel.stateClass, [(.name, "Alone")])
        let resourceSet = ResourceSet()
        await builder.kernel.register(in: resourceSet)
        let resource = await resourceSet.createResource(uri: "memory:/alone.xmi")
        if let object = builder.objects[state] { await resource.add(object) }
        let diagnostics = await KernelValidator(metamodel: builder.kernel).validate(resource)
        #expect(diagnostics.map(\.code) == ["STRUCT"])
        #expect(diagnostics.first?.path == "/Alone")
    }

    /// Diagnostics render severity, code, path and message.
    @Test("diagnostics render severity, code, path and message")
    func diagnosticDescription() {
        let diagnostic = KernelDiagnostic(rule: .unprovenDivisor, severity: .warning, path: "/P", message: "M")
        #expect(diagnostic.description == "warning W7? /P: M")
        #expect(KernelValidator.containsErrors([diagnostic]) == false)
        #expect(KernelValidator.containsErrors([
            KernelDiagnostic(rule: .names, severity: .error, path: "/P", message: "M"),
        ]))
    }
}

/// Tests for the kernel validator: names, initial states, pass-through cycles and externals.
@Suite("Kernel validator: names, initial states, pass-through cycles and externals")
struct KernelValidatorRuleW1toW4Tests {
    /// W1: names must be unique within one containment feature.
    @Test("W1: names must be unique within one containment feature")
    func duplicateNames() async throws {
        let model = try await MiniModel()
        model.builder.state("A", in: model.machine)
        let diagnostics = await model.validate()
        #expect(diagnostics.map(\.code) == ["W1"])
        #expect(diagnostics.first?.path == "/Mini/machines[M]/states[A]")
    }

    /// W1: equal names in different containment features are allowed.
    @Test("W1: equal names in different containment features are allowed")
    func equalNamesInDifferentFeatures() async throws {
        let model = try await MiniModel()
        model.builder.variable("Count", model.count, in: model.arrangement)
        #expect(await model.validate().isEmpty)
    }

    /// W1: names must be identifiers.
    ///
    /// - Parameter name: The candidate name placed on state `B`.
    @Test("W1: names must be identifiers", arguments: ["2fast", "with space", "", "dash-ed", "ümlaut"])
    func invalidNames(_ name: String) async throws {
        let model = try await MiniModel()
        model.builder.set(model.b, .name, name)
        #expect(await model.codes() == ["W1"])
    }

    /// W1: identifiers may start with an underscore and contain digits.
    @Test("W1: identifiers may start with an underscore and contain digits")
    func validIdentifiers() async throws {
        let model = try await MiniModel()
        model.builder.set(model.b, .name, "_b2")
        #expect(await model.validate().isEmpty)
    }

    /// W1: enumeration literals must be unique.
    @Test("W1: enumeration literals must be unique")
    func duplicateLiterals() async throws {
        let model = try await MiniModel()
        model.builder.set(model.mode, .literals, ["on", "off", "on"])
        #expect(await model.codes() == ["W1"])
    }

    /// W2: the initial state must belong to the machine.
    @Test("W2: the initial state must belong to the machine")
    func initialStateOfOtherMachine() async throws {
        let model = try await MiniModel()
        let other = model.builder.machine("N", in: model.arrangement)
        let c = model.builder.state("C", in: other)
        model.builder.initial(c, of: other)
        model.builder.initial(c, of: model.machine)
        #expect(await model.codes() == ["W2"])
    }

    /// W2: the initial state must not be pass-through.
    @Test("W2: the initial state must not be pass-through")
    func passThroughInitialState() async throws {
        let model = try await MiniModel()
        model.builder.set(model.a, .passThrough, true)
        #expect(await model.codes() == ["W2"])
    }

    /// W3: transitions between pass-through states must not form a cycle.
    @Test("W3: transitions between pass-through states must not form a cycle")
    func passThroughCycle() async throws {
        let model = try await MiniModel()
        let p = model.builder.state("P", in: model.machine, passThrough: true)
        let q = model.builder.state("Q", in: model.machine, passThrough: true)
        model.builder.transition(from: p, to: q, when: model.builder.bool(true))
        model.builder.transition(from: q, to: p, when: model.builder.bool(true))
        model.builder.set(model.toA, .target, p)
        let diagnostics = await model.validate()
        #expect(diagnostics.map(\.code) == ["W3"])
        #expect(diagnostics.first?.message.contains("'P' → 'Q' → 'P'") == true)
    }

    /// W3: a pass-through state may loop back to itself only through a resting state.
    @Test("W3: a pass-through state may loop back to itself only through a resting state")
    func acyclicPassThroughChain() async throws {
        let model = try await MiniModel()
        let p = model.builder.state("P", in: model.machine, passThrough: true)
        let q = model.builder.state("Q", in: model.machine, passThrough: true)
        model.builder.transition(from: p, to: q, when: model.builder.bool(true))
        model.builder.transition(from: q, to: model.a, when: model.builder.bool(true))
        model.builder.set(model.toA, .target, p)
        #expect(await model.validate().isEmpty)
    }

    /// W3: a pass-through self loop is a cycle.
    @Test("W3: a pass-through self loop is a cycle")
    func passThroughSelfLoop() async throws {
        let model = try await MiniModel()
        let p = model.builder.state("P", in: model.machine, passThrough: true)
        model.builder.transition(from: p, to: p, when: model.builder.ref(model.sensor))
        model.builder.transition(from: p, to: model.a, when: model.builder.bool(true))
        model.builder.set(model.toA, .target, p)
        #expect(await model.codes() == ["W3"])
    }

    /// W4: an external variable must be shared.
    @Test("W4: an external variable must be shared")
    func externalLocalVariable() async throws {
        let model = try await MiniModel()
        model.builder.variable("probe", model.flag, in: model.machine, external: true)
        #expect(await model.codes() == ["W4"])
    }

    /// W4: an external variable must never be assigned.
    @Test("W4: an external variable must never be assigned")
    func assignedExternalVariable() async throws {
        let model = try await MiniModel()
        model.builder.action(model.b, model.builder.assign(model.builder.ref(model.sensor), model.builder.bool(false)))
        #expect(await model.codes() == ["W4"])
    }

    /// W4: an external variable may be read in labels and actions.
    @Test("W4: an external variable may be read in labels and actions")
    func readExternalVariable() async throws {
        let model = try await MiniModel()
        model.builder.action(model.b, model.builder.printLine("sensor", [model.builder.ref(model.sensor)]))
        #expect(await model.validate().isEmpty)
    }
}
