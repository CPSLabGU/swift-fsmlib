//
//  KernelHostFixtureTests.swift
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

/// Tests that the checked-in HostTally documents are the builder output,
/// round-trip byte for byte and are relaxed models of their language.
@Suite("Kernel host-language fixtures")
struct KernelHostFixtureTests {
    /// Parse a host fixture document in a resource set that knows the metamodels.
    static func load(_ fixture: KernelHostFixture) async throws -> (text: String, resource: Resource) {
        let url = try #require(fixture.bundledURL, "missing host fixture \(fixture.rawValue)")
        let text = try String(contentsOf: url, encoding: .utf8)
        let resourceSet = ResourceSet()
        await (try await LLFSMMetamodels()).register(in: resourceSet)
        let parser = XMIParser(resourceSet: resourceSet)
        let resource = try await parser.parse(text, uri: url.absoluteString)
        #expect(await parser.diagnostics.isEmpty)
        return (text, resource)
    }

    /// Checks that each checked-in host fixture is the serialisation of its builder.
    ///
    /// When the regeneration variable is set, the fixture is first rewritten in the source tree.
    ///
    /// - Parameter fixture: The host fixture to check.
    @Test("each checked-in host fixture is the serialisation of its builder", arguments: KernelHostFixture.allCases)
    func fixtureMatchesBuilder(_ fixture: KernelHostFixture) async throws {
        let builder = try await KernelModelBuilder.make()
        fixture.build(with: builder)
        let text = try await KernelFixtureTests.serialise(await builder.resource())
        if ProcessInfo.processInfo.environment[KernelFixture.regenerationVariable] != nil {
            let url = fixture.sourceURL()
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try text.write(to: url, atomically: true, encoding: .utf8)
        }
        let url = try #require(fixture.bundledURL, "missing host fixture \(fixture.rawValue)")
        #expect(try String(contentsOf: url, encoding: .utf8) == text)
    }

    /// Checks that each host fixture reads and reserialises byte for byte.
    ///
    /// - Parameter fixture: The host fixture to check.
    @Test("each host fixture reads and reserialises byte for byte", arguments: KernelHostFixture.allCases)
    func fixtureRoundTrips(_ fixture: KernelHostFixture) async throws {
        let (text, resource) = try await Self.load(fixture)
        #expect(try await KernelFixtureTests.serialise(resource) == text)
    }

    /// Checks that each host fixture is valid under the relaxed profile and is rejected under the strict profile only for its opaque nodes.
    ///
    /// - Parameter fixture: The host fixture to check.
    @Test("each host fixture is relaxed: valid when relaxed, rejected only for opaque nodes when strict",
          arguments: KernelHostFixture.allCases)
    func fixturesValidate(_ fixture: KernelHostFixture) async throws {
        let kernel = try await KernelMetamodel()
        let (_, resource) = try await Self.load(fixture)
        let relaxed = await KernelValidator(metamodel: kernel, profile: .relaxed).validate(resource)
        let strict = await KernelValidator(metamodel: kernel, profile: .strict).validate(resource)
        #expect(relaxed.isEmpty, "\(relaxed)")
        #expect(!strict.isEmpty)
        #expect(strict.allSatisfy { $0.rule == .strictProfile && $0.severity == .error }, "\(strict)")
    }
}
