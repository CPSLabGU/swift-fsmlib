import XCTest
@testable import FSM

final class CodeGenerationTests: XCTestCase {

    func testCodeBuilder() {
        // Test basic code block creation
        let basicCode = Code.block {
            "line 1"
            "line 2"
            "line 3"
        }

        XCTAssertEqual(basicCode, "line 1\nline 2\nline 3")

        // Test indented block
        let indentedCode = Code.indentedBlock {
            "line 1"
            "line 2"
            "line 3"
        }

        XCTAssertEqual(indentedCode, "    line 1\n    line 2\n    line 3")

        // Test braced block
        let bracedCode = Code.bracedBlock {
            "line 1"
            "line 2"
            "line 3"
        }

        XCTAssertEqual(bracedCode, "{\n    line 1\n    line 2\n    line 3\n}")

        // Test including file
        let includeCode = Code.includeFile(named: "TEST_H") {
            "#include <stdio.h>"
            "#include <stdlib.h>"
            ""
            "void test_function(void);"
        }

        XCTAssertTrue(includeCode.contains("#ifndef TEST_H"))
        XCTAssertTrue(includeCode.contains("#define TEST_H"))
        XCTAssertTrue(includeCode.contains("void test_function(void);"))
        XCTAssertTrue(includeCode.contains("#endif /* TEST_H */"))

        // Test forEach
        let arrayCode = Code.forEach(["a", "b", "c"]) { item in
            "item: \(item)"
        }

        XCTAssertEqual(arrayCode, "item: a\nitem: b\nitem: c")

        // Test enumerating
        let enumeratedCode = Code.enumerating(array: ["x", "y", "z"]) { index, item in
            "[\(index)]: \(item)"
        }

        XCTAssertEqual(enumeratedCode, "[0]: x\n[1]: y\n[2]: z")
    }

    func testCBindingCodeGeneration() {
        // Create a simple FSM
        let state1 = State(name: "Initial")
        let state2 = State(name: "Processing")
        let state3 = State(name: "Complete")

        let transition1 = Transition(label: "start", source: state1.id, target: state2.id)
        let transition2 = Transition(label: "finish", source: state2.id, target: state3.id)

        let llfsm = LLFSM(states: [state1, state2, state3],
                          transitions: [transition1, transition2],
                          suspendState: nil)

        // Generate C interface code
        let interfaceCode = cMachineInterface(for: llfsm, named: "TestMachine", isSuspensible: false)

        // Verify parts of the generated code
        XCTAssertTrue(interfaceCode.contains("Machine_TestMachine.h"))
        XCTAssertTrue(interfaceCode.contains("#define MACHINE_TESTMACHINE_NUMBER_OF_STATES 3"))
        XCTAssertTrue(interfaceCode.contains("#define MACHINE_TESTMACHINE_IS_SUSPENSIBLE 0"))
        XCTAssertTrue(interfaceCode.contains("struct Machine_TestMachine"))
        XCTAssertTrue(interfaceCode.contains("void fsm_testmachine_init(struct Machine_TestMachine *)"))

        // Generate C implementation code
        let implementationCode = cMachineCode(for: llfsm, named: "TestMachine", isSuspensible: false)

        // Verify parts of the generated code
        XCTAssertTrue(implementationCode.contains("Machine_TestMachine.c"))
        XCTAssertTrue(implementationCode.contains("void fsm_testmachine_init(struct Machine_TestMachine * const machine)"))
        XCTAssertTrue(implementationCode.contains("machine->current_state = machine->states[0];"))

        // Generate state interface
        let stateInterfaceCode = cStateInterface(for: state1, llfsm: llfsm, named: "TestMachine", isSuspensible: false)

        // Verify parts of the generated code
        XCTAssertTrue(stateInterfaceCode.contains("State_Initial.h"))
        XCTAssertTrue(stateInterfaceCode.contains("struct FSMTestMachine_State_Initial"))
        XCTAssertTrue(stateInterfaceCode.contains("void fsm_testmachine_initial_on_entry"))

        // Test suspensible code generation
        let suspensibleCode = cMachineInterface(for: llfsm, named: "TestMachine", isSuspensible: true)
        XCTAssertTrue(suspensibleCode.contains("#define MACHINE_TESTMACHINE_IS_SUSPENSIBLE 1"))
        XCTAssertTrue(suspensibleCode.contains("struct LLFSMState *suspend_state;"))
    }

