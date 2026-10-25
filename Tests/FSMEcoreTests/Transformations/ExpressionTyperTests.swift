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
    /// The identifier of the integer variable `counter`.
    let counter = EUUID()
    /// The identifier of the integer variable `limit`.
    let limit = EUUID()
    /// The identifier of the Boolean variable `flag`.
    let flag = EUUID()
    /// The identifier of the integer array variable `samples`.
    let samples = EUUID()
    /// The identifier of the enumeration variable `colour`.
    let colour = EUUID()
    /// The identifier of the enumeration type of `colour`.
    let colourType = EUUID()
    /// The identifier of the array type of `samples`.
    let samplesType = EUUID()
    /// The identifier of the opaque variable `sensor`.
    let sensor = EUUID()
    /// The identifier of the opaque type of `sensor`.
    let sensorType = EUUID()
    /// The identifier of a second, shadowed declaration of `counter`.
    let shadowed = EUUID()
    /// The identifier of the pure function `isReady`.
    let isReady = EUUID()
    /// The identifier of the impure function `log`.
    let log = EUUID()
    /// The identifier of the function `read` that needs a `sensor` receiver.
    let read = EUUID()
    /// The identifier of the impure function `next`.
    let next = EUUID()

    /// The scope that declares the variables and functions of the fixture.
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

    /// A typer over the scope of the fixture.
    ///
    /// - Parameter language: The language of the text to type (C by default).
    /// - Returns: A typer for the language.
    func typer(_ language: String = "c") -> ExpressionTyper {
        ExpressionTyper(language: language, scope: scope)
    }
}

/// Tests for typing host-language expressions and statements against a scope.
@Suite("Expression typer")
struct ExpressionTyperTests {
    /// The scope shared by the tests.
    let fixture = TyperFixture()

    // MARK: - Literals and Names

    /// Boolean and decimal integer literals become typed nodes.
    @Test("Boolean and decimal integer literals type")
    func literals() {
        let typer = fixture.typer()
        #expect(typer.typedExpression(from: "true")?.node == .boolean(true))
        #expect(typer.typedExpression(from: "false")?.node == .boolean(false))
        #expect(typer.typedExpression(from: "42")?.node == .integer(42))
        #expect(typer.typedExpression(from: " 0 ")?.node == .integer(0))
    }

    /// Integer literals outside the plain decimal subset are not typed.
    ///
    /// - Parameter text: The literal text.
    @Test("integer literals outside the plain decimal subset stay opaque",
          arguments: ["0x1F", "010", "10u", "1.5", "2147483648", "'a'"])
    func nonDecimalLiterals(_ text: String) {
        #expect(fixture.typer().typedExpression(from: text) == nil)
    }

    /// Declared variables resolve to their identifiers and types.
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

    /// Variables that cannot be resolved or indexed correctly are not typed.
    ///
    /// - Parameter text: The expression text.
    @Test("undeclared, opaque, unindexed array and wrongly indexed variables stay opaque",
          arguments: ["missing", "counter < missing", "sensor", "samples", "counter[0]", "samples[flag]"])
    func unresolvedVariables(_ text: String) {
        #expect(fixture.typer().typedExpression(from: text) == nil)
    }

    // MARK: - Operators

    /// Unary negation and minus type their operands.
    @Test("unary negation and minus type their operands")
    func unaryOperators() {
        let typer = fixture.typer()
        #expect(typer.typedExpression(from: "!flag")?.node == .unary(.negation, .variable(fixture.flag, index: nil)))
        #expect(typer.typedExpression(from: "-counter")?.node == .unary(.minus, .variable(fixture.counter, index: nil)))
        #expect(typer.typedExpression(from: "!counter") == nil)
        #expect(typer.typedExpression(from: "-flag") == nil)
    }

    /// Every binary operator maps to its kernel operation.
    ///
    /// - Parameters:
    ///   - token: The operator token.
    ///   - operation: The expected kernel operation.
    @Test("every binary operator maps to its kernel operation",
          arguments: [
              ("&&", KernelBinaryOperation.conjunction), ("||", .disjunction), ("==", .equal),
              ("!=", .notEqual), ("<", .lessThan), ("<=", .lessOrEqual), (">", .greaterThan),
              (">=", .greaterOrEqual), ("+", .addition), ("-", .subtraction), ("*", .multiplication),
              ("/", .division), ("%", .modulo),
          ])
    func binaryOperators(_ token: String, _ operation: KernelBinaryOperation) {
        let operands = operation.isLogical ? ("flag", fixture.flag) : ("counter", fixture.counter)
        let operand = TypedNode.variable(operands.1, index: nil)
        let typed = fixture.typer().typedExpression(from: "\(operands.0) \(token) \(operands.0)")
        #expect(typed?.node == .binary(operation, operand, operand))
        #expect(typed?.type == (operation.isArithmetic ? .integer : .boolean))
    }

    /// Multiplication binds tighter than addition, which binds tighter than comparison.
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

