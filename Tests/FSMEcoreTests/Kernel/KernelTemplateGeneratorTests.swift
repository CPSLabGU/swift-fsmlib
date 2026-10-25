//
//  KernelTemplateGeneratorTests.swift
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

/// Tests of the kernel target list, the template sets and the generation
/// driver, independent of the content of the generated files.
@Suite("Kernel template generator")
@MainActor
struct KernelTemplateGeneratorTests {
    /// The files that each target writes for an arrangement called `Model`.
    static let expectedFiles: [KernelTarget: [String]] = [
        .c: ["Model.c"], .cpp: ["Model.cpp"], .swift: ["Model.swift"], .java: ["Model.java"],
        .smv: ["Model.smv"], .tla: ["Model.cfg", "Model.tla"], .dot: ["Model.dot"],
    ]

    /// Load a kernel fixture into a resource.
    static func resource(_ fixture: KernelFixture) async throws -> Resource {
        try await KernelFixtureTests.load(fixture).resource
    }

    /// The generator with the shared kernel metamodel.
    static func generator() async throws -> KernelTemplateGenerator {
        KernelTemplateGenerator(metamodel: try await KernelMetamodel())
    }

    /// Checks that the kernel targets have the documented identifiers.
    @Test("the kernel targets have the documented identifiers")
    func targetIdentifiers() {
        #expect(KernelTarget.allCases.map(\.rawValue)
                == ["kernel-c", "kernel-cpp", "kernel-swift", "kernel-java", "smv", "tla", "dot"])
        #expect(KernelTarget(rawValue: "kernel-c") == .c)
        #expect(KernelTarget(rawValue: "c") == nil)
    }

    /// Checks that execution, verification and diagram targets are told apart.
    @Test("execution, verification and diagram targets are told apart")
    func targetKinds() {
        #expect(KernelTarget.allCases.filter(\.isExecutionTarget) == [.c, .cpp, .swift, .java])
        #expect(KernelTarget.allCases.filter(\.isVerificationTarget) == [.smv, .tla])
        #expect(!KernelTarget.dot.isExecutionTarget && !KernelTarget.dot.isVerificationTarget)
    }

    /// Checks that every kernel target has a bundled template set.
    @Test("every kernel target is bundled")
    func bundledTargets() {
        #expect(KernelTemplateGenerator.availableTargets() == KernelTarget.allCases)
    }

    /// Checks that each template set names its target, its main module and the shared expression modules.
    ///
    /// - Parameter target: The target whose template set is checked.
    /// - Throws: An error if the template set cannot be found.
    @Test("each template set names its target, its main module and the shared expression modules",
          arguments: KernelTarget.allCases)
    func templateSets(_ target: KernelTarget) throws {
        let set = try KernelTemplateGenerator.templateSet(for: target)
        #expect(set.name == target.rawValue)
        #expect(!set.summary.isEmpty)
        #expect(set.mainModule == "generate")
        #expect(set.mainTemplate == "generate")
        #expect(set.imports == ["../../expressions"])
    }

    /// Checks that verification targets validate strictly unless opaque nodes are havocked.
    @Test("verification targets validate strictly unless opaque nodes are havocked")
    func validationProfiles() {
        for target in KernelTarget.allCases {
            let expected: ValidationProfile = target.isVerificationTarget ? .strict : .relaxed
            #expect(target.validationProfile(parameters: [:]) == expected)
            #expect(target.validationProfile(parameters: [KernelTemplateParameter.opaque: "reject"]) == expected)
        }
        let havoc = [KernelTemplateParameter.opaque: KernelOpaqueTreatment.havoc.rawValue]
        #expect(KernelTarget.smv.validationProfile(parameters: havoc) == .relaxed)
        #expect(KernelTarget.tla.validationProfile(parameters: havoc) == .relaxed)
        #expect(KernelTarget.c.validationProfile(parameters: havoc) == .relaxed)
    }

    /// Checks that each target renders the files of its template set.
    ///
    /// - Parameter target: The target to render.
    /// - Throws: An error if the model cannot be built or rendered.
    @Test("each target renders the files of its template set", arguments: KernelTarget.allCases)
    func renderedFiles(_ target: KernelTarget) async throws {
        let builder = try await KernelModelBuilder.make()
        let system = builder.arrangement("Model")
        let machine = builder.machine("Only", in: system)
        let state = builder.state("Resting", in: machine)
        builder.initial(state, of: machine)
        builder.instance("only", of: machine, in: system)
        let files = try await Self.generator().render(target, resource: await builder.resource())
        #expect(files.map(\.path) == Self.expectedFiles[target])
        #expect(files.allSatisfy { !$0.content.isEmpty })
    }

    /// Checks that code targets write the functions of host declarations after their declarations.
    ///
    /// - Parameter target: The code target to render.
    /// - Throws: An error if the model cannot be built or rendered.
    @Test("code targets write the functions of host declarations after their declarations",
          arguments: KernelTarget.allCases.filter(\.isExecutionTarget))
    func hostFunctions(_ target: KernelTarget) async throws {
        let builder = try await KernelModelBuilder.make()
        let system = builder.arrangement("Model")
        let machine = builder.machine("Only", in: system)
        let host = builder.hostDeclarations(in: machine, language: "", includes: "", declarations: "// declared here")
        builder.set(host, .functions, "// functions here")
        builder.set(host, .includePaths, "// include paths are not written")
        let state = builder.state("Resting", in: machine)
        builder.initial(state, of: machine)
        builder.instance("only", of: machine, in: system)
        let files = try await Self.generator().render(target, resource: await builder.resource())
        let content = try #require(files.first?.content)
        let declared = try #require(content.range(of: "// declared here"))
        let functions = try #require(content.range(of: "// functions here"))
        #expect(declared.upperBound <= functions.lowerBound)
        #expect(!content.contains("// include paths are not written"))
    }

    /// Checks that generating to a directory writes the rendered files and returns their locations.
    ///
    /// - Throws: An error if the generation or the reading of the files fails.
    @Test("generating to a directory writes the rendered files and returns their locations")
    func generateToDirectory() async throws {
        let generator = try await Self.generator()
        let resource = try await Self.resource(.turnTakingRelay)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("kernel-generator-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let urls = try await generator.generate(.tla, resource: resource, to: directory)
        let rendered = try await generator.render(.tla, resource: resource)
        #expect(urls.map(\.lastPathComponent) == rendered.map(\.path))
        for (url, file) in zip(urls, rendered) {
            #expect(try String(contentsOf: url, encoding: .utf8) == file.content)
        }
    }

    /// Checks that a model that the strict profile of a target rejects is not generated.
    ///
    /// - Throws: An error if the fixture cannot be loaded.
    @Test("a model that the target's profile rejects is not generated")
    func strictValidationAborts() async throws {
        let resource = try await Self.resource(.opaqueSampler)
        do {
            _ = try await Self.generator().render(.smv, resource: resource)
            Issue.record("expected the strict profile to reject OpaqueSampler")
        } catch KernelTemplateGeneratorError.invalidModel(let target, let diagnostics) {
            #expect(target == .smv)
            #expect(!diagnostics.isEmpty)
            #expect(diagnostics.allSatisfy { $0.rule == .strictProfile })
        }
    }

    /// Checks that a verification target rejects opaque nodes by default and names the offending elements.
    ///
    /// - Throws: An error if the fixture cannot be loaded.
    @Test("a verification target rejects opaque nodes by default and names the offending element")
    func opaqueRejected() async throws {
        let resource = try await Self.resource(.opaqueSampler)
        for target in [KernelTarget.smv, .tla] {
            do {
                _ = try await Self.generator().render(target, resource: resource, parameters: [:], validating: false)
                Issue.record("expected \(target) to reject the opaque nodes of OpaqueSampler")
            } catch KernelTemplateGeneratorError.templateErrors(let failed, let messages) {
                #expect(failed == target)
                #expect(messages.contains { $0.hasPrefix("/OpaqueSampler/machines[Sampler]/states[Wait]/transitions[0]/label: ") },
                        "\(messages)")
                #expect(messages.contains { $0.hasPrefix("/OpaqueSampler/machines[Sampler]/states[Sample]/actions[0]: ") },
                        "\(messages)")
                #expect(messages.contains { $0.hasPrefix("/OpaqueSampler/types[Reading]: ") }, "\(messages)")
            }
        }
    }

    /// Checks that havocked opaque nodes are generated with a warning in the file header.
    ///
    /// - Throws: An error if the fixture cannot be loaded or rendered.
    @Test("havocked opaque nodes are generated with a warning in the file header")
    func opaqueHavocked() async throws {
        let resource = try await Self.resource(.opaqueSampler)
        let parameters = [KernelTemplateParameter.opaque: KernelOpaqueTreatment.havoc.rawValue]
        for target in [KernelTarget.smv, .tla] {
            let files = try await Self.generator().render(target, resource: resource, parameters: parameters)
            let main = try #require(files.first { $0.path.hasSuffix(target == .smv ? ".smv" : ".tla") })
            #expect(main.content.contains("WARNING"), "\(main.content.prefix(400))")
        }
    }

    /// Checks that a code target rejects opaque text written for another language.
    ///
    /// - Throws: An error if the fixture cannot be loaded.
    @Test("a code target rejects opaque text written for another language")
    func foreignOpaqueTextRejected() async throws {
        let resource = try await Self.resource(.opaqueSampler)
        for target in [KernelTarget.cpp, .swift, .java] {
            do {
                _ = try await Self.generator().render(target, resource: resource)
                Issue.record("expected \(target) to reject the C text of OpaqueSampler")
            } catch KernelTemplateGeneratorError.templateErrors(let failed, let messages) {
                #expect(failed == target)
                #expect(messages.contains { $0.hasPrefix("/OpaqueSampler/machines[Sampler]/states[Wait]/transitions[0]/label: ") },
                        "\(messages)")
            }
        }
    }

    /// Checks that an unknown value of a template parameter is a generation error.
    ///
    /// - Throws: An error if the fixture cannot be loaded.
    @Test("an unknown value of a template parameter is a generation error")
    func unknownParameterValue() async throws {
        let resource = try await Self.resource(.turnTakingRelay)
        let cases = [
            (KernelTarget.smv, KernelTemplateParameter.entry),
            (.tla, KernelTemplateParameter.entry),
            (.smv, KernelTemplateParameter.opaque),
            (.tla, KernelTemplateParameter.opaque)
        ]
        for (target, name) in cases {
            do {
                _ = try await Self.generator().render(target, resource: resource, parameters: [name: "sideways"])
                Issue.record("expected \(target) to reject \(name)=sideways")
            } catch KernelTemplateGeneratorError.templateErrors(_, let messages) {
                #expect(messages.contains { $0.contains(name) && $0.contains("sideways") }, "\(messages)")
            }
        }
    }

    /// Checks that printing a value whose type is unknown is a generation error.
    ///
    /// - Throws: An error if the model cannot be built.
    @Test("printing a value whose type is unknown is a generation error")
    func untypedPrintRejected() async throws {
        let builder = try await KernelModelBuilder.make()
        let system = builder.arrangement("Model")
        builder.set(system, .language, "c")
        let machine = builder.machine("Only", in: system)
        let state = builder.state("Resting", in: machine)
        builder.initial(state, of: machine)
        builder.action(state, builder.printLine("value", [builder.opaqueExpression("rand()")]))
        builder.instance("only", of: machine, in: system)
        do {
            _ = try await Self.generator().render(.c, resource: await builder.resource())
            Issue.record("expected the C target to reject printing an untyped opaque expression")
        } catch KernelTemplateGeneratorError.templateErrors(let target, let messages) {
            #expect(target == .c)
            #expect(messages.contains { $0.hasPrefix("/Model/machines[Only]/states[Resting]/actions[0]/values[0]: ") },
                    "\(messages)")
        }
    }

    /// Checks that generation errors describe the target and every message.
    @Test("generation errors describe the target and every message")
    func errorDescriptions() {
        let error = KernelTemplateGeneratorError.templateErrors(.smv, ["/A/types[T]: first", "/A: second"])
        #expect(error.description.contains("smv"))
        #expect(error.description.contains("/A/types[T]: first"))
        #expect(error.description.contains("/A: second"))
        #expect(KernelTemplateGeneratorError.missingTemplateSet(.dot).description.contains("dot"))
        #expect(KernelTemplateGeneratorError.noArrangement.description.contains("arrangement"))
    }
}
