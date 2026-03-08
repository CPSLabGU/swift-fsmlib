import Foundation
import XCTest
@testable import FSMEcore

final class ExecutableGenerationTests: XCTestCase {
    @MainActor
    func testLegacyExecutableTemplatesReproduceExpectedOutputs() async throws {
        let metamodel = try await ExecutableLLFSMMetamodel()
        let generator = ExecutableTemplateGenerator(metamodel: metamodel)

        for model in legacyModels {
            let modelURL = try FSMEcoreTestSupport.legacyModelURL(named: model.fileStem)
            let resource = try await FSMEcoreTestSupport.loadExecutableResource(from: modelURL, metamodel: metamodel)

            for template in templates {
                let outputDirectory = try FSMEcoreTestSupport.makeTemporaryDirectory(
                    prefix: "executable-generation-\(model.expectedStem)-\(template.name)"
                )
                let templateURL = try FSMEcoreTestSupport.bundledExecutableTemplateURL(named: template.name)

                try await generator.generate(
                    templateURL: templateURL,
                    resource: resource,
                    outputDirectory: outputDirectory
                )

                let expectedURL = try FSMEcoreTestSupport.legacyExpectedURL(
                    named: model.expectedStem,
                    withExtension: template.fileExtension
                )
                let generatedURL = outputDirectory
                    .appendingPathComponent(model.expectedStem)
                    .appendingPathExtension(template.fileExtension)

                let expected = try String(contentsOf: expectedURL, encoding: .utf8)
                let generated = try String(contentsOf: generatedURL, encoding: .utf8)

                XCTAssertEqual(
                    normaliseLineEndings(generated),
                    normaliseLineEndings(expected),
                    "\(model.expectedStem) via \(template.name)"
                )
            }
        }
    }
}

private extension ExecutableGenerationTests {
    var legacyModels: [(fileStem: String, expectedStem: String)] {
        [
            ("Fischer", "FischerConcurrencyAlgorithm"),
            ("FischerBoolean", "FischerDelaysByBooleanSensors"),
            ("LamportBoolean", "BooleanFischerConcurrencyAlgorithm"),
            ("PingPongTikiTakaForC", "PingPongTikiTakaForC")
        ]
    }

    var templates: [(name: String, fileExtension: String)] {
        [
            ("llfsm2dot", "dot"),
            ("llfsm2tla", "tla"),
            ("llfsm2nusmv", "smv"),
            ("llfsm2prism", "pm"),
            ("llfsm2uppaal", "xml"),
            ("llfsm2c", "c"),
            ("llfsm2lisp", "lisp"),
            ("llfsm2mips", "asm")
        ]
    }

    func normaliseLineEndings(_ source: String) -> String {
        source.replacingOccurrences(of: "\r\n", with: "\n")
    }
}