    /// Conjunction binds tighter than disjunction, and equality tighter than conjunction.
    @Test("conjunction binds tighter than disjunction, and equality tighter than conjunction")
    func logicalPrecedence() {
        let flag = TypedNode.variable(fixture.flag, index: nil)
        let counter = TypedNode.variable(fixture.counter, index: nil)
        let typed = fixture.typer().typedExpression(from: "flag || counter == 1 && !flag")
        let equality = TypedNode.binary(.equal, counter, .integer(1))
        let conjunction = TypedNode.binary(.conjunction, equality, .unary(.negation, flag))
        #expect(typed?.node == .binary(.disjunction, flag, conjunction))
    }

    /// Operators of one precedence level group to the left.
    @Test("operators of one level group to the left")
    func leftAssociativity() {
        let typed = fixture.typer().typedExpression(from: "10 - 3 - 2")
        #expect(typed?.node == .binary(.subtraction, .binary(.subtraction, .integer(10), .integer(3)), .integer(2)))
    }

    /// Parentheses override operator precedence.
    @Test("parentheses override precedence")
    func parentheses() {
        let typed = fixture.typer().typedExpression(from: "(counter + 1) * 2")
        let sum = TypedNode.binary(.addition, .variable(fixture.counter, index: nil), .integer(1))
        #expect(typed?.node == .binary(.multiplication, sum, .integer(2)))
    }

    /// The conditional operator chooses between branches of one type.
    @Test("the conditional chooses between branches of one type")
    func conditional() {
        let typer = fixture.typer()
        let typed = typer.typedExpression(from: "flag ? counter : limit + 1")
        let limitPlusOne = TypedNode.binary(.addition, .variable(fixture.limit, index: nil), .integer(1))
        let expected = TypedNode.conditional(
            .variable(fixture.flag, index: nil),
            .variable(fixture.counter, index: nil),
            limitPlusOne)
        #expect(typed?.node == expected)
        #expect(typed?.type == .integer)
        #expect(typer.typedExpression(from: "flag ? counter : flag") == nil)
        #expect(typer.typedExpression(from: "counter ? 1 : 2") == nil)
    }

    /// Ill-typed operands are not typed.
    ///
    /// - Parameter text: The expression text.
    @Test("ill-typed operands stay opaque",
          arguments: ["counter && flag", "flag + 1", "flag < true", "counter == flag", "colour == 1"])
    func illTyped(_ text: String) {
        #expect(fixture.typer().typedExpression(from: text) == nil)
    }

    // MARK: - Time Helpers and Calls

    /// The time helpers compare the time in the state with their argument.
    ///
    /// - Parameters:
    ///   - name: The name of the helper.
    ///   - unit: The expected unit of time.
    @Test("the time helpers compare the time in the state with their argument",
          arguments: [("timeout", SectionedTimeUnit.microseconds), ("after", .seconds), ("after_ms", .milliseconds)])
    func timeHelpers(_ name: String, _ unit: SectionedTimeUnit) {
        let typed = fixture.typer().typedCondition(from: "\(name)(60)")
        #expect(typed == .binary(.greaterThan, .stateTime(unit), .integer(60)))
    }

    /// Time helpers with the wrong arguments are not typed.
    @Test("time helpers need one integer argument")
    func malformedTimeHelpers() {
        let typer = fixture.typer()
        #expect(typer.typedCondition(from: "after()") == nil)
        #expect(typer.typedCondition(from: "after(flag)") == nil)
        #expect(typer.typedCondition(from: "after(1, 2)") == nil)
        #expect(typer.typedCondition(from: "at(2)") == nil)
    }

