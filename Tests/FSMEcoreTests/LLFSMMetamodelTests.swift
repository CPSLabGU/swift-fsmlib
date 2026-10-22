import XCTest
import ECore
@testable import FSMEcore

final class LLFSMMetamodelTests: XCTestCase {
    func testMetamodelLoadsExpectedClassesAndFeatures() async throws {
        let metamodel = try await LLFSMMetamodel()

        XCTAssertEqual(metamodel.package.name, "LLFSMStructural")
        XCTAssertEqual(metamodel.package.nsURI, "http://cpslabgu.github.io/LLFSMStructural")
        XCTAssertEqual(metamodel.package.nsPrefix, "llfsm")

        XCTAssertEqual(metamodel.machineClass.getEAttribute(name: "name")?.lowerBound, 1)
        XCTAssertEqual(metamodel.machineClass.getEAttribute(name: "language")?.lowerBound, 1)
        XCTAssertEqual(metamodel.machineClass.getEReference(name: "llfsm")?.containment, true)
        XCTAssertEqual(metamodel.machineClass.getEReference(name: "stateLayouts")?.upperBound, -1)

        XCTAssertEqual(metamodel.llfsmClass.getEReference(name: "states")?.containment, true)
        XCTAssertEqual(metamodel.llfsmClass.getEReference(name: "transitions")?.containment, true)
        XCTAssertEqual(metamodel.llfsmClass.getEReference(name: "suspendState")?.containment, false)

        XCTAssertEqual(metamodel.stateClass.getEAttribute(name: "name")?.lowerBound, 1)
        XCTAssertEqual(metamodel.stateClass.getEReference(name: "activities")?.containment, true)

        XCTAssertEqual(metamodel.transitionClass.getEAttribute(name: "label")?.lowerBound, 1)
        XCTAssertEqual(metamodel.transitionClass.getEReference(name: "source")?.containment, false)
        XCTAssertEqual(metamodel.transitionClass.getEReference(name: "target")?.containment, false)

        XCTAssertEqual(metamodel.stateLayoutClass.getEAttribute(name: "closedX")?.lowerBound, 0)
        XCTAssertEqual(metamodel.transitionLayoutClass.getEReference(name: "points")?.upperBound, -1)
        XCTAssertEqual(metamodel.point2DClass.getEAttribute(name: "x")?.name, "x")
        XCTAssertEqual(metamodel.point2DClass.getEAttribute(name: "y")?.name, "y")
    }

    func testRegisterMakesMetamodelAvailableToResourceSet() async throws {
        let metamodel = try await LLFSMMetamodel()
        let resourceSet = ResourceSet()

        await metamodel.register(in: resourceSet)

        let registered = await resourceSet.getMetamodel(uri: metamodel.package.nsURI)
        XCTAssertEqual(registered?.name, metamodel.package.name)
        XCTAssertNotNil(registered?.getEClass(metamodel.machineClass.name))
    }
}
