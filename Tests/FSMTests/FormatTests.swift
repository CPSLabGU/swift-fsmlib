//
//  FormatTests.swift
//
//  Created by Rene Hexel on 26/02/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import XCTest
@testable import FSM

/// Unit tests for the `Format` enumeration.
///
/// These tests verify that `Format` file extensions, `isSingleFile` property,
/// and language binding mappings behave correctly.
final class FormatTests: XCTestCase {

    // MARK: - fileExtension Tests

    /// Test that SCXML format returns the correct file extension.
    func testSCXMLFileExtension() {
        XCTAssertEqual(Format.scxml.fileExtension, "scxml")
    }

    /// Test that C format returns the machine file extension.
    func testCFileExtension() {
        XCTAssertEqual(Format.c.fileExtension, "machine")
    }

    /// Test that C++ format returns the machine file extension.
    func testCXFileExtension() {
        XCTAssertEqual(Format.cx.fileExtension, "machine")
    }

    /// Test that cpp format returns the machine file extension.
    func testCPPFileExtension() {
        XCTAssertEqual(Format.cpp.fileExtension, "machine")
    }

    /// Test that cxx format returns the machine file extension.
    func testCXXFileExtension() {
        XCTAssertEqual(Format.cxx.fileExtension, "machine")
    }

    /// Test that ObjC format returns the machine file extension.
    func testObjCFileExtension() {
        XCTAssertEqual(Format.objC.fileExtension, "machine")
    }

    /// Test that ObjC++ format returns the machine file extension.
    func testObjCXFileExtension() {
        XCTAssertEqual(Format.objCX.fileExtension, "machine")
    }

    /// Test that objcpp format returns the machine file extension.
    func testObjCPPFileExtension() {
        XCTAssertEqual(Format.objCPP.fileExtension, "machine")
    }

    /// Test that Swift format returns the swift.machine extension.
    func testSwiftFileExtension() {
        XCTAssertEqual(Format.swift.fileExtension, "swift.machine")
    }

    /// Test that Verilog format returns the verilog.machine extension.
    func testVerilogFileExtension() {
        XCTAssertEqual(Format.verilog.fileExtension, "verilog.machine")
    }

    /// Test that VHDL format returns the vhdl.machine extension.
    func testVHDLFileExtension() {
        XCTAssertEqual(Format.vhdl.fileExtension, "vhdl.machine")
    }

    // MARK: - isSingleFile Tests

    /// Test that SCXML is a single-file format.
    func testSCXMLIsSingleFile() {
        XCTAssertTrue(Format.scxml.isSingleFile)
    }

    /// Test that C is not a single-file format.
    func testCIsNotSingleFile() {
        XCTAssertFalse(Format.c.isSingleFile)
    }

    /// Test that C++ is not a single-file format.
    func testCXIsNotSingleFile() {
        XCTAssertFalse(Format.cx.isSingleFile)
    }

    /// Test that cpp is not a single-file format.
    func testCPPIsNotSingleFile() {
        XCTAssertFalse(Format.cpp.isSingleFile)
    }

    /// Test that cxx is not a single-file format.
    func testCXXIsNotSingleFile() {
        XCTAssertFalse(Format.cxx.isSingleFile)
    }

    /// Test that objc is not a single-file format.
    func testObjCIsNotSingleFile() {
        XCTAssertFalse(Format.objC.isSingleFile)
    }

    /// Test that objc++ is not a single-file format.
    func testObjCXIsNotSingleFile() {
        XCTAssertFalse(Format.objCX.isSingleFile)
    }

    /// Test that objcpp is not a single-file format.
    func testObjCPPIsNotSingleFile() {
        XCTAssertFalse(Format.objCPP.isSingleFile)
    }

    /// Test that swift is not a single-file format.
    func testSwiftIsNotSingleFile() {
        XCTAssertFalse(Format.swift.isSingleFile)
    }

    /// Test that verilog is not a single-file format.
    func testVerilogIsNotSingleFile() {
        XCTAssertFalse(Format.verilog.isSingleFile)
    }

    /// Test that vhdl is not a single-file format.
    func testVHDLIsNotSingleFile() {
        XCTAssertFalse(Format.vhdl.isSingleFile)
    }

    // MARK: - Raw Value Tests

    /// Test that Format raw values match their string representations.
    func testRawValues() {
        XCTAssertEqual(Format.c.rawValue, "c")
        XCTAssertEqual(Format.cx.rawValue, "c++")
        XCTAssertEqual(Format.cpp.rawValue, "cpp")
        XCTAssertEqual(Format.cxx.rawValue, "cxx")
        XCTAssertEqual(Format.objC.rawValue, "objc")
        XCTAssertEqual(Format.objCX.rawValue, "objc++")
        XCTAssertEqual(Format.objCPP.rawValue, "objcpp")
        XCTAssertEqual(Format.scxml.rawValue, "scxml")
        XCTAssertEqual(Format.swift.rawValue, "swift")
        XCTAssertEqual(Format.verilog.rawValue, "verilog")
        XCTAssertEqual(Format.vhdl.rawValue, "vhdl")
    }

    // MARK: - outputLanguage Tests

    /// Test that outputLanguage returns an OutputLanguage for a known format.
    func testOutputLanguageForSCXML() {
        let lang = outputLanguage(for: .scxml)
        XCTAssertNotNil(lang)
        XCTAssertTrue(lang is SCXMLBinding)
    }

    /// Test that outputLanguage returns nil for formats without bindings.
    func testOutputLanguageForSwift() {
        let lang = outputLanguage(for: .swift)
        XCTAssertNil(lang)
    }

    /// Test that outputLanguage returns nil for nil format with no default.
    func testOutputLanguageForNilFormat() {
        let lang = outputLanguage(for: nil)
        XCTAssertNil(lang)
    }

    /// Test that outputLanguage falls back to the default when format is nil.
    func testOutputLanguageFallsBackToDefault() {
        let binding = CBinding()
        let lang = outputLanguage(for: nil, default: binding)
        XCTAssertNotNil(lang)
    }
}
