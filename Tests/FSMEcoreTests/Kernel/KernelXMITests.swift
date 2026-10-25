//
//  KernelXMITests.swift
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

/// Tests that kernel and sectioned documents are read with the classes of
/// their namespaces and written back unchanged.
@Suite("Kernel and sectioned XMI")
struct KernelXMITests {
    /// A sectioned arrangement whose state sections hold kernel statements.
    static let sectionedDocument = """
        <?xml version="1.0" encoding="UTF-8"?>
        <sectioned:Arrangement xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" \
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \
        xmlns:sectioned="http://cpslabgu.github.io/llfsm/sectioned" \
        xmlns:kernel="http://cpslabgu.github.io/llfsm/kernel" name="Blinker">
          <types xsi:type="kernel:BooleanType" name="Bool"/>
          <variables name="lamp" type="kernel:BooleanType #//@types.0"/>
          <machines name="Blink" initial="#//@machines.0/@states.0">
            <states name="Dark">
              <onEntry xsi:type="kernel:Assignment">
                <target variable="#//@variables.0"/>
                <value xsi:type="kernel:BooleanLiteral"/>
              </onEntry>
              <transitions target="#//@machines.0/@states.1">
                <label xsi:type="kernel:BinaryExpression" operation="greaterOrEqual">
                  <left xsi:type="sectioned:StateTimeExpression" unit="seconds"/>
                  <right xsi:type="kernel:IntegerLiteral" value="1"/>
                </label>
              </transitions>
            </states>
            <states name="Bright">
              <onEntry xsi:type="kernel:Assignment">
                <target variable="#//@variables.0"/>
                <value xsi:type="kernel:BooleanLiteral" value="true"/>
              </onEntry>
              <internal xsi:type="kernel:Print" text="lamp">
                <values xsi:type="kernel:VariableReference" variable="#//@variables.0"/>
              </internal>
              <transitions target="#//@machines.0/@states.0">
                <label xsi:type="sectioned:InStateExpression" instance="#//@instances.0" state="#//@machines.0/@states.1"/>
              </transitions>
            </states>
          </machines>
          <instances name="blinker" machine="#//@machines.0"/>
        </sectioned:Arrangement>

        """

    /// Parse a document in a resource set that knows the metamodels.
    static func parse(_ text: String) async throws -> Resource {
        let resourceSet = ResourceSet()
        await (try await LLFSMMetamodels()).register(in: resourceSet)
        let parser = XMIParser(resourceSet: resourceSet)
        let resource = try await parser.parse(text, uri: "memory:/document.xmi")
        #expect(await parser.diagnostics.isEmpty)
        return resource
    }

    /// The class names of the objects of a resource in containment order, qualified by package.
    static func qualifiedClasses(of resource: Resource, metamodels: LLFSMMetamodels) async -> [String] {
        let index = await KernelModelIndex(resource: resource)
        return index.order.compactMap { index.object($0) }.map { object in
            if metamodels.kernel.package.getEClass(object.eClass.name)?.id == object.eClass.id {
                return "kernel:" + object.eClass.name
            }
            if metamodels.sectioned.package.getEClass(object.eClass.name)?.id == object.eClass.id {
                return "sectioned:" + object.eClass.name
            }
            return "?:" + object.eClass.name
        }
    }

    /// Verify that each namespace of a sectioned document selects the classes of its own package.
    @Test("a document with kernel and sectioned namespaces is read with the classes of each package")
    func namespacesSelectClasses() async throws {
        let metamodels = try await LLFSMMetamodels()
        let resource = try await Self.parse(Self.sectionedDocument)
        #expect(await Self.qualifiedClasses(of: resource, metamodels: metamodels) == [
            "sectioned:Arrangement", "kernel:BooleanType", "kernel:Variable", "sectioned:Machine",
            "sectioned:State", "kernel:Assignment", "kernel:VariableReference", "kernel:BooleanLiteral",
            "sectioned:Transition", "kernel:BinaryExpression", "sectioned:StateTimeExpression",
            "kernel:IntegerLiteral", "sectioned:State", "kernel:Assignment", "kernel:VariableReference",
            "kernel:BooleanLiteral", "kernel:Print", "kernel:VariableReference", "sectioned:Transition",
            "sectioned:InStateExpression", "sectioned:Instance",
        ])
    }

    /// Verify that a sectioned document reserialises byte for byte.
    @Test("a sectioned document with kernel statements and expressions reserialises byte for byte")
    func sectionedDocumentRoundTrips() async throws {
        let resource = try await Self.parse(Self.sectionedDocument)
        #expect(try await KernelFixtureTests.serialise(resource) == Self.sectionedDocument)
    }

    /// Verify that references and attribute values are preserved when reading a document.
    @Test("references and values survive a round trip through the document")
    func valuesSurvive() async throws {
        let metamodels = try await LLFSMMetamodels()
        let resource = try await Self.parse(Self.sectionedDocument)
        let index = await KernelModelIndex(resource: resource)
        let objects = index.order.compactMap { index.object($0) }
        let time = try #require(objects.first { $0.eClass.id == metamodels.sectioned.stateTimeExpressionClass.id })
        #expect(time.string(.unit) == SectionedTimeUnit.seconds.rawValue)
        let machine = try #require(objects.first { $0.eClass.id == metamodels.sectioned.machineClass.id })
        let states = index.objects(.states, of: machine)
        #expect(states.map { $0.string(.name) } == ["Dark", "Bright"])
        #expect(machine.identifier(.initial) == states.first?.id)
        let observation = try #require(objects.first {
            $0.eClass.id == metamodels.sectioned.inStateExpressionClass.id
        })
        #expect(observation.identifier(.state) == states.last?.id)
        let literals = objects.filter { $0.eClass.id == metamodels.kernel.booleanLiteralClass.id }
        #expect(literals.map { $0.bool(.value) } == [false, true])
    }

    /// Verify that a built kernel model is written with only the kernel namespace and reads back unchanged.
    @Test("a built kernel model is written with the kernel namespace and read back with the same classes")
    func builtKernelModelRoundTrips() async throws {
        let builder = try await KernelModelBuilder.make()
        KernelFixture.schedulerPool.build(with: builder)
        let metamodels = try await LLFSMMetamodels()
        let built = await builder.resource()
        let text = try await KernelFixtureTests.serialise(built)
        #expect(text.contains("xmlns:kernel=\"\(LLFSMMetamodels.kernelNamespaceURI)\""))
        #expect(!text.contains("xmlns:sectioned="))
        let read = try await Self.parse(text)
        let expected = await Self.qualifiedClasses(of: built, metamodels: metamodels)
        #expect(await Self.qualifiedClasses(of: read, metamodels: metamodels) == expected)
        #expect(!expected.contains { $0.hasPrefix("?") || $0.hasPrefix("sectioned") })
        #expect(try await KernelFixtureTests.serialise(read) == text)
    }
}
