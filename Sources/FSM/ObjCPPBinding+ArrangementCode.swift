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
    namespace FSM {
        class CLMachine;
        class StateMachineVector;
        namespace CLM {
    """ + "\n" + Array(Set(instances.map { $0.typeName })).sorted().map { machine in
        "            class \(machine);"
    }.joined(separator: "\n") + "\n" + """
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

    """ + instances.map { instance in
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
    }.joined(separator: "\n") + """

            };
        };
    };

    #ifdef __cplusplus
    extern "C" {
    #endif

    /// Initialise the \(name) CLFSM arrangement.
    ///
    /// - Parameter arrangement: The machine arrangement to initialise.
    void arrangement_\(lowerName)_init(struct Arrangement_\(name) * const arrangement);

    /// Validate the \(name) CLFSM arrangement.
    ///
    /// - Parameter arrangement: The machine arrangement to validate.
    bool arrangement_\(lowerName)_validate(struct Arrangement_\(name) * const arrangement);

    #ifdef __cplusplus
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
    // Build validate section - check that all machine pointers are valid
    var validateSection = ""
    for (i, instance) in instances.enumerated() {
        let camelCaseName = "fsm" + instance.name.prefix(1).uppercased() + instance.name.dropFirst()
        validateSection += "        arrangement->\(camelCaseName) != nullptr\(i < instances.count - 1 ? " &&\n        " : ";")\n"
    }
    return """
    //
    // Arrangement_\(name).mm
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #include "Arrangement_\(name).h"
    \(includes)
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wunused-macros"

    #ifndef NULL
    #define NULL nullptr
    #endif

    extern "C" {
        /// Initialise the \(name) CLFSM arrangement.
        ///
        /// - Parameter arrangement: The machine arrangement to initialise.
        void arrangement_\(lowerName)_init(struct Arrangement_\(name) * const arrangement)
        {
            arrangement->number_of_instances = ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES;
        }

        /// Validate the \(name) CLFSM arrangement.
        ///
        /// - Parameter arrangement: The machine arrangement to validate.
        bool arrangement_\(lowerName)_validate(struct Arrangement_\(name) * const arrangement)
        {
            return arrangement->number_of_instances == ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES &&
    \(validateSection)        }
    }

    #pragma clang diagnostic pop
    """
}
