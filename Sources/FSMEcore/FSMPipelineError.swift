//
//  FSMPipelineError.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// The problems that stop an ``FSMPipeline``.
public enum FSMPipelineError: Error, Sendable, Equatable, CustomStringConvertible {
    /// No input was given.
    case noInput

    /// An input does not exist, with or without the `.machine` suffix.
    ///
    /// The associated value is the path as given.
    case missingInput(String)

    /// A model document has no root element of an LLFSM metamodel.
    ///
    /// The associated value is the path of the document.
    case unknownLevel(String)

    /// A structural model holds neither a machine nor an arrangement.
    case noStructuralRoot

    /// A step received a model at a level other than the one it reads.
    case levelMismatch(expected: LLFSMLevel, found: LLFSMLevel)

    /// The transformation between two levels is not available yet.
    case transformationUnavailable(from: LLFSMLevel, to: LLFSMLevel)

    /// No language binding writes a native format.
    ///
    /// The associated value is the name of the format.
    case noOutputLanguage(String)

    /// The kernel model violates rules of the requested validation profile.
    ///
    /// The associated value holds the diagnostics of the validation, including warnings.
    case invalidModel([KernelDiagnostic])

    /// A sentence that describes the problem.
    public var description: String {
        switch self {
        case .noInput:
            return "No input was given"
        case .missingInput(let path):
            return "File '\(path)' does not exist"
        case .unknownLevel(let path):
            return "'\(path)' holds no structural, sectioned or kernel LLFSM model"
        case .noStructuralRoot:
            return "The structural model holds neither a machine nor an arrangement"
        case .levelMismatch(let expected, let found):
            return "A \(expected.rawValue) model was expected, but the model is at the \(found.rawValue) level"
        case .transformationUnavailable(let source, let target):
            return "The transformation from the \(source.rawValue) to the \(target.rawValue) level is not available "
                + "in this release, so \(source.rawValue) models cannot be written in native formats yet"
        case .noOutputLanguage(let format):
            return "No output language for format '\(format)'"
        case .invalidModel(let diagnostics):
            return "The kernel model is not valid:\n" + diagnostics.map(\.description).joined(separator: "\n")
        }
    }
}

extension FSMPipelineError: LocalizedError {
    /// The ``description`` of the error.
    public var errorDescription: String? { description }
}
