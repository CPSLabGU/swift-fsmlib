//
//  KernelExecutionTests.swift
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

/// The compilers and runtimes of the execution targets, found on the search path.
enum KernelToolchain {
    /// The C compiler.
    static let cc = KernelTestSupport.executable("cc")
    /// The C++ compiler.
    static let cxx = KernelTestSupport.executable("c++")
    /// The Swift compiler.
    static let swiftc = KernelTestSupport.executable("swiftc")
    /// The Java compiler.
    static let javac = KernelTestSupport.executable("javac")
    /// The Java runtime.
    static let java = KernelTestSupport.executable("java")

    /// The flags that make the C compiler strict.
    static let cFlags = ["-std=c11", "-Wall", "-Wextra", "-Werror"]
    /// The flags that make the C++ compiler strict.
    static let cxxFlags = ["-std=c++20", "-Wall", "-Wextra", "-Werror", "-pedantic"]
    /// The flags that make the Swift compiler strict.
    static let swiftFlags = ["-swift-version", "6", "-parse-as-library", "-warnings-as-errors"]
    /// The flags that make the Java compiler strict.
    static let javaFlags = ["--release", "17", "-encoding", "UTF-8", "-Xlint:all", "-Werror"]

    /// The name of the program that a build produces.
    static let programName = "program"

    /// Whether the tools for a target are available.
    static func isAvailable(_ target: KernelTarget) -> Bool {
        switch target {
        case .c:
            return cc != nil
        case .cpp:
            return cxx != nil
        case .swift:
            return swiftc != nil
        case .java:
            return javac != nil && java != nil
        case .smv, .tla, .dot:
            return false
        }
    }

    /// Compile the generated program of a model, with its host implementation if it has one.
    ///
    /// - Parameters:
    ///   - target: The execution target.
    ///   - name: The name of the arrangement, which names the generated file.
    ///   - hostSources: Additional source files that implement declared functions.
    ///   - directory: The directory that holds the generated file and receives the program.
    /// - Returns: The command that runs the program, as an executable and leading arguments.
    static func build(
        _ target: KernelTarget,
        _ name: String,
        hostSources: [URL],
        in directory: URL
    ) throws -> (executable: URL, arguments: [String]) {
        let generated = directory.appendingPathComponent(name)
        let program = directory.appendingPathComponent(programName)
        let hosts = hostSources.map(\.path)
        let compiler: URL
        let arguments: [String]
        switch target {
        case .c:
            compiler = try #require(cc)
            arguments = cFlags + [generated.appendingPathExtension("c").path] + hosts + ["-o", program.path]
        case .cpp:
            compiler = try #require(cxx)
            arguments = cxxFlags + [generated.appendingPathExtension("cpp").path] + hosts + ["-o", program.path]
        case .swift:
            compiler = try #require(swiftc)
            arguments = swiftFlags + [generated.appendingPathExtension("swift").path] + hosts + ["-o", program.path]
        case .java:
            compiler = try #require(javac)
            arguments = javaFlags + ["-d", directory.path, generated.appendingPathExtension("java").path] + hosts
        case .smv, .tla, .dot:
            throw KernelTemplateGeneratorError.missingTemplateSet(target)
        }
        let compiled = try KernelTestSupport.run(compiler, arguments, in: directory)
        #expect(compiled.status == 0, "\(target.rawValue) does not compile \(name):\n\(compiled.output)\(compiled.errors)")
        if target == .java {
            return (try #require(java), ["-cp", directory.path, name])
        }
        return (program, [])
    }
}

/// One model compiled and run by one execution target.
struct KernelExecutionCase: Sendable, CustomTestStringConvertible {
    /// The model.
    let model: KernelTestModel
    /// The execution target.
    let target: KernelTarget

    /// The model and the execution target, for test reports.
    var testDescription: String { "\(model) \(target.rawValue)" }

