import XCTest
import ECore
@testable import FSM
@testable import FSMEcore

final class XMIRoundTripTests: XCTestCase {
    func testMachineXmiRoundTripPreservesTrafficLightMachine() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let metamodel = try await LLFSMMetamodel()
        let roundTrip = XMIRoundTrip(metamodel: metamodel)

        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        let xmiURL = tempDirectory.appendingPathComponent("TrafficLight.xmi")

        try await roundTrip.write(machine: machine, name: "TrafficLight", to: xmiURL)
        let decoded = try await roundTrip.readMachine(from: xmiURL)

        XCTAssertEqual(decoded.name, "TrafficLight")
        FSMEcoreTestSupport.assertMachinesEqual(machine, decoded.machine)
    }

    func testArrangementXmiRoundTripPreservesInstances() async throws {
        let metamodel = try await LLFSMMetamodel()
        let roundTrip = XMIRoundTrip(metamodel: metamodel)
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let arrangement = Arrangement(
            namedInstances: [
                Instance(name: "alpha", typeFile: "TrafficLight.machine", machine: machine),
                Instance(name: "beta", typeFile: "TrafficLight.machine", machine: Machine(copying: machine))
            ]
        )

        let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        let xmiURL = tempDirectory.appendingPathComponent("TrafficLights.xmi")

        try await roundTrip.write(arrangement: arrangement, to: xmiURL)
        let decoded = try await roundTrip.readArrangement(from: xmiURL)

        XCTAssertEqual(decoded.namedInstances.map(\.name), ["alpha", "beta"])
        XCTAssertEqual(decoded.namedInstances.map(\.typeFile), ["TrafficLight.machine", "TrafficLight.machine"])
        for (lhs, rhs) in zip(arrangement.namedInstances, decoded.namedInstances) {
            FSMEcoreTestSupport.assertMachinesEqual(lhs.machine, rhs.machine)
        }
    }

    func testMachineReadAndWriteReportNoDiagnosticsForStructuralDocument() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let roundTrip = XMIRoundTrip(metamodel: try await LLFSMMetamodel())
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "xmi-diagnostics")
        let xmiURL = directory.appendingPathComponent("TrafficLight.xmi")

        var writeDiagnostics = ConversionDiagnostics()
        try await roundTrip.write(machine: machine, name: "TrafficLight", to: xmiURL, diagnostics: &writeDiagnostics)
        var readDiagnostics = ConversionDiagnostics()
        let decoded = try await roundTrip.readMachine(from: xmiURL, diagnostics: &readDiagnostics)

        XCTAssertTrue(writeDiagnostics.isEmpty, String(describing: writeDiagnostics.warnings))
        XCTAssertTrue(readDiagnostics.isEmpty, String(describing: readDiagnostics.warnings))
        XCTAssertEqual(decoded.name, "TrafficLight")
        FSMEcoreTestSupport.assertMachinesEqual(machine, decoded.machine)
    }

    func testArrangementReadAndWriteReportNoDiagnosticsForStructuralDocument() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let arrangement = Arrangement(namedInstances: [
            Instance(name: "alpha", typeFile: "TrafficLight.machine", machine: machine),
        ])
        let roundTrip = XMIRoundTrip(metamodel: try await LLFSMMetamodel())
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "xmi-diagnostics")
        let xmiURL = directory.appendingPathComponent("TrafficLights.xmi")

        var writeDiagnostics = ConversionDiagnostics()
        try await roundTrip.write(arrangement: arrangement, to: xmiURL, diagnostics: &writeDiagnostics)
        var readDiagnostics = ConversionDiagnostics()
        let decoded = try await roundTrip.readArrangement(from: xmiURL, diagnostics: &readDiagnostics)

        XCTAssertTrue(writeDiagnostics.isEmpty, String(describing: writeDiagnostics.warnings))
        XCTAssertTrue(readDiagnostics.isEmpty, String(describing: readDiagnostics.warnings))
        XCTAssertEqual(decoded.namedInstances.map(\.name), ["alpha"])
        FSMEcoreTestSupport.assertMachinesEqual(machine, decoded.namedInstances[0].machine)
    }

    func testLoadResourceUsesStructuralMetamodelClasses() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let metamodel = try await LLFSMMetamodel()
        let roundTrip = XMIRoundTrip(metamodel: metamodel)
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "xmi-resource")
        let xmiURL = directory.appendingPathComponent("TrafficLight.xmi")
        try await roundTrip.write(machine: machine, name: "TrafficLight", to: xmiURL)

        var diagnostics = ConversionDiagnostics()
        let resource = try await roundTrip.loadResource(from: xmiURL, diagnostics: &diagnostics)
        let root = await FSMEcoreTestSupport.findObject(named: metamodel.machineClass.name, in: resource)

        XCTAssertTrue(diagnostics.isEmpty, String(describing: diagnostics.warnings))
        XCTAssertEqual(root?.eClass.getEReference(name: "llfsm")?.containment, true)
        XCTAssertEqual(root?.eClass.getEAttribute(name: "language")?.lowerBound, 1)
    }

    func testLoadResourceReportsClassesOutsideStructuralMetamodel() async throws {
        let roundTrip = XMIRoundTrip(metamodel: try await LLFSMMetamodel())
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "xmi-foreign")
        let xmiURL = directory.appendingPathComponent("Foreign.xmi")
        let document = """
            <?xml version="1.0" encoding="UTF-8"?>
            <other:Gadget xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" \
            xmlns:other="http://example.org/other" name="sample"/>
            """
        try document.write(to: xmiURL, atomically: true, encoding: .utf8)

        var diagnostics = ConversionDiagnostics()
        _ = try await roundTrip.loadResource(from: xmiURL, diagnostics: &diagnostics)

        XCTAssertEqual(diagnostics.warnings.map(\.kind), [.untypedClass(name: "Gadget")])
    }

    func testReadMachineFailsForDocumentWithoutMachine() async throws {
        let roundTrip = XMIRoundTrip(metamodel: try await LLFSMMetamodel())
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "xmi-foreign")
        let xmiURL = directory.appendingPathComponent("Foreign.xmi")
        let document = """
            <?xml version="1.0" encoding="UTF-8"?>
            <other:Gadget xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" \
            xmlns:other="http://example.org/other" name="sample"/>
            """
        try document.write(to: xmiURL, atomically: true, encoding: .utf8)

        var diagnostics = ConversionDiagnostics()
        do {
            _ = try await roundTrip.readMachine(from: xmiURL, diagnostics: &diagnostics)
            XCTFail("Reading a document without a machine should fail")
        } catch LLFSMMetamodelError.missingFeature {
            XCTAssertFalse(diagnostics.isEmpty)
        }
    }

    func testWrittenMachineDeclaresStructuralNamespace() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let metamodel = try await LLFSMMetamodel()
        let roundTrip = XMIRoundTrip(metamodel: metamodel)
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "xmi-namespace")
        let xmiURL = directory.appendingPathComponent("TrafficLight.xmi")

        try await roundTrip.write(machine: machine, name: "TrafficLight", to: xmiURL)
        let text = try String(contentsOf: xmiURL, encoding: .utf8)

        let prefix = metamodel.package.nsPrefix
        XCTAssertTrue(text.contains("xmlns:\(prefix)=\"\(metamodel.package.nsURI)\""), text)
        XCTAssertTrue(text.contains("<\(prefix):\(metamodel.machineClass.name) "), text)
    }

    func testReadsMachineDocumentWithoutStructuralNamespace() async throws {
        let machine = try FSMEcoreTestSupport.loadTrafficLightMachine()
        let metamodel = try await LLFSMMetamodel()
        let roundTrip = XMIRoundTrip(metamodel: metamodel)
        let directory = try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "xmi-unqualified")
        let xmiURL = directory.appendingPathComponent("TrafficLight.xmi")
        let resource = Resource(uri: xmiURL.absoluteString)
        _ = await MachineEcoreCodec(metamodel: metamodel).encode(machine, name: "TrafficLight", into: resource)
        let text = try await XMISerializer(options: .legacy).serialize(resource)
        XCTAssertFalse(text.contains(metamodel.package.nsURI))
        try text.write(to: xmiURL, atomically: true, encoding: .utf8)

        var diagnostics = ConversionDiagnostics()
        let decoded = try await roundTrip.readMachine(from: xmiURL, diagnostics: &diagnostics)

        XCTAssertTrue(diagnostics.warnings.contains(ConversionWarning(.untypedClass(name: metamodel.machineClass.name))))
        XCTAssertEqual(decoded.name, "TrafficLight")
        FSMEcoreTestSupport.assertMachinesEqual(machine, decoded.machine)
    }
}
