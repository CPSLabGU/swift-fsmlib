//
//  ObjCPPBinding+ArrangementCode.swift
//
//  Created by Rene Hexel on 10/05/2025.
//  Copyright © 2012-2019, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Create the Objective-C++ header for an arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement.
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The Objective-C++ arrangement interface code.
public func objcppArrangementHeader(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let upperName = name.uppercased()
    let lowerName = name.lowercased()

    // Build machine class forward declarations
    let machineDeclarations = Array(Set(instances.map { $0.typeName })).sorted().map { machine in
        "            class \(machine);"
    }.joined(separator: "\n")

    // Build struct member declarations
    let memberDeclarations = instances.map { instance in
        let camelCaseName = "fsm" + instance.name.prefix(1).uppercased() + instance.name.dropFirst()
        let snakeCaseName = "fsm_" + instance.name.lowercased()
        return """
    #ifdef __cplusplus
                    /// An instance of the \(instance.typeName) CLFSM.
                    FSM::CLM::\(instance.typeName) *\(camelCaseName);
    #else
                    /// An instance of the \(instance.typeName) CLFSM.
                    void *\(snakeCaseName);
    #endif
    """
    }.joined(separator: "\n")

    // Build getter methods
    let getterMethods = instances.map { instance in
        let camelCaseName = "fsm" + instance.name.prefix(1).uppercased() + instance.name.dropFirst()
        let capitalizedGetter = camelCaseName.prefix(1).uppercased() + camelCaseName.dropFirst()
        return """
                /// Get the \(instance.name) machine instance.
                CLM::\(instance.typeName)* get\(capitalizedGetter)() const { return arrangement_.\(camelCaseName); }
    """
    }.joined(separator: "\n")

    // Build suspensible methods if needed
    let suspensibleMethods = isSuspensible ? """
            /// Suspend all machines in the arrangement.
            void suspend();

            /// Resume all machines in the arrangement.
            void resume();

            /// Restart all machines in the arrangement.
            void restart();

    """ : ""

    // Build suspensible C API if needed
    let suspensibleCAPI = isSuspensible ? """
    /// Suspend all machines in the arrangement.
    ///
    /// - Parameter arrangement: The arrangement to suspend.
    void fsm_arrangement_\(lowerName)_suspend(FSM_Arrangement\(name)* arrangement);

    /// Resume all machines in the arrangement.
    ///
    /// - Parameter arrangement: The arrangement to resume.
    void fsm_arrangement_\(lowerName)_resume(FSM_Arrangement\(name)* arrangement);

    /// Restart all machines in the arrangement.
    ///
    /// - Parameter arrangement: The arrangement to restart.
    void fsm_arrangement_\(lowerName)_restart(FSM_Arrangement\(name)* arrangement);

    """ : ""

    return """
    //
    // Arrangement_\(name).h
    //
    // Automatically created through MiCASE -- do not change manually!
    //
    #ifndef clfsm_arrangement_\(name)_h
    #define clfsm_arrangement_\(name)_h

    #include <inttypes.h>
    #include <stdbool.h>

    #define ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES \(instances.count)

    #ifdef __cplusplus
    #include "StateMachineVector.h"
    namespace FSM {
        class CLMachine;
        namespace CLM {
    \(machineDeclarations)
        }
    }
    #endif

    /// A \(name) CLFSM Arrangement.
    struct Arrangement_\(name)
    {
        /// The number of instances in this arrangement.
        uintptr_t number_of_instances;
        union {
    #ifdef __cplusplus
            /// The machines in this arrangement.
            FSM::CLMachine *machines[\(instances.count)];
    #else
            /// The machines in this arrangement.
            void *machines[\(instances.count)];
    #endif
            struct {

    \(memberDeclarations)

            };
        };
    };

    #ifdef __cplusplus
    namespace FSM {
        /// C++ wrapper class for the \(name) arrangement.
        ///
        /// This class wraps the Arrangement_\(name) struct and provides
        /// RAII lifecycle management and convenient C++ methods.
        class Arrangement\(name) {
        private:
            Arrangement_\(name) arrangement_;
            StateMachineVector vector_;

        public:
            /// Create a new arrangement with dynamically allocated machines.
            Arrangement\(name)();

            /// Destructor - cleans up dynamically allocated machines.
            ~Arrangement\(name)();

            // Prevent copying
            Arrangement\(name)(const Arrangement\(name)&) = delete;
            Arrangement\(name)& operator=(const Arrangement\(name)&) = delete;

    \(getterMethods)

            /// Execute all machines in the arrangement once.
            void executeOnce();

            /// Execute all machines in the arrangement continuously.
            void execute();

    \(suspensibleMethods)
            /// Validate the arrangement.
            ///
            /// - Returns: true if the arrangement is valid, false otherwise.
            bool validate() const;

            /// Get the underlying arrangement struct.
            ///
            /// - Returns: Pointer to the arrangement struct.
            Arrangement_\(name)* getStruct() { return &arrangement_; }

            /// Get the underlying arrangement struct (const).
            ///
            /// - Returns: Pointer to the arrangement struct.
            const Arrangement_\(name)* getStruct() const { return &arrangement_; }
        };
    }

    /// Opaque handle for C code to use the C++ arrangement class.
    typedef struct FSM_Arrangement\(name) FSM_Arrangement\(name);
    #endif

    #ifdef __cplusplus
    extern "C" {
    #endif

    /// Initialise the \(name) CLFSM arrangement struct.
    ///
    /// - Parameter arrangement: The machine arrangement struct to initialise.
    void arrangement_\(lowerName)_init(struct Arrangement_\(name) * const arrangement);

    /// Validate the \(name) CLFSM arrangement struct.
    ///
    /// - Parameter arrangement: The machine arrangement struct to validate.
    /// - Returns: true if valid, false otherwise.
    bool arrangement_\(lowerName)_validate(const struct Arrangement_\(name) * const arrangement);

    #ifdef __cplusplus
    // C API for dynamic allocation using the C++ class

    /// Create a new \(name) arrangement with dynamic allocation.
    ///
    /// - Returns: Opaque handle to the arrangement.
    FSM_Arrangement\(name)* fsm_arrangement_\(lowerName)_create(void);

    /// Destroy a dynamically allocated \(name) arrangement.
    ///
    /// - Parameter arrangement: The arrangement to destroy.
    void fsm_arrangement_\(lowerName)_destroy(FSM_Arrangement\(name)* arrangement);

    /// Execute all machines in the arrangement once.
    ///
    /// - Parameter arrangement: The arrangement to execute.
    void fsm_arrangement_\(lowerName)_execute_once(FSM_Arrangement\(name)* arrangement);

    \(suspensibleCAPI)
    /// Validate a dynamically allocated arrangement.
    ///
    /// - Parameter arrangement: The arrangement to validate.
    /// - Returns: true if valid, false otherwise.
    bool fsm_arrangement_\(lowerName)_validate(const FSM_Arrangement\(name)* arrangement);
    }
    #endif

    #endif // clfsm_arrangement_\(name)_h
    """
}

