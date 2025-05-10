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

    struct CLMachine;
    struct CLFSMArrangement;

    /// A \(name) CLFSM Arrangement.
    struct Arrangement_\(name)
    {
        /// The number of instances in this arrangement.
        uintptr_t number_of_instances;
        union {
            /// The machines in this arrangement.
            struct CLMachine *machines[\(instances.count)];
            struct {
    """ + instances.map { instance in
        "                /// An instance of the \(instance.typeName) CLFSM.\n                struct \(instance.typeName) *fsm_\(instance.name.lowercased());"
    }.joined(separator: "\n") + """
            };
        };
    };

    /// Initialise the \(name) CLFSM arrangement.
    ///
    /// - Parameter arrangement: The machine arrangement to initialise.
    void arrangement_\(lowerName)_init(struct Arrangement_\(name) * const arrangement);

    /// Validate the \(name) CLFSM arrangement.
    ///
    /// - Parameter arrangement: The machine arrangement to validate.
    bool arrangement_\(lowerName)_validate(struct Arrangement_\(name) * const arrangement);

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
    var initSection = ""
    for instance in instances {
        initSection += "    fsm_\(instance.typeName.lowercased())_init(arrangement->fsm_\(instance.name.lowercased()));\n"
    }
    var validateSection = ""
    for (i, instance) in instances.enumerated() {
        validateSection += "    fsm_\(instance.typeName.lowercased())_validate(arrangement->fsm_\(instance.name.lowercased()))\(i < instances.count - 1 ? " &&" : ";")\n"
    }
    return """
    //
    // Arrangement_\(name).mm
    //
    // Automatically created through MiCASE -- do not change manually!
    //
    #include "Arrangement_\(name).h"
    \(includes)
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wunused-macros"

    #ifndef NULL
    #define NULL ((void*)0)
    #endif

    /// Initialise the \(name) CLFSM arrangement.
    ///
    /// - Parameter arrangement: The machine arrangement to initialise.
    void arrangement_\(lowerName)_init(struct Arrangement_\(name) * const arrangement)
    {
        arrangement->number_of_instances = ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES;
    \(initSection)}

    /// Validate the \(name) CLFSM arrangement.
    ///
    /// - Parameter arrangement: The machine arrangement to validate.
    bool arrangement_\(lowerName)_validate(struct Arrangement_\(name) * const arrangement)
    {
        return arrangement->number_of_instances == ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES &&
    \(validateSection)}
    """
}
