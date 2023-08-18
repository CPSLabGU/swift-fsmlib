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
                "struct LLFSMachine *instances[\(instances.count)];"
                "struct"
                Code.bracedBlock {
                    Code.forEach(instances) { instance in
                        "struct Machine_\(instance.url.deletingPathExtension().lastPathComponent) *\(instance.name);"
                    }
                } + ";"
            } + ";"
        } + ";"
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
    }
}
