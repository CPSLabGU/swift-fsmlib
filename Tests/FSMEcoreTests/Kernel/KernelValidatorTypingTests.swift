//
//  KernelValidatorTypingTests.swift
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

/// Tests for the kernel validator: typing (W5).
@Suite("Kernel validator: typing (W5)")
struct KernelValidatorTypingTests {
    /// A well-typed label combining every kind of operation is accepted.
    @Test("a well-typed label combining every kind of operation is accepted")
    func wellTypedLabel() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let isOn = b.binary(.equal, b.literal("on", of: model.mode), b.literal("off", of: model.mode))
        let arithmetic = b.binary(.lessOrEqual,
                                  b.binary(.multiplication, b.ref(model.x), b.unary(.minus, b.ref(model.y))),
                                  b.conditional(b.ref(model.sensor), b.int(1), b.int(2)))
        let element = b.ref(b.variable("both", model.pair, in: model.machine), index: b.int(1))
        let observed = b.inState(model.instance, model.b)
        let left = b.binary(.conjunction, isOn, arithmetic)
        let right = b.binary(.conjunction, b.unary(.negation, element), observed)
        let label = b.binary(.disjunction, left, right)
        model.label(label)
        #expect(await model.validate().isEmpty)
    }

    /// A label must be Boolean.
    @Test("a label must be Boolean")
    func integerLabel() async throws {
        let model = try await MiniModel()
        model.label(model.builder.ref(model.x))
        let diagnostics = await model.validate()
        #expect(diagnostics.map(\.code) == ["W5"])
        #expect(diagnostics.first?.path == "/Mini/machines[M]/states[A]/transitions[0]/label")
    }

    /// Equality requires operands of the same type.
    @Test("equality requires operands of the same type")
    func equalityOfDifferentTypes() async throws {
        let model = try await MiniModel()
        let b = model.builder
        model.label(b.binary(.equal, b.ref(model.sensor), b.ref(model.x)))
        #expect(await model.codes() == ["W5"])
    }

    /// Equality of literals of different enumerations is rejected.
    @Test("equality of literals of different enumerations is rejected")
    func equalityOfDifferentEnumerations() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let other = b.enumerationType("Level", ["on", "off"], in: model.arrangement)
        model.label(b.binary(.notEqual, b.literal("on", of: model.mode), b.literal("on", of: other)))
        #expect(await model.codes() == ["W5"])
    }

    /// Arithmetic requires integer operands.
    @Test("arithmetic requires integer operands")
    func arithmeticOnBoolean() async throws {
        let model = try await MiniModel()
        let b = model.builder
        model.label(b.binary(.greaterThan, b.binary(.addition, b.ref(model.x), b.bool(true)), b.int(1)))
        #expect(await model.codes() == ["W5"])
    }

    /// Logical operations require Boolean operands.
    @Test("logical operations require Boolean operands")
    func conjunctionOfIntegers() async throws {
        let model = try await MiniModel()
        let b = model.builder
        model.label(b.binary(.conjunction, b.ref(model.sensor), b.int(1)))
        #expect(await model.codes() == ["W5"])
    }

    /// Negation requires a Boolean and minus an integer.
    @Test("negation requires a Boolean and minus an integer")
    func unaryOperands() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let negated = b.unary(.negation, b.int(1))
        let comparison = b.binary(.lessThan, b.unary(.minus, b.bool(true)), b.int(1))
        model.label(b.binary(.conjunction, negated, comparison))
        #expect(await model.codes() == ["W5", "W5"])
    }

    /// Comparison requires integer operands.
    @Test("comparison requires integer operands")
    func comparisonOfBooleans() async throws {
        let model = try await MiniModel()
        let b = model.builder
        model.label(b.binary(.lessThan, b.bool(false), b.bool(true)))
        #expect(await model.codes() == ["W5", "W5"])
    }

    /// Conditional branches must have the same type and the condition must be Boolean.
    @Test("conditional branches must have the same type and the condition must be Boolean")
    func conditionalBranches() async throws {
        let model = try await MiniModel()
        let b = model.builder
        model.label(b.binary(.equal, b.conditional(b.int(0), b.int(1), b.bool(true)), b.int(1)))
        #expect(await model.codes() == ["W5", "W5"])
    }

    /// An in-state observation must name a state of the instance's machine.
    @Test("an in-state observation must name a state of the instance's machine")
    func inStateOfForeignState() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let other = b.machine("N", in: model.arrangement)
        let c = b.state("C", in: other)
        b.initial(c, of: other)
        model.label(b.inState(model.instance, c))
        #expect(await model.codes() == ["W5"])
    }

    /// An array index must be an integer and only arrays may be indexed.
    @Test("an array index must be an integer and only arrays may be indexed")
    func arrayIndexing() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let both = b.variable("both", model.pair, in: model.machine)
        let booleanIndex = b.ref(both, index: b.bool(true))
        let scalarIndex = b.binary(.equal, b.ref(model.x, index: b.int(0)), b.int(0))
        model.label(b.binary(.conjunction, booleanIndex, scalarIndex))
        #expect(await model.codes() == ["W5", "W5"])
    }

    /// An enumeration literal must be a literal of its enumeration.
    @Test("an enumeration literal must be a literal of its enumeration")
    func unknownEnumerationLiteral() async throws {
        let model = try await MiniModel()
        let b = model.builder
        model.label(b.binary(.equal, b.literal("standby", of: model.mode), b.literal("on", of: model.mode)))
        #expect(await model.codes() == ["W5"])
    }

    /// Call arguments must match the declared parameters in number and type.
    @Test("call arguments must match the declared parameters in number and type")
    func callArguments() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let check = b.function(
            "check",
            in: model.arrangement,
            pure: true,
            parameters: [("level", model.count)],
            result: model.flag
        )
        model.label(b.call(check, [b.ref(model.x)]))
        #expect(await model.validate().isEmpty)
        model.label(b.call(check, []))
        #expect(await model.codes() == ["W5"])
        model.label(b.call(check, [b.bool(true)]))
        #expect(await model.codes() == ["W5"])
    }

    /// A call with a receiver must name a method of the receiver's type.
    @Test("a call with a receiver must name a method of the receiver's type")
    func callReceivers() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let method = b.function(
            "ready",
            in: model.arrangement,
            pure: true,
            result: model.flag,
            receiverType: model.count
        )
        let free = b.function("idle", in: model.arrangement, pure: true, result: model.flag)
        model.label(b.call(method, receiver: b.ref(model.x)))
        #expect(await model.validate().isEmpty)
        model.label(b.call(method, receiver: b.ref(model.sensor)))
        #expect(await model.codes() == ["W5"])
        model.label(b.call(free, receiver: b.ref(model.x)))
        #expect(await model.codes() == ["W5"])
    }

    /// A function without a result cannot be used as a value.
    @Test("a function without a result cannot be used as a value")
    func voidCallAsValue() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let reset = b.function("reset", in: model.arrangement, pure: true)
        model.label(b.call(reset))
        #expect(await model.codes() == ["W5"])
        model.label(b.bool(true))
        b.action(model.b, b.perform(b.call(reset)))
        #expect(await model.validate().isEmpty)
    }

    /// Initial values, bound values and assigned values must match the variable type.
    @Test("initial values, bound values and assigned values must match the variable type")
    func valueTypes() async throws {
        let model = try await MiniModel()
        let b = model.builder
        b.variable("ready", model.flag, in: model.machine, initialValue: b.int(1))
        b.binding(model.y, to: b.bool(true), for: model.instance)
        b.action(model.b, b.assign(b.ref(model.x), b.literal("on", of: model.mode)))
        #expect(await model.codes() == ["W5", "W5", "W5"])
    }

    /// An opaque operand suspends the checks that involve it under the relaxed profile.
    @Test("an opaque operand suspends the checks that involve it under the relaxed profile")
    func opaqueOperandSuspendsChecks() async throws {
        let model = try await MiniModel()
        let b = model.builder
        model.label(b.binary(.equal, b.opaqueExpression("probe()"), b.ref(model.x)))
        #expect(await model.codes(.relaxed).isEmpty)
        #expect(await model.codes(.strict) == ["STRICT"])
        model.label(b.binary(.conjunction, b.opaqueExpression("probe()"), b.ref(model.x)))
        #expect(await model.codes(.relaxed) == ["W5"])
    }

    /// An opaque expression with a declared kernel type is checked like that type.
    @Test("an opaque expression with a declared kernel type is checked like that type")
    func typedOpaqueExpression() async throws {
        let model = try await MiniModel()
        let b = model.builder
        model.label(b.opaqueExpression("level()", type: model.count))
        #expect(await model.codes(.relaxed) == ["W5"])
        model.label(b.opaqueExpression("ready()", type: model.flag))
        #expect(await model.codes(.relaxed).isEmpty)
    }
}

