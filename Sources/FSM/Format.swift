//
//  Format.swift
//
//  Created by Rene Hexel on 12/8/2023.
//  Copyright © 2015, 2016, 2023 Rene Hexel. All rights reserved.
//
/// Known machine formats.
///
/// This enumeration lists the supported language formats for FSM code generation,
/// including C, C++, Objective-C++, Swift, Verilog, and VHDL. Each case maps to
/// a language binding implementation used for serialisation and deserialisation.
public enum Format: String, RawRepresentable, Hashable, CaseIterable, Codable {
    /// A plain C FSM
    case c
    /// A C++ FSM
    case cx = "c++"
    /// A C++ FSM
    case cpp
    /// A C++ FSM
    case cxx
    /// An Objective-C FSM
    case objC = "objc"
    /// An Objective-C++ FSM
    case objCX = "objc++"
    /// An Objective-C++ FSM
    case objCPP = "objcpp"
    /// An SCXML FSM
    case scxml
    /// A Swift FSM
    case swift
    /// A Verilog FSM
    case verilog
    /// A VHDL FSM
    case vhdl

    /// Return the file extension for this format.
    public var fileExtension: String {
        switch self {
        case .scxml:
            return rawValue
        case .c, .cx, .cpp, .cxx, .objC, .objCX, .objCPP:
            return "machine"
        case .swift:
            return "swift.machine"
        case .verilog:
            return "verilog.machine"
        case .vhdl:
            return "vhdl.machine"
        }
    }

    /// Return whether this format uses single-file storage (vs directory-based).
    public var isSingleFile: Bool {
        switch self {
        case .scxml:
            return true
        default:
            return false
        }
    }
}

/// Format to language binding mapping.
@usableFromInline let formatToLanguageBinding: [Format: any LanguageBinding] = [
    .c: CBinding(),
    .cx: ObjCPPBinding(),
    .cpp: ObjCPPBinding(),
    .cxx: ObjCPPBinding(),
    .objC: ObjCPPBinding(),
    .objCX: ObjCPPBinding(),
    .objCPP: ObjCPPBinding(),
    .scxml: SCXMLBinding(),
    //    .swift: SwiftBinding(),
    //    .verilog: VerilogBinding(),
    //    .vhdl: VHDLBinding(),
]

/// Return the output language associated with the given format.
///
/// This function maps a ``Format`` value to its corresponding
/// ``OutputLanguage`` implementation, falling back to the
/// provided default if the format is `nil`.
///
/// - Parameters:
///   - format: The desired language format.
///   - default: The default format if `format` is `nil`.
/// - Returns: The output language associated with the given format, or `nil` if there is none.
@inlinable
public func outputLanguage(for format: Format?, default: (any LanguageBinding)? = nil) -> (any OutputLanguage)? {
    (format.flatMap { formatToLanguageBinding[$0] } ?? `default`) as? (any OutputLanguage)
}
