//
//  InstanceOrderingTests.swift
//  FSM
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Testing
@testable import FSM

/// Tests that arrangement code lists machine types in a stable order.
@Suite("Instance ordering")
struct InstanceOrderingTests {
    /// Instances of three types, with one type repeated, in a fixed order.
    private func makeInstances() -> [Instance] {
        let names = ["second.machine", "first.machine", "second.machine", "third.machine"]
        return names.enumerated().map { index, typeFile in
            let machine = Machine()
            machine.llfsm = LLFSM(states: [State(name: "Initial")], transitions: [], suspendState: nil)
            return Instance(name: "instance\(index)", typeFile: typeFile, machine: machine)
        }
    }

    /// Checks that machine type names and first instances follow the order of first appearance.
    @Test("Machine type names follow first appearance")
    func machineTypeNamesFollowFirstAppearance() {
        let instances = makeInstances()
        #expect(instances.machineTypeNames == ["second", "first", "third"])
        #expect(instances.firstInstancesByType.map(\.typeName) == ["second", "first", "third"])
        #expect(instances.firstInstancesByType.map(\.instance.name) == ["instance0", "instance1", "instance3"])
    }

    /// Checks that every arrangement generator is deterministic and lists machine types in instance order.
    @Test("Arrangement code is identical across runs and lists types in instance order")
    func arrangementCodeIsStable() {
        let instances = makeInstances()
        let cInterface = cArrangementInterface(for: instances, named: "Stable", isSuspensible: true)
        let cCode = cArrangementCode(for: instances, named: "Stable", isSuspensible: true)
        let cStatic = cStaticArrangementCode(for: instances, named: "Stable", isSuspensible: true)
        let objcpp = objcppArrangementImplementation(for: instances, named: "Stable", isSuspensible: true)
        #expect(cInterface == cArrangementInterface(for: instances, named: "Stable", isSuspensible: true))
        #expect(cCode == cArrangementCode(for: instances, named: "Stable", isSuspensible: true))
        #expect(cStatic == cStaticArrangementCode(for: instances, named: "Stable", isSuspensible: true))
        #expect(objcpp == objcppArrangementImplementation(for: instances, named: "Stable", isSuspensible: true))
        for code in [cInterface, cCode, cStatic, objcpp] {
            let positions = ["second", "first", "third"].map { name in
                code.range(of: "Machine_\(name)")?.lowerBound ?? code.range(of: "\(name).machine")?.lowerBound
            }
            let found = positions.compactMap { $0 }
            #expect(found.count == 3, "every machine type should appear in the generated code")
            #expect(found == found.sorted(), "types should appear in instance order")
        }
    }
}
