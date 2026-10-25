//
//  OutputTargetTests.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Testing
@testable import FSM
@testable import FSMEcore

/// Tests of the output targets, the levels and the chains of transformations between them.
@Suite("Output targets and levels")
struct OutputTargetTests {
    /// Check that a native format is a structural target of the same name.
    ///
    /// - Parameter format: The native format.
    /// - Throws: Any error from the unwrapping of the target.
    @Test("every native format is a structural target of the same name", arguments: Format.allCases)
    func nativeTargets(_ format: Format) throws {
        let target = try #require(OutputTarget(rawValue: format.rawValue))
        #expect(target == .native(format))
        #expect(target.isNative)
        #expect(target.format == format)
        #expect(target.level == .structural)
        #expect(target.kernelTarget == nil)
        #expect(target.modelFormat == nil)
    }

    /// Check that the static targets name the native formats.
    @Test("the static targets name the native formats")
    func nativeStatics() {
        let statics: [OutputTarget] = [.c, .cx, .cpp, .cxx, .objC, .objCX, .objCPP, .scxml, .swift, .verilog, .vhdl]
        #expect(statics.compactMap(\.format) == Format.allCases)
    }

    /// Check that a kernel target is a kernel-level target of the same name.
    ///
    /// - Parameter kernelTarget: The kernel target.
    /// - Throws: Any error from the unwrapping of the target.
    @Test("every kernel target is a kernel-level target of the same name", arguments: KernelTarget.allCases)
    func kernelTargets(_ kernelTarget: KernelTarget) throws {
        let target = try #require(OutputTarget(rawValue: kernelTarget.rawValue))
        #expect(target.kernelTarget == kernelTarget)
        #expect(target.level == .kernel)
        #expect(!target.isNative)
        #expect(target.format == nil)
    }

    /// Check that the static kernel targets name the kernel targets.
    @Test("the static kernel targets name the kernel targets")
    func kernelStatics() {
        let statics: [OutputTarget] = [.kernelC, .kernelCPP, .kernelSwift, .kernelJava, .smv, .tla, .dot]
        #expect(statics.compactMap(\.kernelTarget) == KernelTarget.allCases)
        #expect(statics.map(\.rawValue) == ["kernel-c", "kernel-cpp", "kernel-swift", "kernel-java", "smv", "tla", "dot"])
    }

    /// Check that XMI and JSON have no level of their own.
    @Test("xmi and json have no level of their own")
    func levelNeutralDocuments() {
        #expect(OutputTarget.xmi.rawValue == "xmi")
        #expect(OutputTarget.json.rawValue == "json")
        #expect(OutputTarget.xmi.level == nil)
        #expect(OutputTarget.json.level == nil)
        #expect(OutputTarget.xmi.modelFormat == .xmi)
        #expect(OutputTarget.json.modelFormat == .json)
        #expect(!OutputTarget.xmi.isNative)
    }

    /// Check that the level-specific XMI targets are named after their level.
    ///
    /// - Parameter level: The level of the document.
    /// - Throws: Any error from the unwrapping of the target.
    @Test("the level-specific XMI targets are named after their level", arguments: LLFSMLevel.allCases)
    func levelDocuments(_ level: LLFSMLevel) throws {
        let target = try #require(OutputTarget(rawValue: "\(level.rawValue)-xmi"))
        #expect(target == .xmi(at: level))
        #expect(target.level == level)
        #expect(target.modelFormat == .xmi)
        #expect([OutputTarget.structuralXMI, .sectionedXMI, .kernelXMI].contains(target))
    }

    /// Check that target names are unique and round-trip through the raw value.
    @Test("names identify targets uniquely and round-trip through the raw value")
    func uniqueNames() {
        let names = OutputTarget.allCases.map(\.rawValue)
        #expect(Set(names).count == names.count)
        #expect(names.count == Format.allCases.count + 2 + LLFSMLevel.allCases.count + KernelTarget.allCases.count)
        for target in OutputTarget.allCases {
            #expect(OutputTarget(rawValue: target.rawValue) == target)
            #expect(target.description == target.rawValue)
        }
        #expect(OutputTarget(rawValue: "bogus") == nil)
        #expect(OutputTarget(rawValue: "java") == nil)
    }

    /// Check that the language names stand for the execution targets at the kernel level.
    ///
    /// - Parameters:
    ///   - name: The name to look up.
    ///   - target: The target the name is expected to denote.
    @Test("at the kernel level the language names stand for the execution targets",
          arguments: [
            ("c", OutputTarget.kernelC), ("cpp", .kernelCPP), ("swift", .kernelSwift), ("java", .kernelJava),
            ("C", .kernelC),
          ])
    func kernelSynonyms(_ name: String, _ target: OutputTarget) {
        #expect(OutputTarget.named(name, level: .kernel) == target)
    }

