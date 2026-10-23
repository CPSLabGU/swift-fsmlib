//
//  KernelEncodingSemanticsTests.swift
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

/// Tests that the kernel encoding of sectioned models executes in the
/// traditional order, by interpreting the encodings and comparing their
/// traces with traces derived by hand from the sectioned semantics.
@Suite("Kernel encoding semantics")
@MainActor
struct KernelEncodingSemanticsTests {
    /// Encode a sectioned model and interpret the encoding.
    private func trace(
        of sample: SectionedSample,
        options: SectionedToKernelOptions,
        rounds: Int,
        environment: @escaping KernelInterpreter.Environment
    ) async throws -> [String] {
        let transformations = try await TransformationTestSupport.transformations()
        let kernel = try await transformations.sectionedToKernel(try await sample.resource(), options: options)
        var interpreter = await KernelInterpreter(
            resource: kernel.resource, kernel: transformations.metamodels.kernel, environment: environment)
        interpreter.run(rounds: rounds)
        return interpreter.trace
    }

    /// The options under which the crossing is interpreted.
    nonisolated static let crossingOptions: [SectionedToKernelOptions] = [
        SectionedToKernelOptions(),
        SectionedToKernelOptions(elideEmptySections: false),
        SectionedToKernelOptions(selfLoop: .reentry),
        SectionedToKernelOptions(inState: .exact),
    ]

    @Test("the crossing encoding runs entry, labels, exit and internal sections in the traditional order",
          arguments: crossingOptions)
    func crossing(_ options: SectionedToKernelOptions) async throws {
        // The environment advances `now` by one second per round and
        // requests the crossing in round 1 only. Derived from the sectioned
        // semantics of SectionedCrossing:
        //
        // r0: Go is entered: its entry section sets walkLit to false and
        //     prints "go"; request is false, so the internal section (empty)
        //     runs.
        // r1: request holds: the exit section of Go prints "clearing" and
        //     Amber becomes current.
        // r2: Amber is entered at 2 s and prints "amber"; 0 s < 3 s.
        // r3, r4: 1 s and 2 s < 3 s.
        // r5: 3 s >= 3 s: Amber has no exit section; Stop becomes current.
        // r6: Stop is entered at 6 s: walkLit becomes true, "stop" is
        //     printed; 0 s < 5 s, so the internal section prints
        //     "walking true".
        // r7 to r10: 1 s to 4 s < 5 s: "walking true" each round.
        // r11: 5 s >= 5 s: Stop has no exit section; Go becomes current.
        // r12: Go is entered: "go"; request is false.
        let expected = [
            "r0 main: go", "r1 main: clearing", "r2 main: amber", "r6 main: stop", "r6 main: walking true",
            "r7 main: walking true", "r8 main: walking true", "r9 main: walking true", "r10 main: walking true",
            "r12 main: go",
        ]
        let trace = try await trace(of: .sectionedCrossing, options: options, rounds: 13) { round, name in
            switch name {
            case LLFSMTransformationNames.now: return .integer(round * LLFSMTransformationNames.secondFactor)
            default: return .boolean(round == 1)
            }
        }
        #expect(trace == expected)
    }

    /// The external `go` of the looping counter, false in round 1 only.
    private static func goes(_ round: Int, _ name: String) -> KernelInterpreter.Value {
        .boolean(round != 1)
    }

    @Test("a traditional self loop runs the exit section without re-entering the state",
          arguments: [true, false])
    func traditionalSelfLoop(_ elides: Bool) async throws {
        // Derived from the sectioned semantics of LoopingCounter with
        // selfLoop=traditional:
        //
        // r0: Counting is entered and prints "enter"; go && 0 < 3 holds, so
        //     the exit section sets count to 1 and prints "leave"; the state
        //     is not re-entered.
        // r1: go is false and 1 < 3, so no label holds: the internal
        //     section prints "idle".
        // r2: go && 1 < 3: count becomes 2, "leave".
        // r3: go && 2 < 3: count becomes 3, "leave".
        // r4: 3 < 3 fails, 3 >= 3 holds: count becomes 4, "leave", and
        //     Done becomes current.
        // r5: Done is entered and prints "done 4".
        // r6: Done is accepting.
        let expected = [
            "r0 main: enter", "r0 main: leave", "r1 main: idle", "r2 main: leave", "r3 main: leave",
            "r4 main: leave", "r5 main: done 4",
        ]
        let options = SectionedToKernelOptions(selfLoop: .traditional, elideEmptySections: elides)
        let trace = try await trace(of: .loopingCounter, options: options, rounds: 7, environment: Self.goes)
        #expect(trace == expected)
    }

    @Test("a re-entering self loop runs the entry section again", arguments: [true, false])
    func reenteringSelfLoop(_ elides: Bool) async throws {
        // Derived from the sectioned semantics of LoopingCounter with
        // selfLoop=reentry:
        //
        // r0: "enter"; go && 0 < 3: count becomes 1, "leave", and Counting
        //     is re-entered.
        // r1: "enter"; go is false and 1 < 3: no label holds, "idle".
        // r2: the state was not re-entered: go && 1 < 3: count becomes 2,
        //     "leave", re-entered.
        // r3: "enter"; go && 2 < 3: count becomes 3, "leave", re-entered.
        // r4: "enter"; 3 >= 3: count becomes 4, "leave"; Done is current.
        // r5: "done 4".
        let expected = [
            "r0 main: enter", "r0 main: leave", "r1 main: enter", "r1 main: idle", "r2 main: leave",
            "r3 main: enter", "r3 main: leave", "r4 main: enter", "r4 main: leave", "r5 main: done 4",
        ]
        let options = SectionedToKernelOptions(selfLoop: .reentry, elideEmptySections: elides)
        let trace = try await trace(of: .loopingCounter, options: options, rounds: 7, environment: Self.goes)
        #expect(trace == expected)
    }
}