/// Tests for the kernel validator: actions, ranges, bindings and purity.
@Suite("Kernel validator: actions, ranges, bindings and purity")
struct KernelValidatorRuleW6toW9Tests {
    /// W6: a variable may be assigned once and read before its assignment.
    @Test("W6: a variable may be assigned once and read before its assignment")
    func singleAssignment() async throws {
        let model = try await MiniModel()
        let b = model.builder
        b.action(model.b,
                 b.assign(b.ref(model.x), b.binary(.addition, b.ref(model.x), b.ref(model.y))),
                 b.assign(b.ref(model.y), b.int(0)))
        b.action(model.a, b.assign(b.ref(model.x), b.int(1)))
        #expect(await model.validate().isEmpty)
    }

    /// W6: a variable must not be assigned twice in one action.
    @Test("W6: a variable must not be assigned twice in one action")
    func doubleAssignment() async throws {
        let model = try await MiniModel()
        let b = model.builder
        b.action(model.b, b.assign(b.ref(model.x), b.int(1)), b.assign(b.ref(model.x), b.int(2)))
        let diagnostics = await model.validate()
        #expect(diagnostics.map(\.code) == ["W6"])
        #expect(diagnostics.first?.path == "/Mini/machines[M]/states[B]/actions[1]")
    }

