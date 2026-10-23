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

@Suite("Variable declaration scanner")
struct VariableDeclarationScannerTests {
    let int = ScannedType.integer(name: "int", range: Int(Int32.min)...Int(Int32.max))
    let unsigned = ScannedType.integer(name: "unsigned", range: 0...Int(Int32.max))

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

    @Test("a repeated name is declared once")
    func repeatedName() {
        let result = VariableDeclarationScanner(language: "c").scan("int x;\nbool x;")
        #expect(result.declarations == [.init(name: "x", type: int)])
        #expect(result.remainder == "bool x;")
    }

    @Test("languages without simple declaration types keep the text", arguments: ["swift", "java", "scxml"])
    func otherLanguages(_ language: String) {
        let result = VariableDeclarationScanner(language: language).scan("int x;")
        #expect(result.declarations.isEmpty)
        #expect(result.remainder == "int x;")
    }

    @Test("array types are named after their element type and size")
    func arrayNames() {
        #expect(ScannedType.array(element: int, size: 4).name == "intArray4")
        #expect(ScannedType.boolean(name: "bool").name == "bool")
    }
}
