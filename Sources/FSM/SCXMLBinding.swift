//
//  SCXMLBinding.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// SCXML language binding for reading and writing SCXML documents.
///
/// This binding provides I/O operations for SCXML format while maintaining
/// compatibility with the existing FSM architecture. SCXML uses single-file
/// XML format and works with `SingleFileMachineWrapper` for storage.
///
/// ## Storage Format
///
/// SCXML documents are stored as single `.scxml` XML files, not directory structures.
/// The binding uses `SingleFileMachineWrapper` to maintain API compatibility with
/// directory-based formats while optimizing for single-file storage.
///
/// ## Supported Features
///
/// - Standard SCXML 1.0 elements (states, transitions, datamodel, etc.)
/// - Multi-namespace support (fsm:, qt:, se:) for tool interoperability
/// - Embedded C/C++ boilerplate preservation for round-trip conversion
/// - Layout metadata for visual editors (ScxmlEditor, Qt Creator)
public struct SCXMLBinding: OutputLanguage {
    /// Canonical name of the binding
    public let name: String = "scxml"

    /// Default initializer
    public init() {}

    // MARK: - Direct SCXML File I/O

    /// Read SCXML file and convert to Machine
    ///
    /// - Parameter url: URL to SCXML file
    /// - Returns: Parsed Machine object
    /// - Throws: SCXMLParserError if parsing fails
    public func read(from url: URL) throws -> Machine {
        let parser = SCXMLParser()
        return try parser.parse(contentsOf: url)
    }

    /// Read SCXML from data and convert to Machine
    ///
    /// - Parameter data: SCXML XML data
    /// - Returns: Parsed Machine object
    /// - Throws: SCXMLParserError if parsing fails
    public func read(from data: Data) throws -> Machine {
        let parser = SCXMLParser()
        return try parser.parse(data)
    }

    /// Write Machine to SCXML file
    ///
    /// - Parameters:
    ///   - machine: Machine to write
    ///   - url: URL to write SCXML file to
    /// - Throws: Error if writing fails
    public func write(_ machine: Machine, to url: URL) throws {
        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)
        try xml.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Generate SCXML string from Machine
    ///
    /// - Parameter machine: Machine to convert
    /// - Returns: SCXML XML string
    /// - Throws: Error if generation fails
    public func generateXML(from machine: Machine) throws -> String {
        let writer = SCXMLWriter()
        return try writer.generate(from: machine)
    }

    // MARK: - LanguageBinding Protocol

