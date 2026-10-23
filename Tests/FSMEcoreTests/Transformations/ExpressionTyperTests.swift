//
//  ExpressionTyperTests.swift
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

/// A scope with one variable of each kind and a few functions.
struct TyperFixture {
    let counter = EUUID()
    let limit = EUUID()
    let flag = EUUID()
    let samples = EUUID()
    let colour = EUUID()
    let colourType = EUUID()
    let samplesType = EUUID()
    let sensor = EUUID()
    let sensorType = EUUID()
    let shadowed = EUUID()
    let isReady = EUUID()
    let log = EUUID()
    let read = EUUID()
    let next = EUUID()

    var scope: ExpressionTyper.Scope {
        ExpressionTyper.Scope(
            variables: [
                .init(name: "counter", identifier: counter, type: .integer),
                .init(name: "limit", identifier: limit, type: .integer),
                .init(name: "flag", identifier: flag, type: .boolean),
                .init(name: "samples", identifier: samples, type: .array(samplesType, element: .integer)),
                .init(name: "colour", identifier: colour, type: .enumeration(colourType)),
                .init(name: "sensor", identifier: sensor, type: .opaque(sensorType)),
                .init(name: "counter", identifier: shadowed, type: .boolean),
            ],
            functions: [
                .init(name: "isReady", identifier: isReady, parameters: [.integer], result: .boolean, isPure: true),
                .init(name: "log", identifier: log, parameters: [.integer]),
                .init(name: "read", identifier: read, result: .integer, receiverType: .opaque(sensorType)),
                .init(name: "next", identifier: next, result: .integer),
            ])
    }

    func typer(_ language: String = "c") -> ExpressionTyper {
        ExpressionTyper(language: language, scope: scope)
    }
}

@Suite("Expression typer")
struct ExpressionTyperTests {
    let fixture = TyperFixture()

    // MARK: - Literals and Names

    @Test("Boolean and decimal integer literals type")
    func literals() {
        let typer = fixture.typer()
        #expect(typer.typedExpression(from: "true")?.node == .boolean(true))
        #expect(typer.typedExpression(from: "false")?.node == .boolean(false))
        #expect(typer.typedExpression(from: "42")?.node == .integer(42))
        #expect(typer.typedExpression(from: " 0 ")?.node == .integer(0))
    }

    @Test("integer literals outside the plain decimal subset stay opaque",
          arguments: ["0x1F", "010", "10u", "1.5", "2147483648", "'a'"])
    func nonDecimalLiterals(_ text: String) {
        #expect(fixture.typer().typedExpression(from: text) == nil)
    }

