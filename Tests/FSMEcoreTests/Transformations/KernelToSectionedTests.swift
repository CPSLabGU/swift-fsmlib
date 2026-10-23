//
//  KernelToSectionedTests.swift
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

@Suite("Kernel to sectioned transformation")
@MainActor
struct KernelToSectionedTests {
    /// The kernel fixtures that record no origins.
    nonisolated static let flatFixtures = KernelFixture.allCases.filter { !$0.isSectioned && $0 != .crossingController }

    @Test("kernel machines without origins map flatly, with one warning per machine", arguments: flatFixtures)
    func flatMapping(_ fixture: KernelFixture) async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let (_, source) = try await KernelFixtureTests.load(fixture)
        let result = try await transformations.kernelToSectioned(source)
        let kernelIndex = await KernelModelIndex(resource: source)
        let index = await KernelModelIndex(resource: result.resource)
        let kernel = transformations.metamodels.kernel
        let sectioned = transformations.metamodels.sectioned
        let kernelArrangement = try #require(kernelIndex.roots.first.flatMap(kernelIndex.object))
        let arrangement = try #require(index.roots.first.flatMap(index.object))
        #expect(arrangement.eClass.id == sectioned.arrangementClass.id)
        let kernelMachines = kernelIndex.objects(.machines, of: kernelArrangement)
        #expect(result.diagnostics.warnings.map(\.kind) == kernelMachines.map { .flatMapping(machine: $0.string(.name) ?? "") })
        let machines = index.objects(.machines, of: arrangement)
        #expect(machines.map { $0.string(.name) } == kernelMachines.map { $0.string(.name) })
        for (kernelMachine, machine) in zip(kernelMachines, machines) {
            let kernelStates = kernelIndex.objects(.states, of: kernelMachine)
            let states = index.objects(.states, of: machine)
            #expect(states.map { $0.string(.name) } == kernelStates.map { $0.string(.name) })
            #expect(index.target(.initial, of: machine)?.string(.name) == kernelIndex.target(.initial, of: kernelMachine)?.string(.name))
            #expect(machine.identifier(.suspendState) == nil)
            for (kernelState, state) in zip(kernelStates, states) {
                #expect(index.objects(.onEntry, of: state).map(\.eClass.name)
                        == kernelIndex.objects(.actions, of: kernelState).map(\.eClass.name))
                for feature in [LLFSMFeature.onExit, .internal, .onSuspend, .onResume] {
                    #expect(index.objects(feature, of: state).isEmpty)
                }
                let kernelTransitions = kernelIndex.objects(.transitions, of: kernelState)
                let transitions = index.objects(.transitions, of: state)
                #expect(transitions.map { index.target(.target, of: $0)?.string(.name) }
                        == kernelTransitions.map { kernelIndex.target(.target, of: $0)?.string(.name) })
                for (kernelTransition, transition) in zip(kernelTransitions, transitions) {
                    let kernelLabel = try #require(kernelIndex.target(.label, of: kernelTransition))
                    let label = try #require(index.target(.label, of: transition))
                    let expectedClass = kernel.isKind(kernelLabel.eClass, of: kernel.inStateExpressionClass)
                        ? sectioned.inStateExpressionClass.name : kernelLabel.eClass.name
                    #expect(label.eClass.name == expectedClass)
                }
            }
        }
        #expect(index.objects(.variables, of: arrangement).map { $0.string(.name) }
                == kernelIndex.objects(.variables, of: kernelArrangement).map { $0.string(.name) })
        #expect(index.objects(.types, of: arrangement).map { $0.string(.name) }
                == kernelIndex.objects(.types, of: kernelArrangement).map { $0.string(.name) })
        #expect(index.objects(.instances, of: arrangement).map { $0.string(.name) }
                == kernelIndex.objects(.instances, of: kernelArrangement).map { $0.string(.name) })
    }

    @Test("the flat mapping encodes back into a valid kernel model", arguments: flatFixtures)
    func flatMappingEncodes(_ fixture: KernelFixture) async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let (_, source) = try await KernelFixtureTests.load(fixture)
        let sectioned = try await transformations.kernelToSectioned(source)
        let kernel = try await transformations.sectionedToKernel(sectioned.resource)
        let kernelMetamodel = transformations.metamodels.kernel
        let profile = fixture.isStrict ? ValidationProfile.strict : .relaxed
        #expect(await TransformationTestSupport.profile(for: kernel.resource, kernel: kernelMetamodel) == profile)
        let diagnostics = await KernelValidator(metamodel: kernelMetamodel, profile: profile).validate(kernel.resource)
        #expect(diagnostics.isEmpty, "\(diagnostics)")
    }

    @Test("a kernel model with origins rebuilds its sections, labels and time expressions")
    func originRebuild() async throws {
        let transformations = try await TransformationTestSupport.transformations()
        let (_, source) = try await KernelFixtureTests.load(.crossingController)
        let result = try await transformations.kernelToSectioned(source)
        #expect(result.diagnostics.isEmpty)
        let index = await KernelModelIndex(resource: result.resource)
        let arrangement = try #require(index.roots.first.flatMap(index.object))
        #expect(index.objects(.variables, of: arrangement).map { $0.string(.name) } == ["request"])
        #expect(index.objects(.types, of: arrangement).map { $0.string(.name) } == ["Bool"])
        let machine = try #require(index.objects(.machines, of: arrangement).first)
        #expect(index.objects(.variables, of: machine).isEmpty)
        let states = index.objects(.states, of: machine)
        #expect(states.map { $0.string(.name) } == ["Go", "Amber", "Stop"])
        let go = states[0]
        #expect(index.objects(.onEntry, of: go).map { $0.string(.text) } == ["go"])
        #expect(index.objects(.onExit, of: go).map { $0.string(.text) } == ["clearing"])
        #expect(index.objects(.transitions, of: go).map { index.target(.target, of: $0)?.string(.name) } == ["Amber"])
        let amberLabel = try #require(index.objects(.transitions, of: states[1]).first.flatMap { index.target(.label, of: $0) })
        let time = try #require(index.target(.left, of: amberLabel))
        #expect(time.eClass.id == transformations.metamodels.sectioned.stateTimeExpressionClass.id)
        #expect(time.string(.unit) == SectionedTimeUnit.microseconds.rawValue)
        #expect(index.target(.right, of: amberLabel)?.int(.value) == 3)
    }
}
