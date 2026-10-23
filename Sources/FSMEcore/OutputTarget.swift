//
//  OutputTarget.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
@preconcurrency import FSM

/// What a conversion writes: a native machine format, a model document or a kernel target.
///
/// Every output target has a name, its raw value, under which `fsmconvert`
/// accepts it with `--format`:
///
/// - the native formats of ``FSM/Format``, such as `c`, `objcpp` and `scxml`,
///   which are written from the structural level;
/// - `xmi` and `json`, model documents at the level of the model or at the
///   level chosen by the caller;
/// - `structural-xmi`, `sectioned-xmi` and `kernel-xmi`, XMI documents at a
///   fixed level;
/// - the kernel targets of ``KernelTarget``, such as `kernel-c`, `smv` and
///   `dot`, which are generated from the kernel level.
///
/// ```swift
/// let target = OutputTarget(rawValue: "smv")
/// print(target?.level)        // Optional(kernel)
/// print(OutputTarget.c.isNative)   // true
/// ```
public struct OutputTarget: RawRepresentable, Hashable, Sendable, CaseIterable, CustomStringConvertible {
    /// The kinds of output target.
    public enum Kind: Hashable, Sendable {
        /// A native machine or arrangement format.
        case native(Format)
        /// A model document in a model format, at a fixed level or, for `nil`,
        /// at the level of the model or the one chosen by the caller.
        case model(ModelFormat, LLFSMLevel?)
        /// Text generated from a kernel model by a bundled template set.
        case kernel(KernelTarget)
    }

    /// The name of the target.
    public let rawValue: String

    /// What the target writes.
    public let kind: Kind

    /// Create a target.
    ///
    /// - Parameters:
    ///   - rawValue: The name of the target.
    ///   - kind: What the target writes.
    private init(_ rawValue: String, _ kind: Kind) {
        self.rawValue = rawValue
        self.kind = kind
    }

    /// Find the target with a name.
    ///
    /// - Parameter rawValue: The name of the target, such as `kernel-c`.
    /// - Returns: The target, or `nil` if no target has the name.
    public init?(rawValue: String) {
        guard let target = Self.allCases.first(where: { $0.rawValue == rawValue }) else { return nil }
        self = target
    }

    /// The target that writes a native format.
    ///
    /// - Parameter format: The native format.
    /// - Returns: The target whose name is the raw value of the format.
    public static func native(_ format: Format) -> OutputTarget {
        OutputTarget(format.rawValue, .native(format))
    }

    /// The target that writes an XMI document at a level.
    ///
    /// - Parameter level: The level of the written model.
    /// - Returns: The target named after the level, such as `kernel-xmi`.
    public static func xmi(at level: LLFSMLevel) -> OutputTarget {
        OutputTarget(level.rawValue + levelSeparator + ModelFormat.xmi.rawValue, .model(.xmi, level))
    }

    /// The target that generates a kernel target.
    ///
    /// - Parameter target: The kernel target.
    /// - Returns: The target whose name is the raw value of the kernel target.
    public static func kernel(_ target: KernelTarget) -> OutputTarget {
        OutputTarget(target.rawValue, .kernel(target))
    }

    /// The separator between the level and the format in the name of a level-specific target.
    public static let levelSeparator = "-"

    /// A plain C machine.
    public static let c = native(.c)
    /// An Objective-C++ machine, named `c++`.
    public static let cx = native(.cx)
    /// An Objective-C++ machine, named `cpp`.
    public static let cpp = native(.cpp)
    /// An Objective-C++ machine, named `cxx`.
    public static let cxx = native(.cxx)
    /// An Objective-C++ machine, named `objc`.
    public static let objC = native(.objC)
    /// An Objective-C++ machine, named `objc++`.
    public static let objCX = native(.objCX)
    /// An Objective-C++ machine, named `objcpp`.
    public static let objCPP = native(.objCPP)
    /// An SCXML document.
    public static let scxml = native(.scxml)
    /// A Swift machine.
    public static let swift = native(.swift)
    /// A Verilog machine.
    public static let verilog = native(.verilog)
    /// A VHDL machine.
    public static let vhdl = native(.vhdl)

