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
@usableFromInline let formatToLanguageBinding: [Format: LanguageBinding] = [
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