    @Test("declared variables resolve, the first declaration of a name taking precedence")
    func variables() {
        let typer = fixture.typer()
        #expect(typer.typedExpression(from: "counter")?.node == .variable(fixture.counter, index: nil))
        #expect(typer.typedExpression(from: "counter")?.type == .integer)
        #expect(typer.typedExpression(from: "flag")?.type == .boolean)
        #expect(typer.typedExpression(from: "samples[counter]")?.node
                == .variable(fixture.samples, index: .variable(fixture.counter, index: nil)))
        #expect(typer.typedExpression(from: "colour")?.type == .enumeration(fixture.colourType))
    }

    @Test("undeclared, opaque, unindexed array and wrongly indexed variables stay opaque",
          arguments: ["missing", "counter < missing", "sensor", "samples", "counter[0]", "samples[flag]"])
    func unresolvedVariables(_ text: String) {
        #expect(fixture.typer().typedExpression(from: text) == nil)
    }

    // MARK: - Operators

    @Test("unary negation and minus type their operands")
    func unaryOperators() {
        let typer = fixture.typer()
        #expect(typer.typedExpression(from: "!flag")?.node == .unary(.negation, .variable(fixture.flag, index: nil)))
        #expect(typer.typedExpression(from: "-counter")?.node == .unary(.minus, .variable(fixture.counter, index: nil)))
        #expect(typer.typedExpression(from: "!counter") == nil)
        #expect(typer.typedExpression(from: "-flag") == nil)
    }

    @Test("every binary operator maps to its kernel operation",
          arguments: [("&&", KernelBinaryOperation.conjunction), ("||", .disjunction), ("==", .equal),
                      ("!=", .notEqual), ("<", .lessThan), ("<=", .lessOrEqual), (">", .greaterThan),
                      (">=", .greaterOrEqual), ("+", .addition), ("-", .subtraction), ("*", .multiplication),
                      ("/", .division), ("%", .modulo)])
    func binaryOperators(_ token: String, _ operation: KernelBinaryOperation) {
        let operands = operation.isLogical ? ("flag", fixture.flag) : ("counter", fixture.counter)
        let operand = TypedNode.variable(operands.1, index: nil)
        let typed = fixture.typer().typedExpression(from: "\(operands.0) \(token) \(operands.0)")
        #expect(typed?.node == .binary(operation, operand, operand))
        #expect(typed?.type == (operation.isArithmetic ? .integer : .boolean))
    }

    @Test("multiplication binds tighter than addition, which binds tighter than comparison")
    func arithmeticPrecedence() {
        let counter = TypedNode.variable(fixture.counter, index: nil)
        let typed = fixture.typer().typedExpression(from: "counter + 2 * 3 < 10 - counter % 4")
        let product = TypedNode.binary(.multiplication, .integer(2), .integer(3))
        let sum = TypedNode.binary(.addition, counter, product)
        let remainder = TypedNode.binary(.modulo, counter, .integer(4))
        let difference = TypedNode.binary(.subtraction, .integer(10), remainder)
        #expect(typed?.node == .binary(.lessThan, sum, difference))
    }

    @Test("conjunction binds tighter than disjunction, and equality tighter than conjunction")
    func logicalPrecedence() {
        let flag = TypedNode.variable(fixture.flag, index: nil)
        let counter = TypedNode.variable(fixture.counter, index: nil)
        let typed = fixture.typer().typedExpression(from: "flag || counter == 1 && !flag")
        let equality = TypedNode.binary(.equal, counter, .integer(1))
        let conjunction = TypedNode.binary(.conjunction, equality, .unary(.negation, flag))
        #expect(typed?.node == .binary(.disjunction, flag, conjunction))
    }

    @Test("operators of one level group to the left")
    func leftAssociativity() {
        let typed = fixture.typer().typedExpression(from: "10 - 3 - 2")
        #expect(typed?.node == .binary(.subtraction, .binary(.subtraction, .integer(10), .integer(3)), .integer(2)))
    }

    @Test("parentheses override precedence")
    func parentheses() {
        let typed = fixture.typer().typedExpression(from: "(counter + 1) * 2")
        let sum = TypedNode.binary(.addition, .variable(fixture.counter, index: nil), .integer(1))
        #expect(typed?.node == .binary(.multiplication, sum, .integer(2)))
    }

    @Test("the conditional chooses between branches of one type")
    func conditional() {
        let typer = fixture.typer()
        let typed = typer.typedExpression(from: "flag ? counter : limit + 1")
        let limitPlusOne = TypedNode.binary(.addition, .variable(fixture.limit, index: nil), .integer(1))
        #expect(typed?.node == .conditional(.variable(fixture.flag, index: nil),
                                            .variable(fixture.counter, index: nil), limitPlusOne))
        #expect(typed?.type == .integer)
        #expect(typer.typedExpression(from: "flag ? counter : flag") == nil)
        #expect(typer.typedExpression(from: "counter ? 1 : 2") == nil)
    }

    @Test("ill-typed operands stay opaque",
          arguments: ["counter && flag", "flag + 1", "flag < true", "counter == flag", "colour == 1"])
    func illTyped(_ text: String) {
        #expect(fixture.typer().typedExpression(from: text) == nil)
    }

    // MARK: - Time Helpers and Calls

    @Test("the time helpers compare the time in the state with their argument",
          arguments: [("timeout", SectionedTimeUnit.microseconds), ("after", .seconds), ("after_ms", .milliseconds)])
    func timeHelpers(_ name: String, _ unit: SectionedTimeUnit) {
        let typed = fixture.typer().typedCondition(from: "\(name)(60)")
        #expect(typed == .binary(.greaterThan, .stateTime(unit), .integer(60)))
    }

    @Test("time helpers need one integer argument")
    func malformedTimeHelpers() {
        let typer = fixture.typer()
        #expect(typer.typedCondition(from: "after()") == nil)
        #expect(typer.typedCondition(from: "after(flag)") == nil)
        #expect(typer.typedCondition(from: "after(1, 2)") == nil)
        #expect(typer.typedCondition(from: "at(2)") == nil)
    }

    @Test("calls of declared functions type, with and without a receiver")
    func calls() {
        let typer = fixture.typer("objc++")
        #expect(typer.typedCondition(from: "isReady(counter + 1)")
                == .call(fixture.isReady, receiver: nil,
                         arguments: [.binary(.addition, .variable(fixture.counter, index: nil), .integer(1))]))
        #expect(typer.typedExpression(from: "sensor.read() > 3")?.node
                == .binary(.greaterThan, .call(fixture.read, receiver: .variable(fixture.sensor, index: nil),
                                                arguments: []), .integer(3)))
    }

    @Test("calls that do not match their declaration stay opaque",
          arguments: ["isReady()", "isReady(flag)", "undeclared(1)", "read()", "counter.read()", "sensor.isReady(1)",
                      "log(1) == 1", "sensor.read().read()"])
    func mismatchedCalls(_ text: String) {
        #expect(fixture.typer().typedExpression(from: text) == nil)
    }

    @Test("labels call pure functions only and are Boolean")
    func labels() {
        let typer = fixture.typer()
        #expect(typer.typedCondition(from: "next() > 1") == nil)
        #expect(typer.typedExpression(from: "next() > 1") != nil)
        #expect(typer.typedCondition(from: "counter + 1") == nil)
        #expect(typer.typedCondition(from: "2") == nil)
    }

    // MARK: - Statements

    @Test("assignments, indexed assignments and call statements type")
    func statements() {
        let typer = fixture.typer()
        let typed = typer.typedStatements(from: "counter = counter + 1;\nsamples[0] = limit; log(counter);")
        #expect(typed == [
            .assignment(target: .variable(fixture.counter, index: nil),
                        value: .binary(.addition, .variable(fixture.counter, index: nil), .integer(1))),
            .assignment(target: .variable(fixture.samples, index: .integer(0)), value: .variable(fixture.limit, index: nil)),
            .call(.call(fixture.log, receiver: nil, arguments: [.variable(fixture.counter, index: nil)])),
        ])
        #expect(typer.typedStatements(from: "x = sensor.read();") == nil)
        #expect(fixture.typer("objc++").typedStatements(from: "counter = sensor.read();")
                == [.assignment(target: .variable(fixture.counter, index: nil),
                                value: .call(fixture.read, receiver: .variable(fixture.sensor, index: nil), arguments: []))])
    }

    @Test("print forms with plain literals become print statements")
    func printStatements() {
        #expect(fixture.typer("c").typedStatements(from: "printf(\"go\\n\");") == [.print("go")])
        #expect(fixture.typer("cpp").typedStatements(from: "puts(\"stop 100%\");") == [.print("stop 100%")])
        #expect(fixture.typer("swift").typedStatements(from: "print(\"go\")") == [.print("go")])
        #expect(fixture.typer("java").typedStatements(from: "System.out.println(\"go\");") == [.print("go")])
    }

    @Test("print forms with formats, escapes or no line break stay opaque",
          arguments: ["printf(\"go\");", "printf(\"%d\\n\", counter);", "printf(\"a\\tb\\n\");", "printf(\"n = %d\\n\");",
                      "puts(\"a\\n\");", "puts(name);"])
    func opaquePrints(_ text: String) {
        #expect(fixture.typer("c").typedStatements(from: text) == nil)
    }

    @Test("C-family statements need their terminators, Swift statements end at line breaks")
    func separators() {
        #expect(fixture.typer("c").typedStatements(from: "counter = 1") == nil)
        #expect(fixture.typer("c").typedStatements(from: "counter = 1;;\n") != nil)
        let swift = fixture.typer("swift").typedStatements(from: "counter = 1\nflag = true; limit = 2")
        #expect(swift?.count == 3)
        #expect(fixture.typer("swift").typedStatements(from: "counter = 1 limit = 2") == nil)
    }

    @Test("statements outside the subset make the whole text opaque",
          arguments: ["counter++;", "counter = 1; fflush(stdout);", "machine->counter = 0;", "if (flag) counter = 1;",
                      "counter = 1; // done", "#define X 1", "counter = flag;", "flag = after(1) + 1;", "{ counter = 1; }"])
    func unsupportedStatements(_ text: String) {
        #expect(fixture.typer("c").typedStatements(from: text) == nil)
    }

    @Test("Swift comparisons do not chain")
    func swiftComparisons() {
        #expect(fixture.typer("swift").typedExpression(from: "flag == counter < 1") == nil)
        #expect(fixture.typer("c").typedExpression(from: "flag == counter < 1") != nil)
    }

    @Test("languages without a syntax table are never typed")
    func unknownLanguages() {
        #expect(fixture.typer("scxml").typedExpression(from: "true") == nil)
        #expect(fixture.typer("").typedStatements(from: "counter = 1;") == nil)
    }

    // MARK: - Model Objects

    @Test("typed text becomes kernel objects in the resource")
    func typedObjects() async throws {
        let metamodels = try await LLFSMMetamodels()
        let resource = Resource(uri: "memory:/typer.xmi")
        let typer = fixture.typer()
        let label = await typer.condition(from: "after(5) && flag", in: resource, metamodel: metamodels.sectioned)
        #expect(label.eClass.name == metamodels.kernel.binaryExpressionClass.name)
        #expect(label.string(.operation) == KernelBinaryOperation.conjunction.rawValue)
        let leftID = try #require(label.identifier(.left))
        let left = try #require(await resource.resolve(leftID) as? DynamicEObject)
        #expect(left.string(.operation) == KernelBinaryOperation.greaterThan.rawValue)
        let timeID = try #require(left.identifier(.left))
        let time = try #require(await resource.resolve(timeID) as? DynamicEObject)
        #expect(time.eClass.id == metamodels.sectioned.stateTimeExpressionClass.id)
        #expect(time.string(.unit) == SectionedTimeUnit.seconds.rawValue)
        let statements = await typer.statements(from: "counter = 0;\nputs(\"reset\");", in: resource,
                                                metamodel: metamodels.sectioned)
        #expect(statements.map(\.eClass.name) == ["Assignment", "Print"])
        #expect(statements.last?.string(.text) == "reset")
        #expect(await typer.statements(from: "  \n", in: resource, metamodel: metamodels.sectioned).isEmpty)
    }

    @Test("text outside the subset becomes one opaque node with the exact text and language")
    func opaqueObjects() async throws {
        let metamodels = try await LLFSMMetamodels()
        let resource = Resource(uri: "memory:/typer.xmi")
        let typer = fixture.typer("objc++")
        let section = "counter = 0;\nprintf(\"Initial: counter = %d\\n\", counter);\n"
        let statements = await typer.statements(from: section, in: resource, metamodel: metamodels.sectioned)
        #expect(statements.count == 1)
        #expect(statements.first?.eClass.id == metamodels.kernel.opaqueStatementClass.id)
        #expect(statements.first?.string(.text) == section)
        #expect(statements.first?.string(.language) == "objc++")
        let label = await typer.condition(from: " at(2) ", in: resource, metamodel: metamodels.sectioned)
        #expect(label.eClass.id == metamodels.kernel.opaqueExpressionClass.id)
        #expect(label.string(.text) == " at(2) ")
        #expect(label.string(.language) == "objc++")
        let expression = await typer.expression(from: "counter +", in: resource, metamodel: metamodels.sectioned)
        #expect(expression.string(.text) == "counter +")
    }
}