    /// W6: elements of one array variable count as one variable.
    @Test("W6: elements of one array variable count as one variable")
    func doubleArrayAssignment() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let both = b.variable("both", model.pair, in: model.machine)
        let first = b.assign(b.ref(both, index: b.int(0)), b.bool(true))
        let second = b.assign(b.ref(both, index: b.int(1)), b.bool(true))
        b.action(model.b, first, second)
        #expect(await model.codes() == ["W6"])
    }

    /// W6: a variable must not be read after its assignment in the same action.
    @Test("W6: a variable must not be read after its assignment in the same action")
    func readAfterAssignment() async throws {
        let model = try await MiniModel()
        let b = model.builder
        b.action(model.b, b.assign(b.ref(model.x), b.int(1)), b.printLine("x", [b.ref(model.x)]))
        #expect(await model.codes() == ["W6"])
    }

    /// W6: variables of opaque types are analysed under the strict profile only.
    @Test("W6: variables of opaque types are analysed under the strict profile only")
    func opaqueVariablesUnderRelaxedProfile() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let handle = b.opaqueType("Handle", text: "void *", in: model.arrangement)
        let h = b.variable("h", handle, in: model.machine)
        let open = b.assign(b.ref(h), b.opaqueExpression("open()"))
        let reopen = b.assign(b.ref(h), b.opaqueExpression("reopen()"))
        b.action(model.b, open, reopen)
        #expect(await model.codes(.relaxed).isEmpty)
        #expect(await model.codes(.strict) == ["W6", "STRICT", "STRICT", "STRICT"])
    }

    /// W7: assigned and bound integer literals must lie within the variable's range.
    @Test("W7: assigned and bound integer literals must lie within the variable's range")
    func literalRanges() async throws {
        let model = try await MiniModel()
        let b = model.builder
        b.action(model.b, b.assign(b.ref(model.x), b.int(9)))
        b.binding(model.y, to: b.int(0), for: model.instance)
        #expect(await model.validate().isEmpty)
        b.action(model.a, b.assign(b.ref(model.x), b.int(10)))
        b.binding(model.y, to: b.int(-1), for: b.instance("j", of: model.machine, in: model.arrangement))
        #expect(await model.codes() == ["W7", "W7"])
    }

    /// W7: a negated literal is checked against the range.
    @Test("W7: a negated literal is checked against the range")
    func negatedLiteralRange() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let d = b.variable("d", model.delta, in: model.machine)
        b.action(model.b, b.assign(b.ref(d), b.unary(.minus, b.int(3))))
        #expect(await model.validate().isEmpty)
        b.action(model.a, b.assign(b.ref(d), b.unary(.minus, b.int(4))))
        #expect(await model.codes() == ["W7"])
    }

    /// W7: an assignment to an array element is checked against the element range.
    @Test("W7: an assignment to an array element is checked against the element range")
    func arrayElementRange() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let levels = b.arrayType("Levels", of: model.count, size: 2, in: model.arrangement)
        let l = b.variable("l", levels, in: model.machine)
        b.action(model.b, b.assign(b.ref(l, index: b.int(0)), b.int(12)))
        #expect(await model.codes() == ["W7"])
    }

    /// W7?: a divisor that is not provably non-negative is a warning.
    @Test("W7?: a divisor that is not provably non-negative is a warning")
    func unprovenDivisor() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let d = b.variable("d", model.delta, in: model.machine)
        b.action(model.b, b.assign(b.ref(model.x), b.binary(.division, b.ref(model.y), b.int(2))))
        b.action(model.a, b.assign(b.ref(model.x), b.binary(.modulo, b.ref(model.y), b.ref(model.x))))
        #expect(await model.validate().isEmpty)
        let state = b.state("C", in: model.machine)
        b.transition(from: state, to: model.a, when: b.bool(true))
        b.action(state,
                 b.assign(b.ref(model.x), b.binary(.division, b.ref(model.y), b.ref(d))),
                 b.assign(b.ref(model.y), b.binary(.modulo, b.int(7), b.binary(.subtraction, b.int(2), b.int(1)))))
        let diagnostics = await model.validate()
        #expect(diagnostics.map(\.code) == ["W7?", "W7?"])
        #expect(diagnostics.allSatisfy { $0.severity == .warning })
        #expect(!KernelValidator.containsErrors(diagnostics))
    }

    /// W7?: an opaque divisor suspends the warning under the relaxed profile.
    @Test("W7?: an opaque divisor suspends the warning under the relaxed profile")
    func opaqueDivisor() async throws {
        let model = try await MiniModel()
        let b = model.builder
        b.action(model.b, b.assign(b.ref(model.x), b.binary(.division, b.ref(model.y), b.opaqueExpression("n"))))
        #expect(await model.codes(.relaxed).isEmpty)
    }

    /// W8: a binding value must be a literal.
    @Test("W8: a binding value must be a literal")
    func nonLiteralBinding() async throws {
        let model = try await MiniModel()
        let b = model.builder
        b.binding(model.y, to: b.literal("on", of: model.mode), for: model.instance)
        #expect(await model.codes() == ["W5"])
        let second = b.instance("j", of: model.machine, in: model.arrangement)
        b.binding(model.y, to: b.binary(.addition, b.int(1), b.int(2)), for: second)
        #expect(await model.codes() == ["W5", "W8"])
    }

    /// W8: a binding value that reads a variable is rejected under both profiles.
    @Test("W8: a binding value that reads a variable is rejected under both profiles")
    func variableBinding() async throws {
        let model = try await MiniModel()
        let b = model.builder
        b.binding(model.y, to: b.ref(model.x), for: model.instance)
        #expect(await model.codes(.strict) == ["W8"])
        #expect(await model.codes(.relaxed) == ["W8"])
    }

    /// W9: labels, binding values and initial values may call pure functions only.
    @Test("W9: labels, binding values and initial values may call pure functions only")
    func impureCalls() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let poll = b.function("poll", in: model.arrangement, result: model.flag)
        let level = b.function("level", in: model.arrangement, result: model.count)
        model.label(b.call(poll))
        b.variable("start", model.count, in: model.machine, initialValue: b.call(level))
        #expect(await model.codes() == ["W9", "W9"])
        #expect(await model.codes(.relaxed) == ["W9", "W9"])
    }

    /// W9: a call statement may call an impure function.
    @Test("W9: a call statement may call an impure function")
    func impureCallStatement() async throws {
        let model = try await MiniModel()
        let b = model.builder
        let log = b.function("log", in: model.arrangement, parameters: [("value", model.count)])
        let level = b.function("level", in: model.machine, result: model.count)
        b.action(model.b, b.perform(b.call(log, [b.ref(model.x)])), b.assign(b.ref(model.y), b.call(level)))
        #expect(await model.validate().isEmpty)
    }
}