    func testCBindingArrangementCodeGeneration() {
        // Create a simple arrangement with two instances
        let state1 = State(name: "Initial")
        let state2 = State(name: "Final")

        let transition = Transition(label: "finish", source: state1.id, target: state2.id)

        let llfsm = LLFSM(states: [state1, state2],
                         transitions: [transition],
                         suspendState: nil)

        let machine = Machine()
        machine.llfsm = llfsm
        machine.language = CBinding()

        let instance1 = Instance(name: "instance1", typeFile: "Machine1.machine", machine: machine)
        let instance2 = Instance(name: "instance2", typeFile: "Machine1.machine", machine: machine)

        let instances = [instance1, instance2]

        // Generate arrangement interface
        let arrangementInterface = cArrangementInterface(for: instances, named: "TestArrangement", isSuspensible: true)

        // Verify parts of the generated code
        XCTAssertTrue(arrangementInterface.contains("Arrangement_TestArrangement.h"))
        XCTAssertTrue(arrangementInterface.contains("#define ARRANGEMENT_TESTARRANGEMENT_NUMBER_OF_INSTANCES 2"))
        XCTAssertTrue(arrangementInterface.contains("struct Arrangement_TestArrangement"))
        XCTAssertTrue(arrangementInterface.contains("struct Machine_Machine1 *fsm_instance1;"))
        XCTAssertTrue(arrangementInterface.contains("struct Machine_Machine1 *fsm_instance2;"))

        // Generate arrangement implementation
        let arrangementCode = cArrangementCode(for: instances, named: "TestArrangement", isSuspensible: true)

        // Verify parts of the generated code
        XCTAssertTrue(arrangementCode.contains("Arrangement_TestArrangement.c"))
        XCTAssertTrue(arrangementCode.contains("void arrangement_testarrangement_init"))
        XCTAssertTrue(arrangementCode.contains("fsm_machine1_init(arrangement->fsm_instance1);"))
        XCTAssertTrue(arrangementCode.contains("fsm_machine1_init(arrangement->fsm_instance2);"))

        // Generate static arrangement code
        let staticCode = cStaticArrangementCode(for: instances, named: "TestArrangement", isSuspensible: true)

        // Verify parts of the generated code
        XCTAssertTrue(staticCode.contains("Static_Arrangement_TestArrangement.c"))
        XCTAssertTrue(staticCode.contains("struct Arrangement_TestArrangement static_arrangement_testarrangement"))
        XCTAssertTrue(staticCode.contains(".fsm_instance1 = &static_fsm_instance1"))
    }

    func testCMakeGeneration() {
        // Create a simple FSM
        let state1 = State(name: "Initial")
        let state2 = State(name: "Final")

        let transition = Transition(label: "finish", source: state1.id, target: state2.id)

        let llfsm = LLFSM(states: [state1, state2],
                         transitions: [transition],
                         suspendState: nil)

        // Generate CMake fragment
        let cmakeFragment = cMakeFragment(for: llfsm, named: "TestMachine", isSuspensible: false)

        // Verify parts of the generated code
        XCTAssertTrue(cmakeFragment.contains("# Sources for the TestMachine LLFSM."))
        XCTAssertTrue(cmakeFragment.contains("set(TestMachine_FSM_SOURCES"))
        XCTAssertTrue(cmakeFragment.contains("Machine_TestMachine.c"))
        XCTAssertTrue(cmakeFragment.contains("State_Initial.c"))
        XCTAssertTrue(cmakeFragment.contains("State_Final.c"))

        // Generate CMake lists with a boilerplate
        let boilerplate = CBoilerplate()
        let cmakeLists = cMakeLists(for: llfsm, named: "TestMachine", boilerplate: boilerplate, isSuspensible: false)

        // Verify parts of the generated code
        XCTAssertTrue(cmakeLists.contains("cmake_minimum_required(VERSION 3.21)"))
        XCTAssertTrue(cmakeLists.contains("project(TestMachine C)"))
        XCTAssertTrue(cmakeLists.contains("add_library(TestMachine_fsm STATIC ${TestMachine_FSM_SOURCES})"))
    }

    func testArrangementCMakeGeneration() {
        // Create a simple arrangement with two instances
        let state1 = State(name: "Initial")
        let state2 = State(name: "Final")

        let transition = Transition(label: "finish", source: state1.id, target: state2.id)

        let llfsm = LLFSM(states: [state1, state2],
                         transitions: [transition],
                         suspendState: nil)

        let machine = Machine()
        machine.llfsm = llfsm
        machine.language = CBinding()

        let instance1 = Instance(name: "instance1", typeFile: "Machine1.machine", machine: machine)
        let instance2 = Instance(name: "instance2", typeFile: "Machine2.machine", machine: machine)

        let instances = [instance1, instance2]

        // Generate CMake fragment for arrangement
        let cmakeFragment = cArrangementCMakeFragment(for: instances, named: "TestArrangement", isSuspensible: true)

        // Verify parts of the generated code
        XCTAssertTrue(cmakeFragment.contains("# Sources for the TestArrangement LLFSM arrangement."))
        XCTAssertTrue(cmakeFragment.contains("set(TestArrangement_ARRANGEMENT_SOURCES"))
        XCTAssertTrue(cmakeFragment.contains("Arrangement_TestArrangement.c"))
        XCTAssertTrue(cmakeFragment.contains("Machine_Common.c"))

        // Verify machine include directories
        XCTAssertTrue(cmakeFragment.contains("$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Machine1.machine>"))
        XCTAssertTrue(cmakeFragment.contains("$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Machine2.machine>"))

        // Generate CMake lists for arrangement
        let cmakeLists = cArrangementCMakeLists(for: instances, named: "TestArrangement", isSuspensible: true)

        // Verify parts of the generated code
        XCTAssertTrue(cmakeLists.contains("cmake_minimum_required(VERSION 3.21)"))
        XCTAssertTrue(cmakeLists.contains("project(TestArrangement C)"))
        XCTAssertTrue(cmakeLists.contains("add_library(TestArrangement_arrangement STATIC ${TestArrangement_ARRANGEMENT_SOURCES})"))
        XCTAssertTrue(cmakeLists.contains("add_executable(run_TestArrangement_arrangement static_main.c)"))
    }
}
