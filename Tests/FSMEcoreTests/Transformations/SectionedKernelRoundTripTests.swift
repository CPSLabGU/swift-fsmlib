//
//  SectionedKernelRoundTripTests.swift
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

/// A sectioned model to encode, from a checked-in fixture or built in the test.
enum SectionedSample: String, CaseIterable, Sendable {
    case sectionedCrossing = "SectionedCrossing"
    case suspendResumeSampler = "SuspendResumeSampler"
    case loopingCounter = "LoopingCounter"
    case sharedSuspension = "SharedSuspension"

    /// The resource that holds the model.
    func resource() async throws -> Resource {
        switch self {
        case .sectionedCrossing: return try await KernelFixtureTests.load(.sectionedCrossing).resource
        case .suspendResumeSampler: return try await KernelFixtureTests.load(.suspendResumeSampler).resource
        case .loopingCounter, .sharedSuspension:
            let builder = try await KernelModelBuilder.make()
            if self == .loopingCounter { builder.buildLoopingCounter() } else { builder.buildSharedSuspension() }
            return await builder.resource()
        }
    }

    /// Whether the model holds control statements that the encoding drops.
    var dropsControls: Bool { self == .sharedSuspension }
}

@Suite("Sectioned and kernel round trips")
@MainActor
struct SectionedKernelRoundTripTests {
    /// The option combinations whose encodings differ.
    nonisolated static let optionSets: [[String]] = [
        [], ["selfLoop=reentry"], ["elideEmptySections=false"], ["suspension=omit"], ["time=clock"],
        ["inState=exact"], ["resumeFallback=previous"],
        ["elideEmptySections=false", "selfLoop=reentry", "time=clock", "inState=exact", "resumeFallback=previous"],
    ]

    @Test("sectioned models encode into valid kernel models and rebuild exactly",
          arguments: SectionedSample.allCases, optionSets)
    func roundTrip(_ sample: SectionedSample, _ pairs: [String]) async throws {
        let options = try SectionedToKernelOptions(keyValues: pairs)
        let transformations = try await TransformationTestSupport.transformations()
        let source = try await sample.resource()
        let kernel = try await transformations.sectionedToKernel(source, options: options)
        let kernelMetamodel = transformations.metamodels.kernel
        let profile = await TransformationTestSupport.profile(for: kernel.resource, kernel: kernelMetamodel)
        #expect(profile == .strict)
        let diagnostics = await KernelValidator(metamodel: kernelMetamodel, profile: profile).validate(kernel.resource)
        #expect(diagnostics.isEmpty, "\(diagnostics)")
        let rebuilt = try await transformations.kernelToSectioned(kernel.resource)
        #expect(rebuilt.diagnostics.isEmpty, "\(rebuilt.diagnostics.warnings)")
        let expected = try await expectedRebuild(of: sample, options: options)
        #expect(await ModelDump.text(of: rebuilt.resource) == ModelDump.text(of: expected))
    }

