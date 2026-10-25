//
//  VariableDeclarationScannerTests.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing
@testable import FSMEcore

/// Tests that the scanner recognises simple variable declarations and keeps all other text.
@Suite("Variable declaration scanner")
struct VariableDeclarationScannerTests {
    /// The scanned type of a signed 32-bit integer.
    let int = ScannedType.integer(name: "int", range: Int(Int32.min)...Int(Int32.max))
    /// The scanned type of an unsigned 32-bit integer.
    let unsigned = ScannedType.integer(name: "unsigned", range: 0...Int(Int32.max))

    /// Checks that simple declarations and their documentation comments are recognised.
    @Test("simple declarations with documentation comments are recognised")
    func simpleDeclarations() {
        let text = "int\tcounter;\t///< Bean counter\nbool flag;\nunsigned ticks;\nunsigned int  big ;\nsigned delta;\nint samples[4];"
        let result = VariableDeclarationScanner(language: "c").scan(text)
        #expect(result.declarations == [
            .init(name: "counter", type: int),
            .init(name: "flag", type: .boolean(name: "bool")),
            .init(name: "ticks", type: unsigned),
            .init(name: "big", type: unsigned),
            .init(name: "delta", type: int),
            .init(name: "samples", type: .array(element: int, size: 4)),
        ])
        #expect(result.remainder.isEmpty)
    }

    /// Checks that unrecognised lines are kept verbatim.
    @Test("everything else is kept verbatim, line by line")
    func remainder() {
        let lines = [
            "//", "// Counter_Variables.h", "//",
            "const char *\tmachine_name;\t///< ",
            "int\tcounter;\t///< Bean counter",
            "int a, b;", "int x = 0;", "long wide;", "int empty[0];", "int bool;", "int y; // plain comment",
            "time_t\tstart;\t///< start time", "",
        ]
        let result = VariableDeclarationScanner(language: "objc++").scan(lines.joined(separator: "\n"))
        #expect(result.declarations == [.init(name: "counter", type: int)])
        var expected = lines
        expected.remove(at: 4)
        #expect(result.remainder == expected.joined(separator: "\n"))
    }

    /// Checks that a repeated name is declared only once.
    @Test("a repeated name is declared once")
    func repeatedName() {
        let result = VariableDeclarationScanner(language: "c").scan("int x;\nbool x;")
        #expect(result.declarations == [.init(name: "x", type: int)])
        #expect(result.remainder == "bool x;")
    }

    /// Checks that languages without simple declaration types keep the text unchanged.
    ///
    /// - Parameter language: The language to scan.
    @Test("languages without simple declaration types keep the text", arguments: ["swift", "java", "scxml"])
    func otherLanguages(_ language: String) {
        let result = VariableDeclarationScanner(language: language).scan("int x;")
        #expect(result.declarations.isEmpty)
        #expect(result.remainder == "int x;")
    }

    /// Checks that recognised declarations record their line, text and comment.
    @Test("recognised declarations record their line, their verbatim text and their comment")
    func placements() {
        let text = "//\nint\tcounter;\t///< Bean counter\nbool flag;\nint other; ///<   \nunsigned ticks;///<Tick count  \n"
        let result = VariableDeclarationScanner(language: "c").scan(text)
        #expect(result.declarations.map(\.name) == ["counter", "flag", "other", "ticks"])
        #expect(result.placements == [
            .init(line: 1, text: "int\tcounter;\t///< Bean counter", documentation: "Bean counter"),
            .init(line: 2, text: "bool flag;", documentation: nil),
            .init(line: 3, text: "int other; ///<   ", documentation: nil),
            .init(line: 4, text: "unsigned ticks;///<Tick count  ", documentation: "Tick count"),
        ])
        #expect(result.remainder == "//\n")
        #expect(result.remainderLineCount == 2)
    }

    /// Checks that recognised declarations alone leave no remainder lines.
    @Test("a text of recognised declarations only leaves no remainder lines")
    func noRemainderLines() {
        let result = VariableDeclarationScanner(language: "c").scan("int x;\nbool y;")
        #expect(result.remainder.isEmpty)
        #expect(result.remainderLineCount == 0)
        let terminated = VariableDeclarationScanner(language: "c").scan("int x;\nbool y;\n")
        #expect(terminated.remainder.isEmpty)
        #expect(terminated.remainderLineCount == 1)
    }

    /// Checks that unrecognised text yields no placements.
    ///
    /// - Parameter language: The language to scan.
    @Test("unrecognised text has no placements", arguments: ["swift", "c"])
    func noPlacements(_ language: String) {
        let result = VariableDeclarationScanner(language: language).scan("int a, b;\n")
        #expect(result.placements.isEmpty)
        #expect(result.remainder == "int a, b;\n")
        #expect(result.remainderLineCount == 2)
    }

    /// Checks that merging placements into the remainder restores the scanned text.
    ///
    /// - Parameter text: The text to scan and merge back.
    @Test("merging the placements into the remainder gives back the scanned text", arguments: [
        "", "int x;", "int x;\n", "\n", "//\nint\tcounter;\t///< Bean counter\n",
        "int x;\n// note\nbool y;\n\n", "a\nint x;", "int x;\nint x;\nbool b;", "int a, b;\nint c;\n",
        "//\n// Counter_Variables.h\n//\nconst char *\tmachine_name;\t///< \nint\tcounter;\t///< Bean counter\n",
    ])
    func mergeInverts(_ text: String) {
        let result = VariableDeclarationScanner(language: "c").scan(text)
        let remainder = result.remainderLineCount == 0 ? nil : result.remainder
        #expect(VariableDeclarationScanner.merged(remainder: remainder, placements: result.placements) == text)
    }

    /// Checks that placements beyond the remainder are appended in line order.
    @Test("placements beyond the remainder are appended in line order")
    func mergeAppends() {
        let placements: [VariableDeclarationScanner.Placement] = [
            .init(line: 9, text: "bool late;", documentation: nil),
            .init(line: 0, text: "int first;", documentation: nil),
        ]
        #expect(VariableDeclarationScanner.merged(remainder: "a\nb", placements: placements)
            == "int first;\na\nb\nbool late;")
        #expect(VariableDeclarationScanner.merged(remainder: nil, placements: []).isEmpty)
        #expect(VariableDeclarationScanner.merged(remainder: "keep", placements: []) == "keep")
    }

    /// Checks that array types are named after their element type and size.
    @Test("array types are named after their element type and size")
    func arrayNames() {
        #expect(ScannedType.array(element: int, size: 4).name == "intArray4")
        #expect(ScannedType.boolean(name: "bool").name == "bool")
    }
}
