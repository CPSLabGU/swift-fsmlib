//
//  TransformationTestSupport.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
@testable import FSM
@testable import FSMEcore

/// Helpers shared by the transformation tests.
@MainActor
enum TransformationTestSupport {
    /// The transformations, loaded once per test.
    static func transformations() async throws -> LLFSMTransformations {
        try await LLFSMTransformations()
    }

    /// The structural model of an example machine or arrangement bundle.
    ///
    /// - Parameter url: The location of the bundle.
    /// - Returns: The resource that holds the structural model.
    static func structuralResource(for url: URL) async throws -> Resource {
        let metamodel = try await LLFSMMetamodel()
        let resourceSet = ResourceSet()
        await metamodel.register(in: resourceSet)
        let resource = await resourceSet.createResource(uri: "memory:/structural.xmi")
        if url.pathExtension == TemplateParity.arrangementExtension {
            let arrangement = try ArrangementWrapper(url: url).arrangement
            _ = await ArrangementEcoreCodec(metamodel: metamodel).encode(arrangement, into: resource)
        } else {
            let machine = try Machine(from: url)
            _ = await MachineEcoreCodec(metamodel: metamodel)
                .encode(machine, name: url.deletingPathExtension().lastPathComponent, into: resource)
        }
        return resource
    }

    /// The validation profile that a kernel model is meant to satisfy.
    ///
    /// - Parameter resource: The resource that holds the kernel model.
    /// - Returns: ``ValidationProfile/relaxed`` if the model holds opaque
    ///   nodes or host declarations, ``ValidationProfile/strict`` otherwise.
    static func profile(for resource: Resource, kernel: KernelMetamodel) async -> ValidationProfile {
        let opaqueClasses = [kernel.opaqueExpressionClass, kernel.opaqueStatementClass, kernel.opaqueTypeClass,
                             kernel.hostDeclarationsClass].map(\.id)
        for case let object as DynamicEObject in await resource.getAllObjects()
        where opaqueClasses.contains(object.eClass.id) {
            return .relaxed
        }
        return .strict
    }

    /// The objects of a resource whose class has a given name, in containment order.
    static func objects(named className: String, in resource: Resource) async -> [DynamicEObject] {
        let index = await KernelModelIndex(resource: resource)
        return index.order.compactMap(index.object).filter { $0.eClass.name == className }
    }
}

extension KernelModelBuilder {
    /// A fresh sectioned model of a counter whose state loops on itself.
    ///
    /// `Counting` prints `enter` on entry and `idle` internally; on exit it
    /// increments `count` and prints `leave`. While the external `go` holds
    /// and `count < 3` it loops on itself; once `count >= 3` it moves to the
    /// accepting state `Done`, which prints `done` and the count.
    func buildLoopingCounter() {
        let system = sectionedArrangement("LoopingCounter")
        let flag = booleanType(in: system)
        let range = integerType("Count", 0...9, in: system)
        let go = variable("go", flag, in: system, external: true)
        let looper = sectionedMachine("Looper", in: system)
        let count = variable("count", range, in: looper)
        let counting = sectionedState("Counting", in: looper)
        let done = sectionedState("Done", in: looper)
        set(looper, .initial, counting)
        section(.onEntry, of: counting, printLine("enter"))
        section(.internal, of: counting, printLine("idle"))
        section(.onExit, of: counting, assign(ref(count), binary(.addition, ref(count), int(1))), printLine("leave"))
        sectionedTransition(from: counting, to: counting,
                            when: binary(.conjunction, ref(go), binary(.lessThan, ref(count), int(3))))
        sectionedTransition(from: counting, to: done, when: binary(.greaterOrEqual, ref(count), int(3)))
        section(.onEntry, of: done, printLine("done", [ref(count)]))
        sectionedInstance("main", of: looper, in: system)
    }

    /// A fresh sectioned model whose suspensible machine has two instances
    /// and is also restarted.
    func buildSharedSuspension() {
        let system = sectionedArrangement("SharedSuspension")
        let flag = booleanType(in: system)
        let alarm = variable("alarm", flag, in: system, external: true)
        let pump = sectionedMachine("Pump", in: system)
        let running = sectionedState("Running", in: pump)
        let paused = sectionedState("Paused", in: pump)
        set(pump, .initial, running)
        set(pump, .suspendState, paused)
        section(.onEntry, of: running, printLine("running"))
        section(.onEntry, of: paused, printLine("paused"))
        let first = sectionedInstance("first", of: pump, in: system)
        sectionedInstance("second", of: pump, in: system)
        let guardMachine = sectionedMachine("Guard", in: system)
        let watching = sectionedState("Watching", in: guardMachine)
        let tripped = sectionedState("Tripped", in: guardMachine)
        set(guardMachine, .initial, watching)
        sectionedTransition(from: watching, to: tripped, when: ref(alarm))
        section(.onEntry, of: tripped, control(.suspend, first), control(.restart, first))
        sectionedTransition(from: tripped, to: watching, when: unary(.negation, ref(alarm)))
        section(.onExit, of: tripped, control(.resume, first))
        sectionedInstance("guard", of: guardMachine, in: system)
    }
}