    /// The sectioned model that the inverse rebuilds from an encoding.
    ///
    /// The encoding keeps everything except what its options and
    /// diagnostics drop: the suspension of a machine when it is omitted,
    /// and control statements that cannot be encoded.
    private func expectedRebuild(of sample: SectionedSample, options: SectionedToKernelOptions) async throws -> Resource {
        let resource = try await sample.resource()
        let metamodels = try await LLFSMMetamodels()
        let index = await KernelModelIndex(resource: resource)
        let sectioned = metamodels.sectioned
        var dropped: [EUUID] = []
        for case let machine? in index.order.map(index.object) where machine.eClass.id == sectioned.machineClass.id {
            guard machine.identifier(.suspendState) != nil, options.suspension == .omit else { continue }
            _ = await resource.eSet(objectId: machine.id, feature: LLFSMFeature.suspendState.rawValue, value: nil)
            for state in index.objects(.states, of: machine) {
                for feature in [LLFSMFeature.onSuspend, .onResume] {
                    dropped += state.identifiers(feature)
                    _ = await resource.eSet(objectId: state.id, feature: feature.rawValue, value: nil)
                }
            }
        }
        for case let state? in index.order.map(index.object) where state.eClass.id == sectioned.stateClass.id {
            for feature in SectionedTypingPass.sections {
                let statements = index.objects(feature, of: state)
                let kept = statements.filter { statement in
                    guard statement.eClass.id == sectioned.machineControlStatementClass.id else { return true }
                    let operation = statement.string(.operation)
                    let machine = index.target(.instance, of: statement).flatMap { index.target(.machine, of: $0) }
                    return options.suspension == .encode && operation != SectionedControlOperation.restart.rawValue
                        && machine?.identifier(.suspendState) != nil
                }
                guard kept.count != statements.count else { continue }
                dropped += statements.filter { !kept.map(\.id).contains($0.id) }.map(\.id)
                _ = await resource.eSet(objectId: state.id, feature: feature.rawValue,
                                        value: kept.isEmpty ? nil : kept.map(\.id))
            }
        }
        for identifier in dropped { _ = await resource.remove(id: identifier) }
        return resource
    }

    @Test("an encoding with only entry sections keeps the number of states")
    func entryOnlyStateCount() async throws {
        let builder = try await KernelModelBuilder.make()
        let system = builder.sectionedArrangement("Blinker")
        let blinker = builder.sectionedMachine("Blinker", in: system)
        let on = builder.sectionedState("On", in: blinker)
        let off = builder.sectionedState("Off", in: blinker)
        builder.set(blinker, .initial, on)
        builder.section(.onEntry, of: on, builder.printLine("on"))
        builder.section(.onEntry, of: off, builder.printLine("off"))
        builder.sectionedTransition(from: on, to: off, when: builder.bool(true))
        builder.sectionedTransition(from: off, to: on, when: builder.bool(true))
        builder.sectionedInstance("blinker", of: blinker, in: system)
        let transformations = try await TransformationTestSupport.transformations()
        let kernel = try await transformations.sectionedToKernel(await builder.resource())
        #expect(await TransformationTestSupport.objects(named: "State", in: kernel.resource).count == 2)
        let unelided = try await transformations.sectionedToKernel(
            await builder.resource(), options: SectionedToKernelOptions(elideEmptySections: false))
        #expect(await TransformationTestSupport.objects(named: "State", in: unelided.resource).count == 2 * 4)
    }

