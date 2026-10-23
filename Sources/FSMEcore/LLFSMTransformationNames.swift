//
//  LLFSMTransformationNames.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase

/// The names and constants that the bundled LLFSM transformations share.
///
/// Every name that a transformation gives to an element it creates, and
/// every constant of the time encoding, is defined here once and passed to
/// the transformations as a module parameter, so that the encoding and its
/// inverse agree.
enum LLFSMTransformationNames {
    /// The bundled transformations.
    enum Module: String, CaseIterable, Sendable {
        /// Structural machines and arrangements to the sectioned level.
        case structuralToSectioned = "structural2sectioned"
        /// The encoding of sectioned models into the kernel.
        case sectionedToKernel = "sectioned2kernel"
        /// The inverse of the encoding, and the flat mapping of kernel models.
        case kernelToSectioned = "kernel2sectioned"
        /// Sectioned models back to structural machines and arrangements.
        case sectionedToStructural = "sectioned2structural"
    }

    /// The file extension of the bundled transformations.
    static let moduleExtension = "atl"

    /// The resource directory that holds the bundled transformations.
    static let moduleSubdirectory = "Resources/Transforms"

    /// The model aliases of the transformation headers.
    enum Alias {
        /// The source model.
        static let source = "IN"
        /// The kernel view of a sectioned source model.
        static let kernelSource = "KIN"
        /// The target model.
        static let target = "OUT"
        /// The kernel view of a sectioned target model.
        static let kernelTarget = "KOUT"
    }

    /// The names of the module parameters that carry the shared names.
    enum Parameter: String, CaseIterable, Sendable {
        case nowName, enteredAtName, resumeToName, suspendPrefix
        case timeTypeName, booleanTypeName, resumeTypeSuffix
        case clockMachineName, clockInstanceName, clockStateName
        case internalSuffix, waitSuffix, exitSuffix, suspendSuffix, resumeSuffix, dispatchSuffix
        case timeUpper, millisecondFactor, secondFactor, tickFactor
        case arrangementName
        case defaultLanguage, machineFileSuffix
    }

    /// The shared variable that holds the current time.
    static let now = "now"

    /// The local variable that holds the time at which the current state was entered.
    static let enteredAt = "enteredAt"

    /// The local variable that records the state to resume.
    static let resumeTo = "resumeTo"

    /// The prefix of the shared Boolean that requests the suspension of a machine.
    static let suspendPrefix = "suspend"

    /// The integer type of the current time.
    static let timeType = "Time"

    /// The Boolean type created when a model declares none.
    static let booleanType = "Bool"

    /// The suffix of the enumeration of the states a machine resumes to.
    static let resumeTypeSuffix = "States"

    /// The machine that advances the current time when the clock is internal.
    static let clockMachine = "Clock"

    /// The instance of the clock machine.
    static let clockInstance = "clock"

    /// The state of the clock machine.
    static let clockState = "Tick"

    /// The suffix of the pass-through state that runs the internal section.
    static let internalSuffix = "_i"

    /// The suffix of the state that rests between ringlets.
    static let waitSuffix = "_w"

    /// The suffix of a pass-through state that runs the exit section, followed by the transition index.
    static let exitSuffix = "_x"

    /// The suffix of the pass-through state that runs the suspend section.
    static let suspendSuffix = "_s"

    /// The suffix of the pass-through state that runs the resume section of a working state.
    static let resumeSuffix = "_r"

    /// The suffix of the pass-through state that dispatches a resumption.
    static let dispatchSuffix = "_d"

    /// The upper bound of the time type, in microseconds.
    ///
    /// The bound is the largest value of the 32-bit bounds of kernel integer types.
    static let timeUpper = Int(Int32.max)

    /// The number of microseconds in a millisecond.
    static let millisecondFactor = 1_000

    /// The number of microseconds in a second.
    static let secondFactor = 1_000_000

    /// The divisor that marks a time in ticks, which are counted in clock units.
    static let tickFactor = 1

    /// The name given to the arrangement of a single structural machine.
    static let defaultArrangementName = "Arrangement"

    /// The language of structural machines made from sectioned machines that name none.
    static let defaultLanguage = "c"

    /// The suffix that turns a machine name into the type file of a structural instance.
    static let machineFileSuffix = ".machine"

    /// The helpers implemented in Swift that the transformations call.
    enum NativeHelper {
        /// Renders an expression as host-language text: `renderExpression(e, language)`.
        static let renderExpression = "renderExpression"
        /// Renders a section as host-language text: `renderStatements(statements, language)`.
        static let renderStatements = "renderStatements"
        /// Renders variable declarations as host-language text: `renderDeclarations(variables, language)`.
        static let renderDeclarations = "renderDeclarations"
        /// Puts the declaration texts of variables back at their lines: `mergeDeclarations(text, variables)`.
        static let mergeDeclarations = "mergeDeclarations"
    }

    /// The values of the module parameters that carry the shared names.
    ///
    /// - Parameter arrangementName: The name of the arrangement to create from structural models.
    /// - Returns: The parameter values by name.
    static func parameters(arrangementName: String = defaultArrangementName) -> [String: any EcoreValue] {
        var values: [String: any EcoreValue] = [:]
        for parameter in Parameter.allCases {
            switch parameter {
            case .nowName: values[parameter.rawValue] = now
            case .enteredAtName: values[parameter.rawValue] = enteredAt
            case .resumeToName: values[parameter.rawValue] = resumeTo
            case .suspendPrefix: values[parameter.rawValue] = suspendPrefix
            case .timeTypeName: values[parameter.rawValue] = timeType
            case .booleanTypeName: values[parameter.rawValue] = booleanType
            case .resumeTypeSuffix: values[parameter.rawValue] = resumeTypeSuffix
            case .clockMachineName: values[parameter.rawValue] = clockMachine
            case .clockInstanceName: values[parameter.rawValue] = clockInstance
            case .clockStateName: values[parameter.rawValue] = clockState
            case .internalSuffix: values[parameter.rawValue] = internalSuffix
            case .waitSuffix: values[parameter.rawValue] = waitSuffix
            case .exitSuffix: values[parameter.rawValue] = exitSuffix
            case .suspendSuffix: values[parameter.rawValue] = suspendSuffix
            case .resumeSuffix: values[parameter.rawValue] = resumeSuffix
            case .dispatchSuffix: values[parameter.rawValue] = dispatchSuffix
            case .timeUpper: values[parameter.rawValue] = timeUpper
            case .millisecondFactor: values[parameter.rawValue] = millisecondFactor
            case .secondFactor: values[parameter.rawValue] = secondFactor
            case .tickFactor: values[parameter.rawValue] = tickFactor
            case .arrangementName: values[parameter.rawValue] = arrangementName
            case .defaultLanguage: values[parameter.rawValue] = defaultLanguage
            case .machineFileSuffix: values[parameter.rawValue] = machineFileSuffix
            }
        }
        return values
    }
}
