//
//  LLFSMLevel.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//

/// The levels at which `FSMEcore` describes logic-labelled finite-state machines.
///
/// Each level has its own metamodel (see <doc:MetamodelLevels>). The raw value
/// of a level is its name, as it appears in the names of output targets such as
/// `kernel-xmi`.
public enum LLFSMLevel: String, CaseIterable, Sendable, Codable {
    /// The structural level, which mirrors the native `swift-fsmlib` machines and arrangements.
    case structural
    /// The sectioned level, with entry, exit, internal, suspend and resume sections.
    case sectioned
    /// The kernel level, the sectionless core from which kernel targets are generated.
    case kernel

    /// The namespace URI that documents of the level qualify their root elements with.
    public var namespaceURI: String {
        switch self {
        case .structural:
            return LLFSMMetamodel.namespaceURI
        case .sectioned:
            return LLFSMMetamodels.sectionedNamespaceURI
        case .kernel:
            return LLFSMMetamodels.kernelNamespaceURI
        }
    }

    /// Find the level whose documents use a namespace.
    ///
    /// - Parameter namespaceURI: The namespace URI of the root element of a document.
    /// - Returns: The level, or `nil` if the namespace belongs to none of the levels.
    public init?(namespaceURI: String) {
        guard let level = Self.allCases.first(where: { $0.namespaceURI == namespaceURI }) else { return nil }
        self = level
    }
}

/// A transformation between two levels of LLFSMs.
///
/// The cases are the edges of the graph of levels;
/// ``chain(from:to:)`` finds the shortest path through it. Each case names
/// the ``LLFSMTransformations`` function that performs it.
public enum LevelTransformation: String, CaseIterable, Sendable, Codable {
    /// From the structural to the sectioned level (``LLFSMTransformations/structuralToSectioned(_:arrangementName:uri:)``).
    case structuralToSectioned
    /// From the sectioned level to the kernel (``LLFSMTransformations/sectionedToKernel(_:options:uri:)``).
    case sectionedToKernel
    /// From the kernel to the sectioned level (``LLFSMTransformations/kernelToSectioned(_:uri:)``).
    case kernelToSectioned
    /// From the sectioned to the structural level.
    case sectionedToStructural
    /// From the kernel to the structural level.
    case kernelToStructural

    /// The level of the model that the transformation reads.
    public var source: LLFSMLevel {
        switch self {
        case .structuralToSectioned:
            return .structural
        case .sectionedToKernel, .sectionedToStructural:
            return .sectioned
        case .kernelToSectioned, .kernelToStructural:
            return .kernel
        }
    }

    /// The level of the model that the transformation produces.
    public var target: LLFSMLevel {
        switch self {
        case .sectionedToStructural, .kernelToStructural:
            return .structural
        case .structuralToSectioned, .kernelToSectioned:
            return .sectioned
        case .sectionedToKernel:
            return .kernel
        }
    }

    /// The shortest sequence of transformations from one level to another.
    ///
    /// Among chains of equal length, the one whose transformations come first
    /// in declaration order is chosen, so the result is deterministic.
    ///
    /// - Parameters:
    ///   - source: The level of the model to transform.
    ///   - target: The level to reach.
    /// - Returns: The transformations in the order in which they run; empty if
    ///   the levels are the same.
    public static func chain(from source: LLFSMLevel, to target: LLFSMLevel) -> [LevelTransformation] {
        var paths: [LLFSMLevel: [LevelTransformation]] = [source: []]
        var frontier = [source]
        while !frontier.isEmpty, paths[target] == nil {
            var next: [LLFSMLevel] = []
            for level in frontier {
                for transformation in allCases where transformation.source == level && paths[transformation.target] == nil {
                    paths[transformation.target] = (paths[level] ?? []) + [transformation]
                    next.append(transformation.target)
                }
            }
            frontier = next
        }
        return paths[target] ?? []
    }
}
