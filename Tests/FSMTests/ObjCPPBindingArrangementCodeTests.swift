import XCTest
@testable import FSM

/// Unit tests for ObjCPPBinding+ArrangementCode.
///
/// These tests verify the correct generation of Objective-C++ arrangement header and implementation code
/// for various instance configurations, including edge cases such as empty arrangements and suspensible machines.
///
/// - Note: These tests ensure that the generated code is syntactically correct and contains all required elements.
final class ObjCPPBindingArrangementCodeTests: XCTestCase {
    /// Test header generation for a simple arrangement.
    func testHeaderGenerationSimpleArrangement() {
        let instances = [Instance(name: "instance1", typeFile: "Test.machine", machine: Machine())]
        let code = objcppArrangementHeader(for: instances, named: "TestArrangement", isSuspensible: false)
        XCTAssertTrue(code.contains("struct Arrangement_TestArrangement"))
        XCTAssertTrue(code.contains("fsm_instance1"))
        XCTAssertTrue(code.contains("#ifndef clfsm_arrangement_TestArrangement_h"))
        XCTAssertTrue(code.contains("ARRANGEMENT_TESTARRANGEMENT_NUMBER_OF_INSTANCES 1"))
        XCTAssertTrue(code.contains("void arrangement_testarrangement_init(struct Arrangement_TestArrangement * const arrangement);"))
        XCTAssertTrue(code.contains("bool arrangement_testarrangement_validate(struct Arrangement_TestArrangement * const arrangement);"))
    }

    /// Test header generation for an empty arrangement.
    func testHeaderGenerationEmptyArrangement() {
        let code = objcppArrangementHeader(for: [], named: "Empty", isSuspensible: false)
        XCTAssertTrue(code.contains("struct Arrangement_Empty"))
        XCTAssertTrue(code.contains("ARRANGEMENT_EMPTY_NUMBER_OF_INSTANCES 0"))
    }

    /// Test implementation generation for a simple arrangement.
    func testImplementationGenerationSimpleArrangement() {
        let machine = Machine()
        let instances = [Instance(name: "instance1", typeFile: "Test.machine", machine: machine)]
        let code = objcppArrangementImplementation(for: instances, named: "TestArrangement", isSuspensible: false)
        XCTAssertTrue(code.contains("#include \"Arrangement_TestArrangement.h\""))
        XCTAssertTrue(code.contains("arrangement->number_of_instances = ARRANGEMENT_TESTARRANGEMENT_NUMBER_OF_INSTANCES;"))
        XCTAssertTrue(code.contains("fsm_test_init(arrangement->fsm_instance1);"))
        XCTAssertTrue(code.contains("fsm_test_validate(arrangement->fsm_instance1);"))
    }

    /// Test implementation generation for multiple instances with different types.
    func testImplementationGenerationMultipleTypes() {
        let machine1 = Machine()
        let machine2 = Machine()
        let instances = [
            Instance(name: "alpha", typeFile: "Alpha.machine", machine: machine1),
            Instance(name: "beta", typeFile: "Beta.machine", machine: machine2)
        ]
        let code = objcppArrangementImplementation(for: instances, named: "Multi", isSuspensible: false)
        XCTAssertTrue(code.contains("#include \"Alpha.machine/Alpha.h\""))
        XCTAssertTrue(code.contains("#include \"Beta.machine/Beta.h\""))
        XCTAssertTrue(code.contains("fsm_alpha_init(arrangement->fsm_alpha);"))
        XCTAssertTrue(code.contains("fsm_beta_init(arrangement->fsm_beta);"))
        XCTAssertTrue(code.contains("fsm_alpha_validate(arrangement->fsm_alpha)"))
        XCTAssertTrue(code.contains("fsm_beta_validate(arrangement->fsm_beta)"))
    }

    /// Test generation for suspensible arrangement (should still generate code, as suspensible is a flag).
    func testHeaderAndImplementationSuspensible() {
        let machine = Machine()
        let instances = [Instance(name: "main", typeFile: "Main.machine", machine: machine)]
        let header = objcppArrangementHeader(for: instances, named: "Suspensible", isSuspensible: true)
        let impl = objcppArrangementImplementation(for: instances, named: "Suspensible", isSuspensible: true)
        XCTAssertTrue(header.contains("struct Arrangement_Suspensible"))
        XCTAssertTrue(impl.contains("arrangement->number_of_instances = ARRANGEMENT_SUSPENSIBLE_NUMBER_OF_INSTANCES;"))
    }
}
