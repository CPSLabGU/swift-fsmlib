import XCTest
@testable import ATL
@testable import ECore
import EMFBase
@testable import FSM
@testable import FSMEcore

final class ATLTransformationTests: XCTestCase {
    @MainActor
    func testExecutableMetamodelAndATLModulesLoad() async throws {
        _ = try await LLFSMMetamodel()
        let executableMetamodel = try await ExecutableLLFSMMetamodel()
        XCTAssertNotNil(executableMetamodel.package.getEClass("StateMachine"))
        XCTAssertNotNil(executableMetamodel.package.getEClass("OpaqueStatement"))
        XCTAssertNotNil(executableMetamodel.package.getEClass("OpaqueExpression"))
        XCTAssertNotNil(executableMetamodel.package.getEClass("OnSuspendSection"))
        XCTAssertNotNil(executableMetamodel.package.getEClass("OnResumeSection"))
        XCTAssertNotNil(executableMetamodel.package.getEClass("StateLayout"))
        XCTAssertNotNil(executableMetamodel.package.getEClass("TransitionLayout"))

        let structuralToExecutable = try await loadModule(named: "structural2executable")
        XCTAssertEqual(structuralToExecutable.name, "structural2executable")
        XCTAssertTrue(structuralToExecutable.matchedRules.contains { $0.name == "State2ExecutableState" })
        XCTAssertTrue(structuralToExecutable.matchedRules.contains { $0.name == "Machine2ExecutableStateMachine" })

        let executableToStructural = try await loadModule(named: "executable2structural")
        XCTAssertEqual(executableToStructural.name, "executable2structural")
        XCTAssertTrue(executableToStructural.matchedRules.contains { $0.name == "ExecutableState2State" })
        XCTAssertTrue(executableToStructural.matchedRules.contains { $0.name == "StateMachine2Machine" })
    }

    @MainActor
    func testStructuralExecutableATLBridgeRoundTripsTrafficLightMachine() async throws {
        let structuralMetamodel = try await LLFSMMetamodel()
        let structuralCodec = MachineEcoreCodec(metamodel: structuralMetamodel)
        let sourceMachine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let structuralResource = Resource(uri: "memory:/TrafficLightStructural.xmi")
        _ = await structuralCodec.encode(sourceMachine, name: "TrafficLight", into: structuralResource)

        let transformer = LLFSMATLTransformer()
        let structuralToExecutableURL = try FSMEcoreTestSupport.bundledTransformURL(named: "structural2executable")
        let executableResource: Resource
        do {
            executableResource = try await transformer.transform(
                atlURL: structuralToExecutableURL,
                sourceResource: structuralResource
            )
        } catch {
            if let unresolved = await unresolvedObjectDescription(in: error, resource: structuralResource) {
                XCTFail(unresolved)
            }
            throw error
        }

        let executableMetamodel = try await ExecutableLLFSMMetamodel()
        let executableMachine = await FSMEcoreTestSupport.findObject(
            named: executableMetamodel.stateMachineClass.name,
            in: executableResource
        )
        XCTAssertNotNil(executableMachine)

        let executableToStructuralURL = try FSMEcoreTestSupport.bundledTransformURL(named: "executable2structural")
        let roundTrippedStructuralResource: Resource
        do {
            roundTrippedStructuralResource = try await transformer.transform(
                atlURL: executableToStructuralURL,
                sourceResource: executableResource
            )
        } catch {
            if let unresolved = await unresolvedObjectDescription(in: error, resource: executableResource) {
                XCTFail(unresolved)
            }
            throw error
        }

        let structuralMachineObject = await FSMEcoreTestSupport.findObject(
            named: structuralMetamodel.machineClass.name,
            in: roundTrippedStructuralResource
        )
        let structuralMachine = try XCTUnwrap(structuralMachineObject)
        let llfsmReference = await roundTrippedStructuralResource.eGet(
            objectId: structuralMachine.id,
            feature: "llfsm"
        )
        if llfsmReference == nil {
            let objects = await roundTrippedStructuralResource.getAllObjects().compactMap { $0 as? DynamicEObject }
            let counts = Dictionary(grouping: objects.map(\.eClass.name), by: { $0 }).mapValues(\.count)
            XCTFail("Structural ATL result missing llfsm reference. Object counts: \(counts)")
        }
        let decoded = try await structuralCodec.decode(structuralMachine, from: roundTrippedStructuralResource)
        FSMEcoreTestSupport.assertMachinesEqual(sourceMachine, decoded.machine)
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

    private func unresolvedObjectDescription(in error: Error, resource: Resource) async -> String? {
        let description = String(describing: error)
        guard let match = description.range(of: #"[0-9A-Fa-f-]{36}"#, options: .regularExpression) else {
            return nil
        }
        let candidate = String(description[match])
        guard let uuid = UUID(uuidString: candidate) else {
            return nil
        }
        let objectID = EUUID(uuid: uuid.uuid)
        guard let object = await resource.resolve(objectID) as? DynamicEObject else {
            return "ATL resolveTemp failed for source object \(candidate)"
        }
        return "ATL resolveTemp failed for \(object.eClass.name) source object \(candidate)"
    }
}