    @Test("every kernel state and transition of an encoding records its origin",
          arguments: SectionedSample.allCases)
    func origins(_ sample: SectionedSample) async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let kernel = try await transformations.sectionedToKernel(
            try await sample.resource(), options: SectionedToKernelOptions(elideEmptySections: false, time: .clock))
        let index = await KernelModelIndex(resource: kernel.resource)
        let kernelMetamodel = transformations.metamodels.kernel
        for case let object? in index.order.map(index.object)
        where object.eClass.id == kernelMetamodel.stateClass.id || object.eClass.id == kernelMetamodel.transitionClass.id {
            #expect(await OriginAnnotations.origin(of: object.id, in: kernel.resource) != nil, "\(index.path(of: object.id))")
        }
    }

    @Test("the self-loop option decides whether the entry state is re-entered")
    func selfLoopTargets() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let source = try await SectionedSample.loopingCounter.resource()
        for (selfLoop, target) in [(SectionedToKernelOptions.SelfLoop.traditional, "Counting_w"), (.reentry, "Counting")] {
            let kernel = try await transformations.sectionedToKernel(source, options: SectionedToKernelOptions(selfLoop: selfLoop))
            let index = await KernelModelIndex(resource: kernel.resource)
            let exit = try #require(index.order.compactMap(index.object).first { $0.string(.name) == "Counting_x0" })
            let transition = try #require(index.objects(.transitions, of: exit).first)
            #expect(index.target(.target, of: transition)?.string(.name) == target)
        }
    }

    @Test("the time option decides whether a clock machine advances the time")
    func clockMachine() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let source = try await SectionedSample.sectionedCrossing.resource()
        let external = try await transformations.sectionedToKernel(source)
        let clock = try await transformations.sectionedToKernel(source, options: SectionedToKernelOptions(time: .clock))
        let externalNow = await TransformationTestSupport.objects(named: "Variable", in: external.resource)
            .first { $0.string(.name) == LLFSMTransformationNames.now }
        #expect(externalNow?.bool(.external) == true)
        let clockNow = await TransformationTestSupport.objects(named: "Variable", in: clock.resource)
            .first { $0.string(.name) == LLFSMTransformationNames.now }
        #expect(clockNow?.bool(.external) == false)
        let instances = await TransformationTestSupport.objects(named: "Instance", in: clock.resource)
        #expect(instances.compactMap { $0.string(.name) } == [LLFSMTransformationNames.clockInstance, "main"])
    }

    @Test("in-state observations expand to every encoding state unless exact")
    func inStateExpansion() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let source = try await SectionedSample.suspendResumeSampler.resource()
        let options = SectionedToKernelOptions(elideEmptySections: false)
        let expanded = try await transformations.sectionedToKernel(source, options: options)
        var exactOptions = options
        exactOptions.inState = .exact
        let exact = try await transformations.sectionedToKernel(source, options: exactOptions)
        let expandedObservations = await TransformationTestSupport.objects(named: "InStateExpression", in: expanded.resource)
        let exactObservations = await TransformationTestSupport.objects(named: "InStateExpression", in: exact.resource)
        // The label of Holding is copied into Holding and Holding_w; the
        // suspend state is encoded by Suspended, Suspended_i and Suspended_w.
        #expect(expandedObservations.count == 2 * 3)
        #expect(exactObservations.count == 2)
    }

    @Test("the encoding reports what it drops")
    func encodingDiagnostics() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let shared = try await transformations.sectionedToKernel(try await SectionedSample.sharedSuspension.resource())
        #expect(shared.diagnostics.warnings.map(\.kind) == [
            .sharedSuspension(machine: "Pump", instances: ["first", "second"]),
            .controlDropped(operation: "restart", instance: "first"),
        ])
        let omitted = try await transformations.sectionedToKernel(
            try await SectionedSample.suspendResumeSampler.resource(),
            options: SectionedToKernelOptions(suspension: .omit))
        #expect(omitted.diagnostics.warnings.map(\.kind) == [
            .suspensionOmitted(machine: "Sampler"),
            .controlDropped(operation: "suspend", instance: "worker"),
            .controlDropped(operation: "resume", instance: "worker"),
        ])
        #expect(omitted.diagnostics.warnings.allSatisfy { !$0.message.isEmpty })
        let plain = try await transformations.sectionedToKernel(try await SectionedSample.sectionedCrossing.resource())
        #expect(plain.diagnostics.isEmpty)
    }

    @Test("the encoding serialises to a kernel document that reads back")
    func serialisation() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let kernel = try await transformations.sectionedToKernel(try await SectionedSample.suspendResumeSampler.resource())
        var diagnostics = ConversionDiagnostics()
        let text = try await XMISerializer(options: KernelFixture.serialisationOptions)
            .serialize(kernel.resource, diagnostics: &diagnostics)
        #expect(diagnostics.isEmpty, "\(diagnostics.warnings)")
        let resourceSet = ResourceSet()
        await transformations.metamodels.register(in: resourceSet)
        let parser = XMIParser(resourceSet: resourceSet)
        let parsed = try await parser.parse(text, uri: LLFSMTransformations.defaultKernelURI)
        #expect(await ModelDump.text(of: parsed) == ModelDump.text(of: kernel.resource))
    }
}
