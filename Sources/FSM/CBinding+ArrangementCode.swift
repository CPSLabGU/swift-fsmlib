//
//  CBinding+ArrangementCode.swift
//
//  Created by Rene Hexel on 19/8/2023.
//
/// Return the interface for a C-language LLFSM arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The LLFSM arrangement interface code.
public func cArrangementInterface(for instances: [Instance], named name: String, isSuspensible: Bool) -> String {
    let upperName = name.uppercased()
    return """
    //
    // Arrangement_\(name).h
    //
    // Automatically created using fsmconvert -- do not change manually!
    //

    """ + .includeFile(named: "LLFSM_ARRANGEMENT_" + upperName + "_H") {
        "#include <stdbool.h>"
        ""
        "#define ARRANGEMENT_\(upperName)_NUMBER_OF_INSTANCES \(instances.count)"
        ""
        "struct LLFSMachine;"
        ""
        "/// A \(name) LLFSM Arrangement."
        "struct Arrangement_" + name
        Code.bracedBlock {
            "union"
            Code.bracedBlock {
                "struct LLFSMachine *machines[\(instances.count)];"
                "struct"
                Code.bracedBlock {
                    Code.forEach(instances) { instance in
                        "struct Machine_\(instance.url.deletingPathExtension().lastPathComponent) *\(instance.name);"
                    }
                } + ";"
            } + ";"
        } + ";"
        ""
        "/// Initialise the \(name) LLFSM arrangement."
        "///"
        "/// - Parameter arrangement: The machine arrangement to initialise."
        "void arrangement_" + name + "_init(struct Arrangement_" + name + " * const arrangement);"
    }
}

/// Return the implementation for a C-language LLFSM arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The LLFSM arrangement implementation code.
public func cArrangementCode(for instances: [Instance], named name: String, isSuspensible: Bool) -> String {
    """
    //
    // Arrangement_\(name).c
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #include \"Arrangement_\(name).h\"
    #ifndef NULL
    #define NULL ((void*)0)
    #endif

    """ + .block {
        ""
        "/// Initialise the \(name) LLFSM arrangement."
        "///"
        "/// - Parameter arrangement: The machine arrangement to initialise."
        "void arrangement_" + name + "_init(struct Arrangement_" + name + " * const arrangement)"
        Code.bracedBlock {
        }
        ""
        "/// Run a ringlet of the \(name) LLFSM arrangement."
        "///"
        "/// - Parameter arrangement: The machine arrangement to initialise."
        "void arrangement_" + name + "_execute_once(struct Arrangement_" + name + " * const arrangement)"
        Code.bracedBlock {
            Code.forEach(instances) { instance in
                "struct Machine_\(instance.url.deletingPathExtension().lastPathComponent) *\(instance.name);"
            }
        }
    }
}

/// Return the implementation for a C-language LLFSM arrangement.
///
/// - Parameters:
///   - instances: The instances to arrange.
///   - name: The name of the arrangement
///   - isSuspensible: Indicates whether code for suspensible machines should be generated.
/// - Returns: The LLFSM arrangement implementation code.
public func cArrangementMachineCode(for instances: [Instance], named name: String, isSuspensible: Bool) -> String {
    """
    //
    // Machine_Common.c
    //
    // Automatically created using fsmconvert -- do not change manually!
    //
    #include \"Machine_Common.h\"
    #ifndef NULL
    #define NULL ((void*)0)
    #endif

    """ + .block {
        ""
        "/// Run a ringlet of a C-language LLFSM."
        "///"
        "/// - Parameter machine: The machine arrangement to initialise."
        "void llfsm_execute_once(struct LLFSMArrangement * const arrangement, struct LLFSMachine * const machine)"
        Code.bracedBlock {
        }
    }
}