    /// The models that a target runs.
    static func cases(for target: KernelTarget) -> [KernelExecutionCase] {
        (KernelTestModel.fixtures + KernelTestModel.hosts)
            .filter { $0.executionTargets.contains(target) }
            .map { KernelExecutionCase(model: $0, target: target) }
    }
}

/// Compile-and-run tests: every execution target of every model compiles
/// under strict flags and reproduces the hand-derived canonical trace byte
/// for byte.
///
/// Each test runs only when the compiler of its target can be found on the
/// search path, and is skipped with a message otherwise.
@Suite("Kernel execution targets compile and reproduce the canonical traces")
@MainActor
struct KernelExecutionTests {
    /// Generate, compile and run one case and compare its output with the expected trace.
    func check(_ execution: KernelExecutionCase) async throws {
        let model = execution.model
        let expected = try KernelTestSupport.expectedTrace(of: model)
        let rounds = try #require(KernelTestSupport.rounds(of: expected), "the expected trace has no rounds")
        let directory = try await KernelTestSupport.generate(model, execution.target)
        defer { try? FileManager.default.removeItem(at: directory) }
        let hostSources = KernelTestSupport.hostSources(of: model, for: execution.target)
        let command = try KernelToolchain.build(execution.target, model.name, hostSources: hostSources, in: directory)
        var arguments = command.arguments + [String(rounds)]
        if model.isOpen {
            arguments.append(try #require(KernelTestSupport.inputs(of: model), "missing inputs of \(model)").path)
        }
        let outcome = try KernelTestSupport.run(command.executable, arguments, in: directory)
        #expect(outcome.status == 0, "\(execution.testDescription) exited with \(outcome.status): \(outcome.errors)")
        #expect(outcome.errors.isEmpty, "\(outcome.errors)")
        #expect(outcome.output == expected, "\(execution.testDescription) printed:\n\(outcome.output)")
    }

    /// Checks that the generated C programs reproduce the expected traces.
    ///
    /// - Parameter execution: The model and target to compile and run.
    /// - Throws: An error if generation, compilation or execution fails.
    @Test("C programs reproduce the expected traces",
          .enabled(if: KernelToolchain.isAvailable(.c), "No cc found on the search path; skipping the C programs"),
          arguments: KernelExecutionCase.cases(for: .c))
    func cPrograms(_ execution: KernelExecutionCase) async throws { try await check(execution) }

    /// Checks that the generated C++ programs reproduce the expected traces.
    ///
    /// - Parameter execution: The model and target to compile and run.
    /// - Throws: An error if generation, compilation or execution fails.
    @Test("C++ programs reproduce the expected traces",
          .enabled(if: KernelToolchain.isAvailable(.cpp), "No c++ found on the search path; skipping the C++ programs"),
          arguments: KernelExecutionCase.cases(for: .cpp))
    func cppPrograms(_ execution: KernelExecutionCase) async throws { try await check(execution) }

    /// Checks that the generated Swift programs reproduce the expected traces.
    ///
    /// - Parameter execution: The model and target to compile and run.
    /// - Throws: An error if generation, compilation or execution fails.
    @Test("Swift programs reproduce the expected traces",
          .enabled(if: KernelToolchain.isAvailable(.swift), "No swiftc found on the search path; skipping the Swift programs"),
          arguments: KernelExecutionCase.cases(for: .swift))
    func swiftPrograms(_ execution: KernelExecutionCase) async throws { try await check(execution) }

    /// Checks that the generated Java programs reproduce the expected traces.
    ///
    /// - Parameter execution: The model and target to compile and run.
    /// - Throws: An error if generation, compilation or execution fails.
    @Test("Java programs reproduce the expected traces",
          .enabled(if: KernelToolchain.isAvailable(.java), "No javac and java found on the search path; skipping the Java programs"),
          arguments: KernelExecutionCase.cases(for: .java))
    func javaPrograms(_ execution: KernelExecutionCase) async throws { try await check(execution) }

    /// A one-state counter whose increment leaves its range in the third round.
    static func overflowingCounter() async throws -> Resource {
        let b = try await KernelModelBuilder.make()
        let system = b.arrangement("Overflow")
        let small = b.integerType("Small", 0...2, in: system)
        let counter = b.machine("Counter", in: system)
        let x = b.variable("x", small, in: counter)
        let counting = b.state("Counting", in: counter)
        b.initial(counting, of: counter)
        b.action(counting, b.printLine("x", [b.ref(x)]), b.assign(b.ref(x), b.binary(.addition, b.ref(x), b.int(1))))
        b.transition(from: counting, to: counting, when: b.bool(true))
        b.instance("counter", of: counter, in: system)
        return await b.resource()
    }

    /// Run the overflowing counter with a target and check that it stops at the violation.
    func checkOverflow(_ target: KernelTarget) async throws {
        let directory = try KernelTestSupport.makeScratch("overflow")
        defer { try? FileManager.default.removeItem(at: directory) }
        let generator = KernelTemplateGenerator(metamodel: try await KernelMetamodel())
        try await generator.generate(target, resource: try await Self.overflowingCounter(), to: directory)
        let command = try KernelToolchain.build(target, "Overflow", hostSources: [], in: directory)
        let outcome = try KernelTestSupport.run(command.executable, command.arguments + ["5"], in: directory)
        #expect(outcome.status == 2)
        #expect(outcome.errors == "range violation x\n")
        #expect(outcome.output == "arrangement Overflow\nx 0\nR1 counter Counting\nx 1\nR2 counter Counting\nx 2\n")
    }

    /// Checks that a generated C program stops with a range violation.
    ///
    /// - Throws: An error if generation, compilation or execution fails.
    @Test("a C program stops with a range violation",
          .enabled(if: KernelToolchain.isAvailable(.c), "No cc found on the search path; skipping the C range check"))
    func cRangeViolation() async throws { try await checkOverflow(.c) }

    /// Checks that a generated C++ program stops with a range violation.
    ///
    /// - Throws: An error if generation, compilation or execution fails.
    @Test("a C++ program stops with a range violation",
          .enabled(if: KernelToolchain.isAvailable(.cpp), "No c++ found on the search path; skipping the C++ range check"))
    func cppRangeViolation() async throws { try await checkOverflow(.cpp) }

    /// Checks that a generated Swift program stops with a range violation.
    ///
    /// - Throws: An error if generation, compilation or execution fails.
    @Test("a Swift program stops with a range violation",
          .enabled(if: KernelToolchain.isAvailable(.swift), "No swiftc found on the search path; skipping the Swift range check"))
    func swiftRangeViolation() async throws { try await checkOverflow(.swift) }

    /// Checks that a generated Java program stops with a range violation.
    ///
    /// - Throws: An error if generation, compilation or execution fails.
    @Test("a Java program stops with a range violation",
          .enabled(if: KernelToolchain.isAvailable(.java), "No javac and java found on the search path; skipping the Java range check"))
    func javaRangeViolation() async throws { try await checkOverflow(.java) }
}