    /// Check that the language names keep their native meaning without the kernel level.
    ///
    /// - Parameter level: The level used to look names up, if any.
    @Test("without the kernel level the language names keep their native meaning",
          arguments: [nil, LLFSMLevel.structural, .sectioned])
    func nativeNames(_ level: LLFSMLevel?) {
        #expect(OutputTarget.named("c", level: level) == .c)
        #expect(OutputTarget.named("CPP", level: level) == .cpp)
        #expect(OutputTarget.named("swift", level: level) == .swift)
        #expect(OutputTarget.named("java", level: level) == nil)
        #expect(OutputTarget.named("smv", level: level) == .smv)
        #expect(!OutputTarget.names(level: level).contains("java"))
    }

    /// Check that other names keep their meaning at the kernel level.
    @Test("other names keep their meaning at the kernel level")
    func otherNamesAtKernelLevel() {
        #expect(OutputTarget.named("objcpp", level: .kernel) == .objCPP)
        #expect(OutputTarget.named("scxml", level: .kernel) == .scxml)
        #expect(OutputTarget.named("xmi", level: .kernel) == .xmi)
        #expect(OutputTarget.names(level: .kernel).contains("java"))
        #expect(OutputTarget.names(level: .kernel).count == OutputTarget.allCases.count + 1)
    }

    /// Check that the native generators are named mtl and swift.
    @Test("the native generators are named mtl and swift")
    func generators() {
        #expect(NativeGenerator.allCases.map(\.rawValue) == ["mtl", "swift"])
        #expect(NativeGenerator(rawValue: "mtl") == .templates)
    }

    // MARK: - Levels

    /// Check that each level is found by its namespace.
    ///
    /// - Parameter level: The level to look up.
    @Test("each level is found by its namespace", arguments: LLFSMLevel.allCases)
    func namespaces(_ level: LLFSMLevel) {
        #expect(LLFSMLevel(namespaceURI: level.namespaceURI) == level)
    }

    /// Check that the namespaces are those of the bundled metamodels.
    ///
    /// - Throws: Any error from loading the metamodels.
    @Test("the namespaces are those of the bundled metamodels")
    func bundledNamespaces() async throws {
        #expect(try await LLFSMMetamodel().package.nsURI == LLFSMLevel.structural.namespaceURI)
        let metamodels = try await LLFSMMetamodels()
        #expect(metamodels.sectioned.package.nsURI == LLFSMLevel.sectioned.namespaceURI)
        #expect(metamodels.kernel.package.nsURI == LLFSMLevel.kernel.namespaceURI)
        #expect(LLFSMLevel(namespaceURI: LLFSMMetamodels.rootNamespaceURI) == nil)
    }

    /// Check the shortest chains of transformations between the levels.
    ///
    /// - Parameters:
    ///   - source: The level to start from.
    ///   - target: The level to reach.
    ///   - expected: The transformations expected, in order.
    @Test("the shortest chains between the levels",
          arguments: [
            (LLFSMLevel.structural, LLFSMLevel.kernel, [LevelTransformation.structuralToSectioned, .sectionedToKernel]),
            (.structural, .sectioned, [.structuralToSectioned]),
            (.sectioned, .kernel, [.sectionedToKernel]),
            (.kernel, .sectioned, [.kernelToSectioned]),
            (.kernel, .structural, [.kernelToStructural]),
            (.sectioned, .structural, [.sectionedToStructural]),
            (.structural, .structural, []),
            (.kernel, .kernel, []),
          ])
    func chains(_ source: LLFSMLevel, _ target: LLFSMLevel, _ expected: [LevelTransformation]) {
        #expect(LevelTransformation.chain(from: source, to: target) == expected)
    }

    /// Check that every chain of transformations connects its levels.
    ///
    /// - Parameter source: The level to start from.
    @Test("every chain connects its levels", arguments: LLFSMLevel.allCases)
    func chainsConnect(_ source: LLFSMLevel) {
        for target in LLFSMLevel.allCases {
            var level = source
            for transformation in LevelTransformation.chain(from: source, to: target) {
                #expect(transformation.source == level)
                level = transformation.target
            }
            #expect(level == target)
        }
    }

    /// Check that no transformation stays at its level.
    @Test("no transformation stays at its level")
    func transformationsChangeLevel() {
        for transformation in LevelTransformation.allCases {
            #expect(transformation.source != transformation.target)
        }
    }
}
