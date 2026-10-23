//
//  KernelFixtureTests.swift
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

/// Tests that the checked-in fixtures are the builder output, round-trip
/// byte for byte and validate as intended.
@Suite("Kernel and sectioned fixtures")
struct KernelFixtureTests {
    /// Serialise a resource with the fixture options.
    static func serialise(_ resource: Resource) async throws -> String {
        var diagnostics = ConversionDiagnostics()
        let text = try await XMISerializer(options: KernelFixture.serialisationOptions)
            .serialize(resource, diagnostics: &diagnostics)
        #expect(diagnostics.isEmpty, "\(diagnostics.warnings)")
        return text
    }

    /// Parse a fixture document in a resource set that knows the metamodels.
    static func load(_ fixture: KernelFixture) async throws -> (text: String, resource: Resource) {
        let url = try #require(fixture.bundledURL, "missing fixture \(fixture.rawValue)")
        let text = try String(contentsOf: url, encoding: .utf8)
        let resourceSet = ResourceSet()
        await (try await LLFSMMetamodels()).register(in: resourceSet)
        let parser = XMIParser(resourceSet: resourceSet)
        let resource = try await parser.parse(text, uri: url.absoluteString)
        #expect(await parser.diagnostics.isEmpty)
        return (text, resource)
    }

    @Test("each checked-in fixture is the serialisation of its builder", arguments: KernelFixture.allCases)
    func fixtureMatchesBuilder(_ fixture: KernelFixture) async throws {
        let builder = try await KernelModelBuilder.make()
        fixture.build(with: builder)
        let text = try await Self.serialise(await builder.resource())
        if ProcessInfo.processInfo.environment[KernelFixture.regenerationVariable] != nil {
            let url = fixture.sourceURL()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }
        let url = try #require(fixture.bundledURL, "missing fixture \(fixture.rawValue)")
        #expect(try String(contentsOf: url, encoding: .utf8) == text)
    }

    @Test("each fixture reads and reserialises byte for byte", arguments: KernelFixture.allCases)
    func fixtureRoundTrips(_ fixture: KernelFixture) async throws {
        let (text, resource) = try await Self.load(fixture)
        #expect(try await Self.serialise(resource) == text)
    }

    @Test("each kernel fixture is valid under the profiles it is written for",
          arguments: KernelFixture.allCases.filter { !$0.isSectioned })
    func kernelFixturesValidate(_ fixture: KernelFixture) async throws {
        let kernel = try await KernelMetamodel()
        let (_, resource) = try await Self.load(fixture)
        let strict = await KernelValidator(metamodel: kernel, profile: .strict).validate(resource)
        let relaxed = await KernelValidator(metamodel: kernel, profile: .relaxed).validate(resource)
        #expect(relaxed.isEmpty, "\(relaxed)")
        if fixture.isStrict {
            #expect(strict.isEmpty, "\(strict)")
        } else {
            #expect(!strict.isEmpty)
            #expect(strict.allSatisfy { $0.rule == .strictProfile && $0.severity == .error }, "\(strict)")
        }
    }

    @Test("the kernel fixtures include at least three strict models and one relaxed model")
    func fixtureCoverage() {
        let kernelFixtures = KernelFixture.allCases.filter { !$0.isSectioned }
        #expect(kernelFixtures.filter(\.isStrict).count >= 3)
        #expect(kernelFixtures.filter { !$0.isStrict }.count == 1)
        #expect(KernelFixture.allCases.filter(\.isSectioned).count >= 2)
    }
}