    /// Return the number of transitions for the given state.
    public func numberOfTransitions(for machineWrapper: MachineWrapper, stateName: StateName) -> Int {
        guard let data = scxmlData(from: machineWrapper),
              let machine = try? read(from: data),
              let state = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == stateName })
        else {
            return 0
        }
        return machine.llfsm.transitionsFrom(state).count
    }

    /// Return the expression of the given transition.
    public func expression(of transitionNumber: Int, for machineWrapper: MachineWrapper, stateName: StateName) -> String {
        guard let data = scxmlData(from: machineWrapper),
              let machine = try? read(from: data),
              let state = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == stateName }),
              let scxmlBoilerplate = machine.boilerplate as? SCXMLBoilerplate
        else {
            return ""
        }

        let transitionIDs = machine.llfsm.transitionsFrom(state)
        guard transitionNumber < transitionIDs.count,
              let transition = machine.llfsm.transitionMap[transitionIDs[transitionNumber]]
        else {
            return ""
        }

        if let metadata = scxmlBoilerplate.transitionMetadata[transition.id],
           let condition = metadata.condition {
            return condition
        }
        return transition.label
    }

    /// Return the target state ID of the given transition.
    public func target(of transitionNumber: Int, for machineWrapper: MachineWrapper, stateName: StateName, with states: [State]) -> StateID? {
        guard let data = scxmlData(from: machineWrapper),
              let machine = try? read(from: data),
              let state = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == stateName })
        else {
            return nil
        }

        let transitionIDs = machine.llfsm.transitionsFrom(state)
        guard transitionNumber < transitionIDs.count,
              let transition = machine.llfsm.transitionMap[transitionIDs[transitionNumber]]
        else {
            return nil
        }

        return transition.target
    }

    /// Return the suspend state ID for the given machine.
    public func suspendState(for machineWrapper: MachineWrapper, states: [State]) -> StateID? {
        // SCXML doesn't have a built-in suspend state concept
        return nil
    }

    /// Return the boilerplate for the given machine.
    public func boilerplate(for machineWrapper: MachineWrapper) -> any Boilerplate {
        guard let data = scxmlData(from: machineWrapper),
              let machine = try? read(from: data)
        else {
            return SCXMLBoilerplate()
        }
        return machine.boilerplate
    }

    /// Return the boilerplate for the given state.
    public func stateBoilerplate(for machineWrapper: MachineWrapper, stateName: StateName) -> any Boilerplate {
        // For SCXML, state boilerplate is stored in the machine's stateBoilerplate map
        // Try to get it from the wrapper's machine first
        if let stateID = machineWrapper.machine.llfsm.states.first(where: {
            machineWrapper.machine.llfsm.stateName(for: $0) == stateName
        }) {
            if let boilerplate = machineWrapper.machine.stateBoilerplate[stateID] {
                return boilerplate
            }
        }

        // Fallback: try to parse from SCXML data in wrapper
        if let data = scxmlData(from: machineWrapper),
           let machine = try? read(from: data),
           let stateID = machine.llfsm.states.first(where: { machine.llfsm.stateName(for: $0) == stateName }),
           let boilerplate = machine.stateBoilerplate[stateID] {
            return boilerplate
        }

        // Last resort: return empty boilerplate
        return SCXMLBoilerplate()
    }

    // MARK: - OutputLanguage Protocol

    /// Create a file wrapper at the given URL.
    public func createWrapper(at url: URL, for machine: Machine?) throws -> MachineWrapper {
        // For SCXML, we create a SingleFileMachineWrapper
        // But the protocol requires MachineWrapper return type
        // So we need to work around this...

        // Actually, since single files aren't directories, we can't use MachineWrapper
        // We need to return a compatibility wrapper
        // For now, create an empty directory wrapper that will be populated with SCXML
        let machine = machine ?? Machine()
        let wrapper = MachineWrapper(directoryWithFileWrappers: [:], for: machine, named: url.lastPathComponent)
        return wrapper
    }

    /// Create an arrangement wrapper at the given URL.
    public func createArrangementWrapper(at url: URL) throws -> ArrangementWrapper {
        throw FSMError.unsupportedOutputFormat
    }

    /// Add language information to the wrapper.
    public func addLanguage(to wrapper: FileWrapper) throws {
        // For SCXML in directory wrapper, add a Language file
        let languageData = "scxml\n".data(using: .utf8)!
        let languageWrapper = FileWrapper(regularFileWithContents: languageData)
        languageWrapper.preferredFilename = "Language"
        wrapper.addFileWrapper(languageWrapper)
    }

    /// Add layout information.
    public func add(layout: StateNameLayouts, to wrapper: MachineWrapper) throws {
        // Layout is embedded in SCXML XML, not separate file
        // This will be handled during XML generation
    }

    /// Add window layout.
    public func add(windowLayout: Data?, to wrapper: MachineWrapper) throws {
        // Window layout not used in SCXML
    }

    /// Add state names.
    public func add(stateNames: StateNames, to wrapper: MachineWrapper) throws {
        // State names are embedded in SCXML XML
    }

    /// Add machine boilerplate.
    public func add(boilerplate: any Boilerplate, to wrapper: MachineWrapper) throws {
        // Boilerplate is embedded in SCXML XML
    }

    /// Add state boilerplate.
    public func add(stateBoilerplate: any Boilerplate, to wrapper: MachineWrapper, for stateName: String) throws {
        // State boilerplate is embedded in SCXML XML
    }

    /// Add machine interface.
    public func addInterface(for llfsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws {
        // SCXML doesn't generate separate interface files
    }

    /// Add state interface.
    public func addStateInterface(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws {
        // SCXML doesn't generate separate state interface files
    }

    /// Add arrangement interface.
    public func addArrangementInterface(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        throw FSMError.unsupportedOutputFormat
    }

    /// Add machine code.
    public func addCode(for llfsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws {
        // Generate SCXML and add to wrapper
        let machine = wrapper.machine
        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)
        let xmlData = xml.data(using: .utf8)!

        let scxmlWrapper = FileWrapper(regularFileWithContents: xmlData)
        scxmlWrapper.preferredFilename = "document.scxml"
        wrapper.addFileWrapper(scxmlWrapper)
    }

    /// Add state code.
    public func addStateCode(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws {
        // State code is embedded in SCXML XML
    }

    /// Add transition code.
    public func addTransitionCode(for fsm: LLFSM, to wrapper: MachineWrapper, isSuspensible: Bool) throws {
        // Transition code is embedded in SCXML XML
    }

    /// Add arrangement code.
    public func addArrangementCode(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        throw FSMError.unsupportedOutputFormat
    }

    /// Add CMake file.
    public func addCMakeFile(for llfsm: LLFSM, boilerplate: any Boilerplate, to wrapper: MachineWrapper, isSuspensible: Bool) throws {
        // SCXML doesn't generate CMake files
    }

    /// Add arrangement CMake file.
    public func addArrangementCMakeFile(for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool) throws {
        throw FSMError.unsupportedOutputFormat
    }

    // MARK: - Section-Based Boilerplate Access

    /// Extract sections from SCXMLBoilerplate.
    ///
    /// All sections (both standard SCXML and extensions) are stored in genericSections.
    ///
    /// - Parameter boilerplate: The boilerplate to extract sections from.
    /// - Returns: Dictionary mapping section names to their content.
    public func extractSections(from boilerplate: any Boilerplate) -> [StandardBoilerplateSection: String] {
        guard let scxmlBoilerplate = boilerplate as? SCXMLBoilerplate else {
            return [:]
        }
        return scxmlBoilerplate.genericSections ?? [:]
    }

    /// Extract sections from state boilerplate.
    ///
    /// For SCXML, state boilerplate is also stored as SCXMLBoilerplate with genericSections.
    ///
    /// - Parameters:
    ///   - boilerplate: The state boilerplate to extract sections from.
    ///   - stateName: The name of the state.
    /// - Returns: Dictionary mapping section names to their content.
    public func extractStateSections(
        from boilerplate: any Boilerplate,
        stateName: StateName
    ) -> [StandardBoilerplateSection: String] {
        return extractSections(from: boilerplate)
    }

    /// Create SCXMLBoilerplate for machine boilerplate.
    public func createBoilerplate(from sections: [StandardBoilerplateSection: String]) -> any Boilerplate {
        var scxmlBoilerplate = SCXMLBoilerplate()
        scxmlBoilerplate.genericSections = sections
        return scxmlBoilerplate
    }

    /// Create SCXMLBoilerplate for state boilerplate.
    ///
    /// States also use SCXMLBoilerplate with genericSections to avoid CBoilerplate dependency.
    public func createStateBoilerplate(
        from sections: [StandardBoilerplateSection: String],
        stateName: StateName
    ) -> any Boilerplate {
        var scxmlBoilerplate = SCXMLBoilerplate()
        scxmlBoilerplate.genericSections = sections
        return scxmlBoilerplate
    }

    // MARK: - Helper Methods

    /// Extract SCXML data from MachineWrapper.
    private func scxmlData(from wrapper: MachineWrapper) -> Data? {
        // Try "document.scxml" first
        if let data = wrapper.fileWrappers?["document.scxml"]?.regularFileContents {
            return data
        }

        // Try to find any .scxml file
        if let fileWrappers = wrapper.fileWrappers {
            for (filename, fileWrapper) in fileWrappers {
                if filename.hasSuffix(".scxml"), let data = fileWrapper.regularFileContents {
                    return data
                }
            }
        }

        return nil
    }
}
