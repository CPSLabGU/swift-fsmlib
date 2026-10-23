//
//  StructuralTemplateServicesTests.swift
//  FSMEcoreTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation
import MTL
import Testing
@testable import FSMEcore

/// Tests for the text services offered to the structural templates.
@Suite("Structural template services")
struct StructuralTemplateServicesTests {
    @Test("Numbers are formatted with C conversions")
    func formatting() throws {
        #expect(try StructuralTemplateServices.format(607.27668023017429, with: "%.17g") == "607.27668023017429")
        #expect(try StructuralTemplateServices.format(1.0, with: "%.17g") == "1")
        #expect(try StructuralTemplateServices.format(33.333333333333336, with: "%.17g") == "33.333333333333336")
        #expect(try StructuralTemplateServices.format(2.5, with: "[%6.2f]") == "[  2.50]")
        #expect(try StructuralTemplateServices.format(42.0, with: "%d%%") == "42%")
        #expect(try StructuralTemplateServices.format(255, with: "%04X") == "00FF")
        #expect(try StructuralTemplateServices.format(9_007_199_254_740_993, with: "%d") == "9007199254740993")
        #expect(try StructuralTemplateServices.format(3, with: "%.1f") == "3.0")
    }

    @Test("Format specifications must hold exactly one supported conversion")
    func invalidFormats() {
        for format in ["", "plain", "%s", "%@", "%n", "%d %d", "%ld", "%1000f", "%.1000f", "%"] {
            #expect(throws: StructuralTemplateServicesError.invalidFormat(format)) {
                try StructuralTemplateServices.format(1.0, with: format)
            }
        }
        #expect(throws: StructuralTemplateServicesError.notIntegral("%d")) {
            try StructuralTemplateServices.format(1.5, with: "%d")
        }
    }

    @Test("Base64 text is decoded in the requested character set")
    func decoding() throws {
        let text = Data("<?xml?>\n\tä".utf8).base64EncodedString()
        #expect(try StructuralTemplateServices.base64Decode(text, charset: "UTF-8") == "<?xml?>\n\tä")
        let bytes = Data([0x00, 0x7F, 0x80, 0xFF]).base64EncodedString()
        let latin = try StructuralTemplateServices.base64Decode(bytes, charset: "ISO-8859-1")
        #expect(Array(latin.unicodeScalars.map(\.value)) == [0x00, 0x7F, 0x80, 0xFF])
        #expect(throws: StructuralTemplateServicesError.invalidBase64) {
            try StructuralTemplateServices.base64Decode("@@@", charset: "UTF-8")
        }
        #expect(throws: StructuralTemplateServicesError.undecodable("UTF-8")) {
            try StructuralTemplateServices.base64Decode(bytes, charset: "UTF-8")
        }
    }

    @Test("Errors describe the problem")
    func messages() {
        #expect(StructuralTemplateServicesError.invalidFormat("%s").errorDescription?.contains("%s") == true)
        #expect(StructuralTemplateServicesError.notIntegral("%d").errorDescription?.contains("whole") == true)
        #expect(StructuralTemplateServicesError.invalidBase64.errorDescription?.contains("Base64") == true)
        #expect(StructuralTemplateServicesError.undecodable("UTF-8").errorDescription?.contains("UTF-8") == true)
    }

    @Test("Templates can call the services")
    @MainActor
    func templateCalls() async throws {
        let encoded = Data("hello".utf8).base64EncodedString()
        let module = try await MTLParser().parse("""
            [module m('http://www.eclipse.org/emf/2002/Ecore')/]
            [template main()][(0.5).formatted('%.17g')/]|[(7).formatted('%03d')/]|['\(encoded)'.base64Decoded('UTF-8')/][/template]
            """, filename: "m.mtl")
        let strategy = MTLInMemoryStrategy()
        let generator = MTLGenerator(
            module: module, generationStrategy: strategy, serviceProviders: [StructuralTemplateServices()])
        try await generator.generate(mainTemplate: "main", arguments: [], models: [:])
        #expect(await strategy.getGeneratedFiles()["stdout"] == "0.5|007|hello")
    }
}
