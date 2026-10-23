//
//  CLIPipelineTests.swift
//  FSMTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing
@testable import FSM

/// End-to-end tests of the levels, transformations, kernel targets and
/// validation that `fsmconvert` offers.
@Suite("fsmconvert levels and targets")
struct CLIPipelineTests {
    /// The prefix of the root element of a kernel document.
    static let kernelRoot = "<kernel:Arrangement"

    /// The prefix of the root element of a sectioned document.
    static let sectionedRoot = "<sectioned:Arrangement"

    /// Run the tool and expect it to succeed.
    ///
    /// - Parameter arguments: The command-line arguments.
    /// - Returns: The result of the run.
    @discardableResult
    func succeed(_ arguments: [String], sourceLocation: SourceLocation = #_sourceLocation) throws -> FSMConvertRunner.Result {
        let result = try FSMConvertRunner.run(arguments)
        #expect(result.status == FSMConvertRunner.successStatus, "\(arguments): \(result.standardError)",
                sourceLocation: sourceLocation)
        return result
    }

    /// Compare the files below two locations byte for byte.
    func expectIdentical(_ lhs: URL, _ rhs: URL, sourceLocation: SourceLocation = #_sourceLocation) {
        let left = FSMConvertRunner.files(at: lhs)
        let right = FSMConvertRunner.files(at: rhs)
        #expect(!left.isEmpty, "nothing was written to \(lhs.path)", sourceLocation: sourceLocation)
        #expect(left.keys.sorted() == right.keys.sorted(), sourceLocation: sourceLocation)
        let differing = left.keys.filter { left[$0] != right[$0] }.sorted()
        #expect(differing.isEmpty, "differing files: \(differing)", sourceLocation: sourceLocation)
    }

    // MARK: - Native Generators

    @Test("native formats from the templates match the Swift bindings byte for byte",
          arguments: [["-f", "c"], ["-f", "objcpp"], ["-f", "scxml"], [], ["-n", "-f", "c"],
                      ["--metamodel", "structural", "-n", "-f", "c"]])
    func templatesMatchSwift(_ options: [String]) throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "native")
        defer { try? FileManager.default.removeItem(at: directory) }
        let name = options.contains("scxml") ? "TrafficLight.scxml" : "TrafficLight.machine"
        let templates = directory.appendingPathComponent("mtl/\(name)")
        let swift = directory.appendingPathComponent("swift/\(name)")
        try FileManager.default.createDirectory(at: templates.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: swift.deletingLastPathComponent(), withIntermediateDirectories: true)
        let input = FSMConvertRunner.trafficLight.path
        try succeed([input] + options + ["-o", templates.path])
        try succeed([input] + options + ["--generator", "swift", "-o", swift.path])
        expectIdentical(templates, swift)
    }

    @Test("arrangements from the templates match the Swift bindings byte for byte")
    func arrangementTemplatesMatchSwift() throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "arrangement")
        defer { try? FileManager.default.removeItem(at: directory) }
        let inputs = ["Counter.machine", "SuspendCounter.machine"].map {
            FSMConvertRunner.examples.appendingPathComponent($0).path
        }
        for generator in ["mtl", "swift"] {
            try FileManager.default.createDirectory(
                at: directory.appendingPathComponent(generator), withIntermediateDirectories: true)
            try succeed(inputs + ["-f", "c", "--generator", generator,
                                  "-o", directory.appendingPathComponent("\(generator)/Pair.arrangement").path])
        }
        expectIdentical(directory.appendingPathComponent("mtl/Pair.arrangement"),
                        directory.appendingPathComponent("swift/Pair.arrangement"))
    }

    @Test("machines written by either generator read back as the original machine", arguments: ["mtl", "swift"])
    func generatorRoundTrip(_ generator: String) throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "roundtrip")
        defer { try? FileManager.default.removeItem(at: directory) }
        let written = directory.appendingPathComponent("TrafficLight.machine")
        let again = directory.appendingPathComponent("again/TrafficLight.machine")
        try FileManager.default.createDirectory(at: again.deletingLastPathComponent(), withIntermediateDirectories: true)
        try succeed([FSMConvertRunner.trafficLight.path, "--generator", generator, "-o", written.path])
        try succeed([written.path, "--generator", generator, "-o", again.path])
        let original = try Machine(from: FSMConvertRunner.trafficLight)
        let first = try Machine(from: written)
        let second = try Machine(from: again)
        #expect(first.llfsm.stateNames == original.llfsm.stateNames)
        #expect(second.llfsm.stateNames == original.llfsm.stateNames)
        #expect(first.llfsm.transitions.count == original.llfsm.transitions.count)
        #expect(second.llfsm.transitions.count == original.llfsm.transitions.count)
        let labels = { (machine: Machine) in machine.llfsm.transitions.compactMap { machine.llfsm.transition(for: $0)?.label } }
        #expect(labels(second) == labels(original))
    }

    // MARK: - Kernel Targets

    @Test("kernel targets are generated from a native machine",
          arguments: [["-f", "dot"], ["-f", "kernel-c"], ["-f", "smv", "--opaque", "havoc"],
                      ["-f", "tla", "--opaque", "havoc"], ["--metamodel", "kernel", "-f", "c"]])
    func kernelTargetsFromMachine(_ options: [String]) throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "kernel-native")
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = FSMConvertRunner.examples.appendingPathComponent("CounterC.machine")
        try succeed([input.path] + options + ["-o", directory.path])
        let extensions = Set(FSMConvertRunner.files(at: directory).keys.map { URL(fileURLWithPath: $0).pathExtension })
        let expected: Set<String> = switch options[options.firstIndex(of: "-f")! + 1] {
        case "dot": ["dot"]
        case "smv": ["smv"]
        case "tla": ["tla", "cfg"]
        default: ["c"]
        }
        #expect(extensions == expected)
    }

    @Test("verification targets reject the host code of a native machine without --opaque havoc")
    func verificationRejectsHostCode() throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "strict")
        defer { try? FileManager.default.removeItem(at: directory) }
        let result = try FSMConvertRunner.run([FSMConvertRunner.trafficLight.path, "-f", "smv", "-o", directory.path])
        #expect(result.status == FSMConvertRunner.failureStatus)
        #expect(result.standardError.contains("STRICT"), "\(result.standardError)")
        #expect(FSMConvertRunner.files(at: directory).isEmpty)
    }

    @Test("kernel targets of the kernel fixtures match the expected files",
          arguments: [("smv", "smv"), ("tla", "tla"), ("dot", "dot"), ("kernel-c", "kernel-c"),
                      ("c", "kernel-c")])
    func kernelTargetsFromFixture(_ format: String, _ expected: String) throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "kernel-fixture")
        defer { try? FileManager.default.removeItem(at: directory) }
        let synonym = format == "c" ? ["--metamodel", "kernel"] : []
        try succeed([FSMConvertRunner.kernelModel("DoorInterlock").path, "-f", format] + synonym + ["-o", directory.path])
        let written = FSMConvertRunner.files(at: directory)
        let reference = FSMConvertRunner.files(at: FSMConvertRunner.expected(expected))
            .filter { $0.key.hasPrefix("DoorInterlock.") }
        #expect(!written.isEmpty)
        #expect(written == reference, "\(written.keys.sorted()) differs from \(reference.keys.sorted())")
    }

    @Test("template parameters reach the kernel targets")
    func kernelParameters() throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "parameters")
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = FSMConvertRunner.kernelModel("DoorInterlock").path
        let plain = directory.appendingPathComponent("plain")
        let rounds = directory.appendingPathComponent("rounds")
        let param = directory.appendingPathComponent("param")
        try succeed([input, "-f", "smv", "-o", plain.path])
        try succeed([input, "-f", "smv", "--max-rounds", "3", "-o", rounds.path])
        try succeed([input, "-f", "smv", "--param", "maxRounds=3", "-o", param.path])
        #expect(FSMConvertRunner.files(at: plain) != FSMConvertRunner.files(at: rounds))
        expectIdentical(rounds, param)
    }

    // MARK: - Levels

    @Test("a native machine is written as a kernel model")
    func kernelXMIFromMachine() throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "kernel-xmi")
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("TrafficLight.xmi")
        let result = try succeed([FSMConvertRunner.trafficLight.path, "--metamodel", "kernel", "-f", "xmi", "-o", output.path])
        #expect(try String(contentsOf: output, encoding: .utf8).contains(Self.kernelRoot))
        #expect(result.standardError.contains("warning: "), "the lost include path is reported")
        try succeed([output.path, "--validate", "--profile", "relaxed"])
    }

    @Test("a sectioned model is written as a kernel model", arguments: [["--metamodel", "kernel", "-f", "xmi"], ["-f", "kernel-xmi"]])
    func kernelXMIFromSectioned(_ options: [String]) throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "sectioned-kernel")
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("Crossing.xmi")
        try succeed([FSMConvertRunner.sectionedModel("SectionedCrossing").path] + options + ["-o", output.path])
        #expect(try String(contentsOf: output, encoding: .utf8).contains(Self.kernelRoot))
    }

    @Test("the sectioned level can be selected, also with its deprecated name", arguments: ["sectioned", "executable"])
    func sectionedXMIFromMachine(_ level: String) throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "sectioned")
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("TrafficLight.xmi")
        let result = try succeed([FSMConvertRunner.trafficLight.path, "--metamodel", level, "-f", "xmi", "-o", output.path])
        #expect(try String(contentsOf: output, encoding: .utf8).contains(Self.sectionedRoot))
        #expect(result.standardError.contains("deprecated") == (level == "executable"))
    }

    @Test("a kernel model is written as JSON and read back")
    func kernelJSON() throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "json")
        defer { try? FileManager.default.removeItem(at: directory) }
        let json = directory.appendingPathComponent("DoorInterlock.json")
        let smv = directory.appendingPathComponent("smv")
        try succeed([FSMConvertRunner.kernelModel("DoorInterlock").path, "-f", "json", "-o", json.path])
        try succeed([json.path, "-f", "smv", "-o", smv.path])
        #expect(FSMConvertRunner.files(at: smv) == FSMConvertRunner.files(at: FSMConvertRunner.expected("smv"))
            .filter { $0.key.hasPrefix("DoorInterlock.") })
    }

    @Test("native bundles are written from the kernel level with a flat-mapping warning")
    func nativeFromKernel() throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "kernel-native")
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("DoorInterlock.arrangement")
        let result = try succeed([FSMConvertRunner.kernelModel("DoorInterlock").path,
                                  "--metamodel", "structural", "-f", "c", "-o", output.path])
        #expect(result.standardError.contains("mapped flatly"), "\(result.standardError)")
        #expect(FileManager.default.fileExists(atPath: output.appendingPathComponent("Machines").path))
        let arrangement = try Arrangement(from: output)
        #expect(arrangement.namedInstances.count == 2)
        #expect(arrangement.namedInstances.allSatisfy { !$0.machine.llfsm.states.isEmpty })
    }

    @Test("the plain reference style writes fragments without a leading #")
    func referenceStyle() throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "references")
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("DoorInterlock.xmi")
        try succeed([FSMConvertRunner.kernelModel("DoorInterlock").path, "-f", "xmi", "--reference-style", "plain",
                     "-o", output.path])
        let text = try String(contentsOf: output, encoding: .utf8)
        #expect(text.contains("\"//@"))
        #expect(!text.contains("#//@"))
    }

    @Test("--unset-features reaches the kernel templates")
    func unsetFeatures() throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "unset")
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = FSMConvertRunner.kernelModel("DoorInterlock").path
        let defaults = directory.appendingPathComponent("defaults")
        let undefined = directory.appendingPathComponent("undefined")
        try succeed([input, "-f", "smv", "--unset-features", "defaults", "-o", defaults.path])
        try succeed([input, "-f", "smv", "--unset-features", "undefined", "-o", undefined.path])
        #expect(FSMConvertRunner.files(at: defaults) == FSMConvertRunner.files(at: FSMConvertRunner.expected("smv"))
            .filter { $0.key.hasPrefix("DoorInterlock.") })
        #expect(FSMConvertRunner.files(at: defaults) != FSMConvertRunner.files(at: undefined))
    }

    @Test("structural templates render the first machine of an arrangement")
    func structuralTemplateOfArrangement() throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "transform")
        defer { try? FileManager.default.removeItem(at: directory) }
        let output = directory.appendingPathComponent("First.scxml")
        let inputs = ["Counter.machine", "SuspendCounter.machine"].map { FSMConvertRunner.examples.appendingPathComponent($0).path }
        try succeed(inputs + ["--metamodel", "structural", "--transform", "structural2scxml", "-o", output.path])
        #expect(FileManager.default.fileExists(atPath: output.path))
    }

    // MARK: - Semantics

    @Test("--semantics selfLoop=reentry changes the kernel encoding of a self transition")
    func selfLoopSemantics() throws {
        let directory = try FSMConvertRunner.makeTemporaryDirectory(prefix: "semantics")
        defer { try? FileManager.default.removeItem(at: directory) }
        let machineURL = directory.appendingPathComponent("Looper.machine")
        try Self.makeSelfLoopMachine().write(to: machineURL, language: CBinding(), isSuspensible: true)
        let traditional = directory.appendingPathComponent("traditional.xmi")
        let reentry = directory.appendingPathComponent("reentry.xmi")
        try succeed([machineURL.path, "-f", "kernel-xmi", "-o", traditional.path])
        try succeed([machineURL.path, "-f", "kernel-xmi", "--semantics", "selfLoop=reentry", "-o", reentry.path])
        #expect(try Data(contentsOf: traditional) != Data(contentsOf: reentry))
    }

    /// A C machine whose first state has an entry section and loops on itself.
    static func makeSelfLoopMachine() -> Machine {
        let looping = State(name: "Looping")
        let done = State(name: "Done")
        let machine = Machine()
        machine.llfsm = LLFSM(
            states: [looping, done],
            transitions: [
                Transition(label: "count < 3", source: looping.id, target: looping.id),
                Transition(label: "count >= 3", source: looping.id, target: done.id),
            ],
            suspendState: nil)
        var entry = CBoilerplate()
        entry.sections[.onEntry] = "count = count + 1;"
        machine.stateBoilerplate[looping.id] = entry
        machine.stateBoilerplate[done.id] = CBoilerplate()
        var boilerplate = CBoilerplate()
        boilerplate.sections[.variables] = "int count;"
        machine.boilerplate = boilerplate
        return machine
    }

    // MARK: - Validation

    @Test("validation under the strict profile reports the opaque nodes of a relaxed model")
    func strictValidationFails() throws {
        let result = try FSMConvertRunner.run([FSMConvertRunner.kernelModel("OpaqueSampler").path, "--validate",
                                              "--profile", "strict"])
        #expect(result.status == FSMConvertRunner.failureStatus)
        #expect(result.standardError.contains("error: STRICT "), "\(result.standardError)")
    }

    @Test("validation succeeds on models that satisfy the profile",
          arguments: [("DoorInterlock", "strict"), ("OpaqueSampler", "relaxed")])
    func validationSucceeds(_ fixture: String, _ profile: String) throws {
        let result = try succeed([FSMConvertRunner.kernelModel(fixture).path, "--validate", "--profile", profile])
        #expect(!result.standardError.contains("error:"))
    }

    @Test("validation of a native machine transforms it to the kernel first")
    func nativeValidation() throws {
        let relaxed = try succeed([FSMConvertRunner.trafficLight.path, "--validate", "--profile", "relaxed", "-q"])
        #expect(relaxed.standardError.isEmpty, "--quiet suppresses warnings: \(relaxed.standardError)")
        let strict = try FSMConvertRunner.run([FSMConvertRunner.trafficLight.path, "--validate"])
        #expect(strict.status == FSMConvertRunner.failureStatus)
        #expect(strict.standardError.contains("STRICT"))
    }

    // MARK: - Invalid Options

    @Test("invalid option values are usage errors with a helpful message",
          arguments: [
            (["--semantics", "selfLoop=sometimes"], "traditional, reentry"),
            (["--semantics", "loops=reentry"], "selfLoop"),
            (["--semantics", "selfLoop"], "option=value"),
            (["--profile", "lax"], "strict"),
            (["--generator", "java"], "mtl"),
            (["--metamodel", "executive"], "kernel"),
            (["-f", "bogus"], "kernel-c"),
            (["-f", "java"], "--metamodel kernel"),
            (["--max-rounds=-1"], "must not be negative"),
            (["--entry", "late"], "ringlet"),
            (["--opaque", "ignore"], "havoc"),
            (["--param", "1x=2"], "1x"),
            (["--template-path", "/nonexistent/templates"], "not a directory"),
          ])
    func invalidValues(_ options: [String], _ hint: String) throws {
        let result = try FSMConvertRunner.run([FSMConvertRunner.trafficLight.path] + options + ["-o", "/nonexistent/out"])
        #expect(result.status == FSMConvertRunner.usageStatus, "\(options): \(result.standardError)")
        #expect(result.standardError.contains(hint), "\(options): \(result.standardError)")
    }

    @Test("the help describes the levels and the new options")
    func help() throws {
        let result = try succeed(["--help"])
        for text in ["--generator", "--metamodel", "--profile", "--semantics", "--entry", "--max-rounds", "--sanity",
                     "--opaque", "--param", "--template-path", "--reference-style", "--unset-features", "--validate",
                     "--quiet", "kernel-xmi", "smv"] {
            #expect(result.standardOutput.contains(text), "\(text) is missing from the help")
        }
    }
}
