//
//  TemplateBindingTests.swift
//  FSMEcoreTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import MTL
import Testing
@testable import FSM
@testable import FSMEcore

/// Tests for the template sets, the template binding and its single-file storage.
@Suite("Template binding")
@MainActor
struct TemplateBindingTests {
    /// The formats that have a Swift output language.
    nonisolated static let writableFormats = Format.allCases.filter { outputLanguage(for: $0) != nil }

    /// Check that every format with a Swift output language has a template set declaring the same language.
    ///
    /// - Throws: Any error from loading the template sets.
    @Test("Every format with a Swift output language has a template set declaring the same language")
    func templateSetsCoverFormats() throws {
        let engine = try StructuralTemplateEngine()
        let sets = try engine.templateSets()
        #expect(Set(sets.map(\.set.name)) == ["c", "objcpp", "scxml"])
        for format in Self.writableFormats {
            let (set, _) = try engine.templateSet(for: format)
            #expect(set.writes(format))
            #expect(set.language == outputLanguage(for: format)?.name)
            #expect(set.isSingleFile == format.isSingleFile)
        }
    }

    /// Check that formats without a template set are rejected.
    ///
    /// - Throws: Any error from loading the test machine.
    @Test("Formats without a template set are rejected")
    func unsupportedFormat() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        await #expect(throws: StructuralTemplateGeneratorError.unsupportedFormat(Format.swift.rawValue)) {
            _ = try await TemplateBinding.make(for: machine, named: "TrafficLight", format: .swift, isSuspensible: true)
        }
        let arrangement = Arrangement(namedInstances: [
            Instance(name: "Light", typeFile: "TrafficLight.machine", machine: machine)
        ])
        await #expect(throws: StructuralTemplateGeneratorError.unsupportedFormat(Format.scxml.rawValue)) {
            _ = try await TemplateBinding.make(for: arrangement, named: "Lights", format: .scxml, isSuspensible: true)
        }
    }

    /// Check that a template set directory without a readable manifest is reported.
    ///
    /// - Throws: Any error from preparing the temporary directory.
    @Test("A template set directory without a readable manifest is reported")
    func invalidManifest() throws {
        let root = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "template-sets")
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appendingPathComponent("broken", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("{".utf8).write(to: directory.appendingPathComponent(StructuralTemplateEngine.manifestName))
        #expect(throws: StructuralTemplateGeneratorError.invalidTemplateSet("broken")) {
            try StructuralTemplateEngine(root: root).templateSets()
        }
    }

    /// Check that a binding declares the language of its set and delegates reading.
    ///
    /// - Throws: Any error from creating the binding.
    @Test("The binding declares the language of its set and delegates reading")
    func bindingIdentity() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let binding = try await TemplateBinding.make(for: machine, named: "TrafficLight", format: .cpp, isSuspensible: false)
        #expect(binding.name == ObjCPPBinding().name)
        #expect(binding.format == .cpp)
        #expect(binding.bundleName == "TrafficLight")
        #expect(!binding.isSingleFile)
        #expect(binding.machineDirectories.isEmpty)
        #expect(binding.singleFileContents == nil)
        #expect(binding.files["States"].flatMap { String(bytes: $0, encoding: .utf8) } == machine.llfsm.stateNames.joined(separator: "\n"))
        #expect(binding.reader.name == ObjCPPBinding().name)
    }

    /// Check that writing to a bundle with another name is rejected.
    ///
    /// - Throws: Any error from creating the binding or the temporary directory.
    @Test("Writing to a bundle with another name is rejected")
    func nameMismatch() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let binding = try await TemplateBinding.make(for: machine, named: "TrafficLight", format: .c, isSuspensible: true)
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "template-name")
        defer { try? FileManager.default.removeItem(at: directory) }
        #expect(throws: TemplateBindingError.nameMismatch(expected: "TrafficLight", found: "Other")) {
            try machine.write(to: directory.appendingPathComponent("Other.machine"), language: binding, isSuspensible: true)
        }
    }

    /// Check that rendered files are placed into nested directories and that invalid paths are rejected.
    ///
    /// - Throws: Any error from placing the files.
    @Test("Rendered files are placed into nested directories")
    func placement() throws {
        let files = ["a.txt": Data("a".utf8), "sub/b.txt": Data("b".utf8), "sub/deeper/c.txt": Data("c".utf8)]
        let binding = TemplateBinding(name: "test", format: .c, bundleName: "Test", files: files)
        let wrapper = FileWrapper(directoryWithFileWrappers: [:])
        try binding.place(files, into: wrapper)
        try binding.place(files, into: wrapper)
        #expect(wrapper.fileWrappers?["a.txt"]?.regularFileContents == Data("a".utf8))
        let sub = try #require(wrapper.fileWrappers?["sub"])
        #expect(sub.isDirectory)
        #expect(sub.fileWrappers?["b.txt"]?.regularFileContents == Data("b".utf8))
        #expect(sub.fileWrappers?["deeper"]?.fileWrappers?["c.txt"]?.regularFileContents == Data("c".utf8))
        #expect(throws: TemplateBindingError.invalidPath("/x")) {
            try binding.place(["/x": Data()], into: wrapper)
        }
    }

    /// Check that arrangement bindings separate the files of the arrangement and of each machine.
    @Test("Arrangement bindings separate the files of the arrangement and of each machine")
    func arrangementFiles() {
        let files = [
            "Machines": Data("m".utf8),
            "infrastructure/CLMachine.h": Data("h".utf8),
            "Counter.machine/States": Data("s".utf8),
        ]
        let binding = TemplateBinding(
            name: "test", format: .c, bundleName: "Test", files: files, machineDirectories: ["Counter.machine"])
        #expect(Set(binding.bundleFiles.keys) == ["Machines", "infrastructure/CLMachine.h"])
        #expect(binding.machineFiles(in: "Counter.machine") == ["States": Data("s".utf8)])
        #expect(binding.machineFiles(in: "Other.machine").isEmpty)
    }

    /// Check that machine bundles unknown to the binding are rejected.
    @Test("Machine bundles of an arrangement that the binding does not know are rejected")
    func unknownBundle() {
        let binding = TemplateBinding(
            name: "test", format: .c, bundleName: "Test", files: [:], machineDirectories: ["Counter.machine"])
        let wrapper = FileWrapper(directoryWithFileWrappers: [:])
        wrapper.preferredFilename = "Other.machine"
        #expect(throws: TemplateBindingError.unknownBundle("Other.machine")) {
            try binding.addLanguage(to: wrapper)
        }
    }

    /// Check that single-file bindings write their file and reject arrangements.
    ///
    /// - Throws: Any error from creating the binding or writing the file.
    @Test("Single-file bindings write their file and reject arrangements")
    func singleFile() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let binding = try await TemplateBinding.make(for: machine, named: "TrafficLight", format: .scxml, isSuspensible: true)
        #expect(binding.isSingleFile)
        let contents = try #require(binding.singleFileContents)
        #expect(throws: TemplateBindingError.arrangementsUnsupported) {
            try binding.createArrangementWrapper(at: URL(fileURLWithPath: "Lights.arrangement"))
        }
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "template-single")
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Light.scxml")
        let storage = try binding.createWrapper(at: url, for: machine)
        #expect(storage is TemplateFileStorage)
        try storage.write(to: url)
        #expect(try Data(contentsOf: url) == contents)
        #expect(throws: TemplateBindingError.readingUnsupported) { _ = try TemplateFileStorage(url: url) }
        let plain = TemplateFileStorage(machine: machine, named: "Plain.scxml")
        #expect(throws: TemplateBindingError.missingFile) { try plain.write(to: url) }
    }

    /// Check that errors describe the problem.
    @Test("Errors describe the problem")
    func messages() {
        let errors: [TemplateBindingError] = [
            .arrangementsUnsupported, .unknownBundle("A.machine"), .nameMismatch(expected: "A", found: "B"),
            .invalidPath("/x"), .readingUnsupported, .missingFile,
        ]
        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
        #expect(TemplateBindingError.unknownBundle("A.machine").errorDescription?.contains("A.machine") == true)
    }

    /// Check that templates can tell set features from unset ones.
    ///
    /// - Throws: Any error from parsing or running the template.
    @Test("Templates can tell set features from unset ones")
    func featureSetness() async throws {
        let metamodel = try await LLFSMMetamodel()
        let resource = Resource(uri: "memory:/setness.xmi")
        var boilerplate = DynamicEObject(eClass: metamodel.boilerplateClass)
        boilerplate.eSet("includes", value: "")
        await resource.add(boilerplate)
        let module = try await MTLParser().parse("""
            [module m('\(metamodel.package.nsURI)')/]
            [template main(b : Boilerplate)][b.eIsSet('includes')/]|[b.eIsSet('variables')/][/template]
            """, filename: "m.mtl")
        let strategy = MTLInMemoryStrategy()
        let generator = MTLGenerator(
            module: module, generationStrategy: strategy, serviceProviders: [StructuralTemplateServices()])
        try await generator.generate(mainTemplate: "main", arguments: [boilerplate], models: ["IN": resource])
        #expect(await strategy.getGeneratedFiles()["stdout"] == "true|false")
    }
}
