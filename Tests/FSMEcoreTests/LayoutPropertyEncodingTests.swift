//
//  LayoutPropertyEncodingTests.swift
//  FSMEcoreTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import Testing
@testable import FSM
@testable import FSMEcore

/// Tests for the typed encoding of additional state layout properties.
@Suite("Layout property encoding")
struct LayoutPropertyEncodingTests {
    /// A reference date with whole seconds, as property lists store them.
    static let referenceDate = Date(timeIntervalSince1970: 1_790_000_000)

    /// Additional layout properties covering every property list value type.
    static var sampleProperties: [String: Any] {
        [
            "real": 1.0,
            "zero": 0.0,
            "fraction": 0.84545904397964478,
            "integer": 42,
            "negative": -7,
            "flag": true,
            "off": false,
            "text": "a < b & c",
            "bytes": Data([0, 1, 2, 3, 254, 255]),
            "when": referenceDate,
            "list": [1.5, "two", false] as [Any],
            "nested": ["alpha": 1.0, "red": 0.5, "inner": ["deep": 3] as [String: Any]] as [String: Any],
        ]
    }

    /// Create a machine with one state whose layout carries the sample properties.
    ///
    /// - Returns: The machine and the identifier of its state.
    static func makeMachine() -> (Machine, StateID) {
        let machine = Machine()
        let state = State(name: "Only")
        machine.llfsm = LLFSM(states: [state], transitions: [], suspendState: nil)
        var layout = StateLayout(index: 0)
        layout.extraProperties = sampleProperties
        machine.stateLayout = [state.id: layout]
        return (machine, state.id)
    }

    /// Check that decoded properties keep their values and value types.
    ///
    /// - Parameter properties: The decoded additional properties.
    static func expectSampleProperties(_ properties: [String: Any]) {
        #expect(properties.count == sampleProperties.count)
        #expect(kind(of: properties["real"]) == "real")
        #expect(properties["real"] as? Double == 1.0)
        #expect(kind(of: properties["zero"]) == "real")
        #expect(properties["fraction"] as? Double == 0.84545904397964478)
        #expect(kind(of: properties["integer"]) == "integer")
        #expect(properties["integer"] as? Int == 42)
        #expect(properties["negative"] as? Int == -7)
        #expect(kind(of: properties["flag"]) == "boolean")
        #expect(properties["flag"] as? Bool == true)
        #expect(properties["off"] as? Bool == false)
        #expect(properties["text"] as? String == "a < b & c")
        #expect(properties["bytes"] as? Data == Data([0, 1, 2, 3, 254, 255]))
        #expect(properties["when"] as? Date == referenceDate)
        let list = properties["list"] as? [Any]
        #expect(list?.count == 3)
        #expect(list?.first as? Double == 1.5)
        #expect(list?.dropFirst().first as? String == "two")
        let nested = properties["nested"] as? [String: Any]
        #expect(nested?["red"] as? Double == 0.5)
        #expect(kind(of: nested?["alpha"]) == "real")
        #expect((nested?["inner"] as? [String: Any])?["deep"] as? Int == 3)
    }

    /// Classify a property list number the way the property list writer does.
    ///
    /// - Parameter value: The value to classify.
    /// - Returns: `boolean`, `real`, `integer`, or `other`.
    static func kind(of value: Any?) -> String {
        guard let value else { return "other" }
        switch PropertyListValueKind(value) {
        case .boolean: return "boolean"
        case .real: return "real"
        case .integer: return "integer"
        default: return "other"
        }
    }

    @Test("Typed properties survive encoding and decoding")
    func codecRoundTrip() async throws {
        let (machine, stateID) = Self.makeMachine()
        let metamodel = try await LLFSMMetamodel()
        let codec = MachineEcoreCodec(metamodel: metamodel)
        let resource = Resource(uri: "memory:/properties.xmi")
        let root = await codec.encode(machine, name: "Properties", into: resource)
        let decoded = try await codec.decode(root, from: resource)
        let state = try #require(decoded.machine.llfsm.states.first)
        #expect(decoded.machine.llfsm.stateName(for: state) == machine.llfsm.stateName(for: stateID))
        Self.expectSampleProperties(decoded.machine.stateLayout[state]?.extraProperties ?? [:])
    }

    @Test("Typed properties survive an XMI document")
    func xmiRoundTrip() async throws {
        let (machine, _) = Self.makeMachine()
        let roundTrip = XMIRoundTrip(metamodel: try await LLFSMMetamodel())
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "layout-properties")
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Properties.xmi")
        var writeDiagnostics = ConversionDiagnostics()
        try await roundTrip.write(machine: machine, name: "Properties", to: url, diagnostics: &writeDiagnostics)
        var readDiagnostics = ConversionDiagnostics()
        let decoded = try await roundTrip.readMachine(from: url, diagnostics: &readDiagnostics)
        #expect(writeDiagnostics.isEmpty)
        #expect(readDiagnostics.isEmpty)
        let state = try #require(decoded.machine.llfsm.states.first)
        Self.expectSampleProperties(decoded.machine.stateLayout[state]?.extraProperties ?? [:])
    }

    @Test("Properties stored as JSON text are still read")
    func legacyJSONProperties() async throws {
        let metamodel = try await LLFSMMetamodel()
        let codec = MachineEcoreCodec(metamodel: metamodel)
        let (machine, _) = Self.makeMachine()
        machine.stateLayout = machine.stateLayout.mapValues {
            var layout = $0
            layout.extraProperties = [:]
            return layout
        }
        let resource = Resource(uri: "memory:/legacy.xmi")
        let root = await codec.encode(machine, name: "Legacy", into: resource)
        let layoutObjects = await resource.getAllObjects().compactMap { $0 as? DynamicEObject }
            .filter { $0.eClass.name == metamodel.stateLayoutClass.name }
        let layout = try #require(layoutObjects.first)
        await resource.eSet(objectId: layout.id, feature: "extraProperties", value: #"{"bgColour":"green","alpha":1}"#)
        let decoded = try await codec.decode(root, from: resource)
        let state = try #require(decoded.machine.llfsm.states.first)
        let properties = decoded.machine.stateLayout[state]?.extraProperties ?? [:]
        #expect(properties["bgColour"] as? String == "green")
        #expect(properties["alpha"] as? Int == 1)
    }

    @Test("The metamodel declares the property list classes")
    func metamodelClasses() async throws {
        let metamodel = try await LLFSMMetamodel()
        #expect(metamodel.stateLayoutClass.getEReference(name: "properties")?.containment == true)
        #expect(metamodel.propertyListEntryClass.getEAttribute(name: "key")?.lowerBound == 1)
        #expect(metamodel.propertyListValueClass.isAbstract)
        for valueClass in [
            metamodel.propertyListRealClass, metamodel.propertyListIntegerClass,
            metamodel.propertyListBooleanClass, metamodel.propertyListStringClass,
            metamodel.propertyListDataClass, metamodel.propertyListDateClass,
            metamodel.propertyListArrayClass, metamodel.propertyListDictionaryClass,
        ] {
            #expect(valueClass.allSuperTypes.contains { $0.name == metamodel.propertyListValueClass.name })
        }
    }
}