    /// An XMI document at the level of the model, or the level chosen by the caller.
    public static let xmi = OutputTarget(ModelFormat.xmi.rawValue, .model(.xmi, nil))
    /// A JSON document at the level of the model, or the level chosen by the caller.
    public static let json = OutputTarget(ModelFormat.json.rawValue, .model(.json, nil))
    /// A structural XMI document.
    public static let structuralXMI = xmi(at: .structural)
    /// A sectioned XMI document.
    public static let sectionedXMI = xmi(at: .sectioned)
    /// A kernel XMI document.
    public static let kernelXMI = xmi(at: .kernel)

    /// A C11 program generated from the kernel.
    public static let kernelC = kernel(.c)
    /// A C++20 program generated from the kernel.
    public static let kernelCPP = kernel(.cpp)
    /// A Swift 6 program generated from the kernel.
    public static let kernelSwift = kernel(.swift)
    /// A Java 17 program generated from the kernel.
    public static let kernelJava = kernel(.java)
    /// A nuXmv or NuSMV model generated from the kernel.
    public static let smv = kernel(.smv)
    /// A TLA+ specification generated from the kernel.
    public static let tla = kernel(.tla)
    /// A Graphviz drawing generated from the kernel.
    public static let dot = kernel(.dot)

    /// Every target: the native formats, the model documents and the kernel targets.
    public static let allCases: [OutputTarget] = Format.allCases.map(native)
        + [xmi, json] + LLFSMLevel.allCases.map { xmi(at: $0) } + KernelTarget.allCases.map(kernel)

    /// The language names that stand for the execution targets of the kernel
    /// when the kernel level is chosen.
    public static let kernelLanguageSynonyms: [String: KernelTarget] = [
        Format.c.rawValue: .c,
        Format.cpp.rawValue: .cpp,
        Format.swift.rawValue: .swift,
        "java": .java,
    ]

    /// Find the target that a name denotes when a level is chosen.
    ///
    /// At the kernel level, the language names of ``kernelLanguageSynonyms``,
    /// such as `c` and `java`, denote the execution targets of the kernel; every
    /// other name denotes the target of that name.
    ///
    /// - Parameters:
    ///   - name: The name of the target, ignoring case.
    ///   - level: The level chosen by the caller, if any.
    /// - Returns: The target, or `nil` if the name denotes none.
    public static func named(_ name: String, level: LLFSMLevel?) -> OutputTarget? {
        let name = name.lowercased()
        if level == .kernel, let target = kernelLanguageSynonyms[name] { return kernel(target) }
        return OutputTarget(rawValue: name)
    }

    /// The names that ``named(_:level:)`` accepts at a level, in the order of ``allCases``.
    ///
    /// - Parameter level: The level chosen by the caller, if any.
    /// - Returns: The names of every target, followed at the kernel level by the
    ///   synonyms that are not names of their own.
    public static func names(level: LLFSMLevel?) -> [String] {
        let names = allCases.map(\.rawValue)
        guard level == .kernel else { return names }
        return names + kernelLanguageSynonyms.keys.sorted().filter { !names.contains($0) }
    }

    /// The level of the model that the target is written from.
    ///
    /// Native formats are written from the structural level and kernel targets
    /// from the kernel; `xmi` and `json` have no level of their own (`nil`).
    public var level: LLFSMLevel? {
        switch kind {
        case .native: return .structural
        case .model(_, let level): return level
        case .kernel: return .kernel
        }
    }

    /// Whether the target is a native machine or arrangement format.
    public var isNative: Bool { format != nil }

    /// The native format that the target writes, if it is native.
    public var format: Format? {
        guard case .native(let format) = kind else { return nil }
        return format
    }

    /// The model format that the target writes, if it writes a model document.
    public var modelFormat: ModelFormat? {
        guard case .model(let format, _) = kind else { return nil }
        return format
    }

    /// The kernel target that the target generates, if it is a kernel target.
    public var kernelTarget: KernelTarget? {
        guard case .kernel(let target) = kind else { return nil }
        return target
    }

    /// The name of the target.
    public var description: String { rawValue }
}

/// The generators that write native machine and arrangement formats.
///
/// The raw value of each generator is its name on the command line.
public enum NativeGenerator: String, CaseIterable, Sendable {
    /// The bundled structural MTL templates (see ``TemplateBinding``), the default.
    ///
    /// Formats that no template set writes fall back to the Swift language bindings.
    case templates = "mtl"
    /// The language bindings written in Swift.
    case swift
}