/// Create the Objective-C++ implementation for an arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement.
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The Objective-C++ arrangement implementation code.
public func objcppArrangementImplementation(for instances: [Instance], named name: String, isSuspensible: Bool) -> Code {
    let upperName = name.uppercased()
    let lowerName = name.lowercased()
    let machineTypes = Array(Set(instances.map { $0.typeName }))
    var includes = ""
    for machine in machineTypes {
        includes += "#include \"\(machine).machine/\(machine).h\"\n"
    }
    // Build validate section for C struct function - check that all machine pointers are valid
    var validateSectionCStruct = ""
    for (i, instance) in instances.enumerated() {
        let camelCaseName = "fsm" + instance.name.prefix(1).uppercased() + instance.name.dropFirst()
        validateSectionCStruct += "        arrangement->\(camelCaseName) != nullptr\(i < instances.count - 1 ? " &&\n        " : ";")\n"
    }

    // Build validate section for C++ class - check that all machine pointers are valid
    var validateSectionCppClass = ""
    for (i, instance) in instances.enumerated() {
        let camelCaseName = "fsm" + instance.name.prefix(1).uppercased() + instance.name.dropFirst()
        validateSectionCppClass += "        arrangement_.\(camelCaseName) != nullptr\(i < instances.count - 1 ? " &&\n        " : ";")\n"
    }

    // Build constructor initialization - create machines dynamically
    var constructorInit = ""
    for (i, instance) in instances.enumerated() {
        let camelCaseName = "fsm" + instance.name.prefix(1).uppercased() + instance.name.dropFirst()
        constructorInit += "        arrangement_.\(camelCaseName) = new CLM::\(instance.typeName)(\(i), \"\(instance.name)\");\n"
        constructorInit += "        arrangement_.machines[\(i)] = arrangement_.\(camelCaseName);\n"
    }

    // Build destructor cleanup - delete machines
    var destructorCleanup = ""
    for instance in instances {
        let camelCaseName = "fsm" + instance.name.prefix(1).uppercased() + instance.name.dropFirst()
        destructorCleanup += "        delete arrangement_.\(camelCaseName);\n"
    }

    return """
    //
    // Arrangement_\(name).mm
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #include "Arrangement_\(name).h"
    #include "StateMachineVector.h"
    #include "CLMacros.h"
    \(includes)
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wunused-macros"

    #ifndef NULL
    #define NULL nullptr
    #endif

    namespace FSM {
        // C++ class implementation

        Arrangement\(name)::Arrangement\(name)()
            : vector_(nullptr, 0)
        {
            arrangement_.number_of_instances = ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES;
    \(constructorInit)        // Initialize execution engine with machine array
            vector_ = StateMachineVector(arrangement_.machines, ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES);
        }

        Arrangement\(name)::~Arrangement\(name)() {
    \(destructorCleanup)    }

        void Arrangement\(name)::executeOnce() {
            set_global_machine_vector(&vector_);
            vector_.executeOnce();
        }

        void Arrangement\(name)::execute() {
            while (true) {
                executeOnce();
            }
        }

    """ + (isSuspensible ? """
        void Arrangement\(name)::suspend() {
            set_global_machine_vector(&vector_);
            for (uintptr_t i = 0; i < arrangement_.number_of_instances; ++i) {
                control_machine_at_index(static_cast<int>(i), CLSuspend);
            }
        }

        void Arrangement\(name)::resume() {
            set_global_machine_vector(&vector_);
            for (uintptr_t i = 0; i < arrangement_.number_of_instances; ++i) {
                control_machine_at_index(static_cast<int>(i), CLResume);
            }
        }

        void Arrangement\(name)::restart() {
            set_global_machine_vector(&vector_);
            for (uintptr_t i = 0; i < arrangement_.number_of_instances; ++i) {
                control_machine_at_index(static_cast<int>(i), CLRestart);
            }
        }

    """ : "") + """
        bool Arrangement\(name)::validate() const {
            return arrangement_.number_of_instances == ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES &&
    \(validateSectionCppClass)        }
    }

    extern "C" {
        /// Initialise the \(name) CLFSM arrangement struct.
        ///
        /// - Parameter arrangement: The machine arrangement struct to initialise.
        void arrangement_\(lowerName)_init(struct Arrangement_\(name) * const arrangement)
        {
            arrangement->number_of_instances = ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES;
        }

        /// Validate the \(name) CLFSM arrangement struct.
        ///
        /// - Parameter arrangement: The machine arrangement struct to validate.
        bool arrangement_\(lowerName)_validate(const struct Arrangement_\(name) * const arrangement)
        {
            return arrangement->number_of_instances == ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES &&
    \(validateSectionCStruct)        }

        // C wrapper functions for dynamic allocation using C++ class

        FSM_Arrangement\(name)* fsm_arrangement_\(lowerName)_create(void) {
            return reinterpret_cast<FSM_Arrangement\(name)*>(new FSM::Arrangement\(name)());
        }

        void fsm_arrangement_\(lowerName)_destroy(FSM_Arrangement\(name)* arrangement) {
            delete reinterpret_cast<FSM::Arrangement\(name)*>(arrangement);
        }

        void fsm_arrangement_\(lowerName)_execute_once(FSM_Arrangement\(name)* arrangement) {
            reinterpret_cast<FSM::Arrangement\(name)*>(arrangement)->executeOnce();
        }

    """ + (isSuspensible ? """
        void fsm_arrangement_\(lowerName)_suspend(FSM_Arrangement\(name)* arrangement) {
            reinterpret_cast<FSM::Arrangement\(name)*>(arrangement)->suspend();
        }

        void fsm_arrangement_\(lowerName)_resume(FSM_Arrangement\(name)* arrangement) {
            reinterpret_cast<FSM::Arrangement\(name)*>(arrangement)->resume();
        }

        void fsm_arrangement_\(lowerName)_restart(FSM_Arrangement\(name)* arrangement) {
            reinterpret_cast<FSM::Arrangement\(name)*>(arrangement)->restart();
        }

    """ : "") + """
        bool fsm_arrangement_\(lowerName)_validate(const FSM_Arrangement\(name)* arrangement) {
            return reinterpret_cast<const FSM::Arrangement\(name)*>(arrangement)->validate();
        }
    }

    #pragma clang diagnostic pop
    """
}
