import XCTest
@testable import ATL
@testable import ECore
@testable import FSM
@testable import FSMEcore

final class ATLTransformationTests: XCTestCase {
    @MainActor
    func testFormalMetamodelAndATLModulesLoad() async throws {
        _ = try await LLFSMMetamodel()
        let formalMetamodel = try await FormalLLFSMMetamodel()
        XCTAssertNotNil(formalMetamodel.package.getEClass("StateMachine"))
        XCTAssertNotNil(formalMetamodel.package.getEClass("OpaqueCode"))
        XCTAssertNotNil(formalMetamodel.package.getEClass("OpaqueExpression"))
        XCTAssertNotNil(formalMetamodel.package.getEClass("OnSuspendSection"))
        XCTAssertNotNil(formalMetamodel.package.getEClass("OnResumeSection"))
        XCTAssertNotNil(formalMetamodel.package.getEClass("StateLayout"))
        XCTAssertNotNil(formalMetamodel.package.getEClass("TransitionLayout"))

        let structuralToFormal = try await loadModule(named: "structural2formal")
        XCTAssertEqual(structuralToFormal.name, "structural2formal")
        XCTAssertTrue(structuralToFormal.matchedRules.contains { $0.name == "State2FormalState" })
        XCTAssertTrue(structuralToFormal.matchedRules.contains { $0.name == "Machine2StateMachine" })

        let formalToStructural = try await loadModule(named: "formal2structural")
        XCTAssertEqual(formalToStructural.name, "formal2structural")
        XCTAssertTrue(formalToStructural.matchedRules.contains { $0.name == "FormalState2State" })
        XCTAssertTrue(formalToStructural.matchedRules.contains { $0.name == "StateMachine2Machine" })
    }

    @MainActor
    private func loadModule(named name: String) async throws -> ATLModule {
        let testsURL = URL(fileURLWithPath: #filePath)
        let repoURL = testsURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = repoURL
            .appendingPathComponent("Sources/FSMEcore/Resources/Transforms", isDirectory: true)
            .appendingPathComponent(name)
            .appendingPathExtension("atl")
        guard FileManager.default.fileExists(atPath: url.path) else {
            XCTFail("Missing ATL resource \(name)")
            throw NSError(domain: "FSMEcoreTests", code: 2)
        }
        let parser = ATLParser()
        return try await parser.parse(url)
    }
}