    /// Calls of declared functions type, with and without a receiver.
    @Test("calls of declared functions type, with and without a receiver")
    func calls() {
        let typer = fixture.typer("objc++")
        let increment = TypedNode.binary(.addition, .variable(fixture.counter, index: nil), .integer(1))
        #expect(typer.typedCondition(from: "isReady(counter + 1)")
                == .call(fixture.isReady, receiver: nil, arguments: [increment]))
        let reading = TypedNode.call(fixture.read, receiver: .variable(fixture.sensor, index: nil), arguments: [])
        #expect(typer.typedExpression(from: "sensor.read() > 3")?.node
                == .binary(.greaterThan, reading, .integer(3)))
    }

    /// Calls that do not match their declaration are not typed.
    ///
    /// - Parameter text: The expression text.
    @Test("calls that do not match their declaration stay opaque",
          arguments: [
              "isReady()", "isReady(flag)", "undeclared(1)", "read()", "counter.read()", "sensor.isReady(1)",
              "log(1) == 1", "sensor.read().read()",
          ])
    func mismatchedCalls(_ text: String) {
        #expect(fixture.typer().typedExpression(from: text) == nil)
    }

    /// Labels call pure functions only and are Boolean.
    @Test("labels call pure functions only and are Boolean")
    func labels() {
        let typer = fixture.typer()
        #expect(typer.typedCondition(from: "next() > 1") == nil)
        #expect(typer.typedExpression(from: "next() > 1") != nil)
        #expect(typer.typedCondition(from: "counter + 1") == nil)
        #expect(typer.typedCondition(from: "2") == nil)
    }

    // MARK: - Statements

    /// Assignments, indexed assignments and call statements type.
    @Test("assignments, indexed assignments and call statements type")
    func statements() {
        let typer = fixture.typer()
        let typed = typer.typedStatements(from: "counter = counter + 1;\nsamples[0] = limit; log(counter);")
        let counter = TypedNode.variable(fixture.counter, index: nil)
        let increment = TypedNode.binary(.addition, counter, .integer(1))
        let firstSample = TypedNode.variable(fixture.samples, index: .integer(0))
        let logged = TypedNode.call(fixture.log, receiver: nil, arguments: [counter])
        #expect(typed == [
            .assignment(target: counter, value: increment),
            .assignment(target: firstSample, value: .variable(fixture.limit, index: nil)),
            .call(logged),
        ])
        #expect(typer.typedStatements(from: "x = sensor.read();") == nil)
        let reading = TypedNode.call(fixture.read, receiver: .variable(fixture.sensor, index: nil), arguments: [])
        #expect(fixture.typer("objc++").typedStatements(from: "counter = sensor.read();")
                == [.assignment(target: counter, value: reading)])
    }

    /// Print forms with plain literals become print statements.
    @Test("print forms with plain literals become print statements")
    func printStatements() {
        #expect(fixture.typer("c").typedStatements(from: "printf(\"go\\n\");") == [.print("go")])
        #expect(fixture.typer("cpp").typedStatements(from: "puts(\"stop 100%\");") == [.print("stop 100%")])
        #expect(fixture.typer("swift").typedStatements(from: "print(\"go\")") == [.print("go")])
        #expect(fixture.typer("java").typedStatements(from: "System.out.println(\"go\");") == [.print("go")])
    }

    /// Print forms with formats, escapes or no line break are not typed.
    ///
    /// - Parameter text: The statement text.
    @Test("print forms with formats, escapes or no line break stay opaque",
          arguments: [
              "printf(\"go\");", "printf(\"%d\\n\", counter);", "printf(\"a\\tb\\n\");", "printf(\"n = %d\\n\");",
              "puts(\"a\\n\");", "puts(name);",
          ])
    func opaquePrints(_ text: String) {
        #expect(fixture.typer("c").typedStatements(from: text) == nil)
    }

    /// C-family statements need their terminators, and Swift statements end at line breaks.
    @Test("C-family statements need their terminators, Swift statements end at line breaks")
    func separators() {
        #expect(fixture.typer("c").typedStatements(from: "counter = 1") == nil)
        #expect(fixture.typer("c").typedStatements(from: "counter = 1;;\n") != nil)
        let swift = fixture.typer("swift").typedStatements(from: "counter = 1\nflag = true; limit = 2")
        #expect(swift?.count == 3)
        #expect(fixture.typer("swift").typedStatements(from: "counter = 1 limit = 2") == nil)
    }

    /// Statements outside the subset make the whole text opaque.
    ///
    /// - Parameter text: The statement text.
    @Test("statements outside the subset make the whole text opaque",
          arguments: [
              "counter++;", "counter = 1; fflush(stdout);", "machine->counter = 0;", "if (flag) counter = 1;",
              "counter = 1; // done", "#define X 1", "counter = flag;", "flag = after(1) + 1;", "{ counter = 1; }",
          ])
    func unsupportedStatements(_ text: String) {
        #expect(fixture.typer("c").typedStatements(from: text) == nil)
    }

    /// Swift comparisons do not chain.
    @Test("Swift comparisons do not chain")
    func swiftComparisons() {
        #expect(fixture.typer("swift").typedExpression(from: "flag == counter < 1") == nil)
        #expect(fixture.typer("c").typedExpression(from: "flag == counter < 1") != nil)
    }

    /// Languages without a syntax table are never typed.
    @Test("languages without a syntax table are never typed")
    func unknownLanguages() {
        #expect(fixture.typer("scxml").typedExpression(from: "true") == nil)
        #expect(fixture.typer("").typedStatements(from: "counter = 1;") == nil)
    }

    // MARK: - Model Objects

    /// Typed text becomes kernel objects in the resource.
    ///
    /// - Throws: If the metamodels cannot be loaded or an object is missing.
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
        let text = "counter = 0;\nputs(\"reset\");"
        let statements = await typer.statements(from: text, in: resource, metamodel: metamodels.sectioned)
        #expect(statements.map(\.eClass.name) == ["Assignment", "Print"])
        #expect(statements.last?.string(.text) == "reset")
        #expect(await typer.statements(from: "  \n", in: resource, metamodel: metamodels.sectioned).isEmpty)
    }

    /// Text outside the subset becomes one opaque node with the exact text and language.
    ///
    /// - Throws: If the metamodels cannot be loaded.
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