/// Tests for the kernel validator: profiles.
@Suite("Kernel validator: profiles")
struct KernelValidatorProfileTests {
    /// The strict profile rejects every opaque node and host declarations.
    @Test("the strict profile rejects every opaque node and host declarations")
    func strictRejectsOpaqueNodes() async throws {
        let model = try await MiniModel()
        let b = model.builder
        b.hostDeclarations(in: model.machine, language: "c", includes: "#include <math.h>")
        let handle = b.opaqueType("Handle", text: "void *", in: model.arrangement)
        b.variable("h", handle, in: model.machine)
        b.action(model.b, b.opaqueStatement("tick();"))
        model.label(b.opaqueExpression("ready()"))
        let diagnostics = await model.validate(.strict)
        #expect(diagnostics.map(\.code) == ["STRICT", "STRICT", "STRICT", "STRICT"])
        #expect(Set(diagnostics.map(\.message)) == [
            "The strict profile admits no OpaqueType",
            "The strict profile admits no HostDeclarations",
            "The strict profile admits no OpaqueExpression",
            "The strict profile admits no OpaqueStatement",
        ])
        #expect(await model.validate(.relaxed).isEmpty)
    }

    /// The relaxed profile still applies the structural and naming rules.
    @Test("the relaxed profile still applies the structural and naming rules")
    func relaxedKeepsStructuralRules() async throws {
        let model = try await MiniModel()
        let b = model.builder
        model.label(b.opaqueExpression("ready()"))
        b.state("A", in: model.machine)
        b.set(model.a, .passThrough, true)
        #expect(await model.codes(.relaxed) == ["W1", "W2"])
    }
}
