//
//  Format.swift
//
//  Created by Rene Hexel on 12/8/2023.
//  Copyright © 2015, 2016, 2023 Rene Hexel. All rights reserved.
//
/// Known machine formats.
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
    /// A Swift FSM
    case swift
    /// A Verilog FSM
    case verilog
    /// A VHDL FSM
    case vhdl
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
    //    .swift: SwiftBinding(),
    //    .verilog: VerilogBinding(),
    //    .vhdl: VHDLBinding(),
]

/// Return the output language associated with the given format.
/// 
/// - Parameter format: T
/// Return the output language associated with the given format.
///
/// - Parameters:
///   - format: The desired language format.
///   - default: The default format if `format` is `nil`
/// - Returns: The output language associated with the given format, or `nil` if there is none.
@inlinable
public func outputLanguage(for format: Format?, default: (any LanguageBinding)? = nil) -> (any OutputLanguage)? {
    (format.flatMap { formatToLanguageBinding[$0] } ?? `default`) as? (any OutputLanguage)
}
