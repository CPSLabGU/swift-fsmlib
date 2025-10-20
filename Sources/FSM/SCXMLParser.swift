//
//  SCXMLParser.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

/// SCXML parsing errors.
public enum SCXMLParserError: Error, CustomStringConvertible {
    case invalidXML(String)
    case missingRequiredAttribute(element: String, attribute: String)
    case invalidStateReference(String)
    case invalidTransitionTarget(String)
    case circularStateHierarchy(String)
    case duplicateStateID(String)
    case unsupportedDatamodel(String)
    case parsingFailed(String)

    public var description: String {
        switch self {
        case .invalidXML(let msg): return "Invalid XML: \(msg)"
        case .missingRequiredAttribute(let elem, let attr):
            return "Missing required attribute '\(attr)' on element '\(elem)'"
        case .invalidStateReference(let ref): return "Invalid state reference: \(ref)"
        case .invalidTransitionTarget(let target): return "Invalid transition target: \(target)"
        case .circularStateHierarchy(let state):
            return "Circular state hierarchy detected: \(state)"
        case .duplicateStateID(let id): return "Duplicate state ID: \(id)"
        case .unsupportedDatamodel(let dm): return "Unsupported datamodel: \(dm)"
        case .parsingFailed(let msg): return "Parsing failed: \(msg)"
        }
    }
}

/// SCXML parser for converting SCXML XML documents to Machine objects.
///
/// This class handles parsing of SCXML 1.0 documents, supporting:
/// - Basic states and transitions
/// - Compound and parallel states
/// - History states (shallow/deep)
/// - Final states
/// - Data models
/// - Executable content (onentry/onexit/script/assign/send/raise)
/// - Layout preservation from visual editors
public final class SCXMLParser: NSObject {
    // MARK: - Parsing State

    private var xmlDoc: XMLDocument?
    private var stateMap: [String: StateID] = [:]
    private var states: [State] = []
    private var transitions: [Transition] = []
    private var stateMetadata: SCXMLStateMetadataMap = [:]
    private var transitionMetadata: SCXMLTransitionMetadataMap = [:]
    private var boilerplate: SCXMLBoilerplate = SCXMLBoilerplate()
    private var stateBoilerplate: [StateID: any Boilerplate] = [:]
    private var stateLayouts: StateLayouts = [:]
    private var transitionLayouts: TransitionLayouts = [:]

    // MARK: - Parsing

    /// Parse SCXML data into a Machine object.
    ///
    /// - Parameter data: SCXML XML data
    /// - Returns: Parsed Machine object
    /// - Throws: SCXMLParserError on parsing failure
    public func parse(_ data: Data) throws -> Machine {
        // Reset state
        reset()

        // Parse XML
        do {
            xmlDoc = try XMLDocument(data: data, options: [])
        } catch {
            throw SCXMLParserError.invalidXML(error.localizedDescription)
        }

        guard let root = xmlDoc?.rootElement(), root.name == "scxml" else {
            throw SCXMLParserError.invalidXML("Root element must be <scxml>")
        }

        // Parse scxml attributes
        try parseScxmlAttributes(root)

        // Parse FSMLib boilerplate (fsm: namespace)
        parseFSMLibBoilerplate(root)

        // Parse datamodel
        if let datamodelElem = root.elements(forName: "datamodel").first {
            try parseDatamodel(datamodelElem)
        }

        // Parse initial script
        if let scriptElem = root.elements(forName: "script").first {
            boilerplate.initialScript = scriptElem.stringValue
        }

        // Parse states (recursive)
        try parseStates(root, parent: nil)

        // Determine initial state
        _ = try determineInitialState(root)

        // Parse transitions
        try parseTransitions()

        // Build LLFSM
        let llfsm = LLFSM(
            states: states,
            transitions: transitions,
            suspendState: nil
        )

        // Store metadata in boilerplate
        boilerplate.stateMetadata = stateMetadata
        boilerplate.transitionMetadata = transitionMetadata

        // Create Machine
        let machine = Machine()
        machine.language = SCXMLBinding()
        machine.llfsm = llfsm
        machine.boilerplate = boilerplate
        machine.stateBoilerplate = stateBoilerplate
        machine.stateLayout = stateLayouts
        machine.transitionLayout = transitionLayouts

        return machine
    }

    /// Parse SCXML from file URL.
    ///
    /// - Parameter url: File URL to SCXML document
    /// - Returns: Parsed Machine object
    /// - Throws: SCXMLParserError on parsing failure
    public func parse(contentsOf url: URL) throws -> Machine {
        let data = try Data(contentsOf: url)
        return try parse(data)
    }

    // MARK: - Private Parsing Methods

    private func reset() {
        xmlDoc = nil
        stateMap = [:]
        states = []
        transitions = []
        stateMetadata = [:]
        transitionMetadata = [:]
        boilerplate = SCXMLBoilerplate()
        stateBoilerplate = [:]
        stateLayouts = [:]
        transitionLayouts = [:]
    }

    private func parseScxmlAttributes(_ element: XMLElement) throws {
        // Version (required)
        guard let version = element.attributeValue(forName: "version") else {
            throw SCXMLParserError.missingRequiredAttribute(element: "scxml", attribute: "version")
        }
        boilerplate.scxmlVersion = version

        // Name (optional)
        boilerplate.name = element.attributeValue(forName: "name")

        // Datamodel (optional, defaults to "null")
        boilerplate.datamodel = element.attributeValue(forName: "datamodel") ?? "null"

        // Binding (optional, defaults to "early")
        boilerplate.binding = element.attributeValue(forName: "binding") ?? "early"

        // FSMLib language attribute (fsm:language)
        boilerplate.targetLanguage = element.attributeValue(forName: "fsm:language")
    }

    private func parseFSMLibBoilerplate(_ root: XMLElement) {

        // Look for fsm:boilerplate element
        for child in root.children ?? [] {
            guard let elem = child as? XMLElement,
                  elem.name == "fsm:boilerplate" || elem.name == "boilerplate"
            else {
                continue
            }


            // Parse generic fsm:section elements
            // IMPORTANT: Preserve empty sections for round-trip fidelity
            var genericSections: [StandardBoilerplateSection: String] = [:]

            let fsmSections = elem.elements(forName: "fsm:section")

            for sectionElem in fsmSections {
                guard let sectionName = sectionElem.attributeValue(forName: "name"),
                      let section = StandardBoilerplateSection(rawValue: sectionName) else {
                    continue
                }
                // Preserve empty content (don't filter out empty strings)
                let content = sectionElem.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                genericSections[section] = content
            }

            // Also support old format for backwards compatibility
            // IMPORTANT: Preserve empty sections
            // Parse fsm:includePath (legacy)
            if let includePathElem = elem.elements(forName: "fsm:includePath").first ?? elem.elements(forName: "includePath").first {
                let content = includePathElem.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                genericSections[.includePath] = content
            }

            // Parse fsm:includes (legacy)
            if let includesElem = elem.elements(forName: "fsm:includes").first ?? elem.elements(forName: "includes").first {
                let content = includesElem.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                genericSections[.includes] = content
            }

            // Parse fsm:variables (legacy)
            if let variablesElem = elem.elements(forName: "fsm:variables").first ?? elem.elements(forName: "variables").first {
                let content = variablesElem.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                genericSections[.variables] = content
            }

            // Parse fsm:functions (legacy)
            if let functionsElem = elem.elements(forName: "fsm:functions").first ?? elem.elements(forName: "functions").first {
                let content = functionsElem.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                genericSections[.functions] = content
            }

            if !genericSections.isEmpty {
                boilerplate.genericSections = genericSections
            }
            break
        }
    }

    private func parseDatamodel(_ element: XMLElement) throws {
        for dataElem in element.elements(forName: "data") {
            guard let id = dataElem.attributeValue(forName: "id") else {
                throw SCXMLParserError.missingRequiredAttribute(element: "data", attribute: "id")
            }

            let expr = dataElem.attributeValue(forName: "expr")
            let src = dataElem.attributeValue(forName: "src")
            let content = dataElem.stringValue

            let declaration = DataDeclaration(
                id: id,
                expr: expr,
                src: src,
                content: content?.isEmpty == false ? content : nil
            )
            boilerplate.dataDeclarations.append(declaration)
        }
    }

    private func parseStates(_ parent: XMLElement, parent parentStateID: StateID?) throws {
        // Parse <state> elements
        for stateElem in parent.elements(forName: "state") {
            try parseState(stateElem, parent: parentStateID, isParallel: false, isFinal: false)
        }

        // Parse <parallel> elements
        for parallelElem in parent.elements(forName: "parallel") {
            try parseState(parallelElem, parent: parentStateID, isParallel: true, isFinal: false)
        }

        // Parse <final> elements
        for finalElem in parent.elements(forName: "final") {
            try parseState(finalElem, parent: parentStateID, isParallel: false, isFinal: true)
        }

        // Parse <history> elements
        for historyElem in parent.elements(forName: "history") {
            try parseHistoryState(historyElem, parent: parentStateID)
        }
    }

    private func parseState(
        _ element: XMLElement, parent parentStateID: StateID?, isParallel: Bool, isFinal: Bool
    ) throws {
        guard let stateIDString = element.attributeValue(forName: "id") else {
            throw SCXMLParserError.missingRequiredAttribute(
                element: element.name ?? "state", attribute: "id")
        }

        // Check for duplicate
        if stateMap[stateIDString] != nil {
            throw SCXMLParserError.duplicateStateID(stateIDString)
        }

        // Create state
        let stateID = StateID()
        let state = State(id: stateID, name: stateIDString)
        states.append(state)
        stateMap[stateIDString] = stateID

        // Create metadata
        var metadata = SCXMLStateMetadata()
        metadata.parentState = parentStateID
        metadata.isParallel = isParallel
        metadata.isFinal = isFinal

        // Parse initial attribute
        if element.attributeValue(forName: "initial") != nil {
            // Will resolve after all states parsed
            metadata.initialChild = nil  // Placeholder
        }

        // Parse child states
        let childElements =
            element.elements(forName: "state") + element.elements(forName: "parallel")
            + element.elements(forName: "final") + element.elements(forName: "history")
        if !childElements.isEmpty {
            metadata.childStates = []
            try parseStates(element, parent: stateID)
        }

        // Parse onentry/onexit
        try parseStateActions(element, stateID: stateID)

        // Parse layout metadata (custom attributes)
        parseLayoutMetadata(element, stateID: stateID)

        // Store metadata
        stateMetadata[stateID] = metadata

        // Parse invokes
        parseInvokes(element, stateID: stateID)
    }

    private func parseHistoryState(_ element: XMLElement, parent parentStateID: StateID?) throws {
        guard let historyID = element.attributeValue(forName: "id") else {
            throw SCXMLParserError.missingRequiredAttribute(element: "history", attribute: "id")
        }

        let historyType: HistoryType =
            element.attributeValue(forName: "type") == "deep" ? .deep : .shallow

        let stateID = StateID()
        let state = State(id: stateID, name: historyID)
        states.append(state)
        stateMap[historyID] = stateID

        var metadata = SCXMLStateMetadata()
        metadata.parentState = parentStateID
        metadata.historyType = historyType

        // Parse default transition
        if let transitionElem = element.elements(forName: "transition").first,
            transitionElem.attributeValue(forName: "target") != nil
        {
            // Will resolve after all states parsed
        }

        stateMetadata[stateID] = metadata
    }

    private func parseStateActions(_ element: XMLElement, stateID: StateID) throws {
        // Store state activities in SCXMLBoilerplate with genericSections
        var genericSections: [StandardBoilerplateSection: String] = [:]

        // Parse onentry (standard SCXML)
        let onentryElems = element.elements(forName: "onentry")
        if !onentryElems.isEmpty {
            var onEntryCode = ""
            for onentryElem in onentryElems {
                let actions = try parseExecutableContent(onentryElem)
                onEntryCode += executableActionsToCode(actions)
            }
            genericSections[.onEntry] = onEntryCode
        }

        // Parse onexit (standard SCXML)
        let onexitElems = element.elements(forName: "onexit")
        if !onexitElems.isEmpty {
            var onExitCode = ""
            for onexitElem in onexitElems {
                let actions = try parseExecutableContent(onexitElem)
                onExitCode += executableActionsToCode(actions)
            }
            genericSections[.onExit] = onExitCode
        }

        // Parse generic FSMLib extension sections (new format)
        for sectionElem in element.elements(forName: "fsm:section") {
            guard let sectionName = sectionElem.attributeValue(forName: "name"),
                  let section = StandardBoilerplateSection(rawValue: sectionName),
                  let content = sectionElem.stringValue else {
                continue
            }
            genericSections[section] = content
        }

        // Parse FSMLib extensions (legacy format for backwards compatibility)
        let internalElems = element.elements(forName: "fsm:internal")
        if !internalElems.isEmpty {
            var internalCode = ""
            for internalElem in internalElems {
                if let code = internalElem.stringValue {
                    internalCode += code
                }
            }
            genericSections[.internal] = internalCode
        }

        let suspendElems = element.elements(forName: "fsm:onSuspend")
        if !suspendElems.isEmpty {
            var onSuspendCode = ""
            for suspendElem in suspendElems {
                if let code = suspendElem.stringValue {
                    onSuspendCode += code
                }
            }
            genericSections[.onSuspend] = onSuspendCode
        }

        let resumeElems = element.elements(forName: "fsm:onResume")
        if !resumeElems.isEmpty {
            var onResumeCode = ""
            for resumeElem in resumeElems {
                if let code = resumeElem.stringValue {
                    onResumeCode += code
                }
            }
            genericSections[.onResume] = onResumeCode
        }

        // Create SCXMLBoilerplate for state
        var scxmlBoilerplate = SCXMLBoilerplate()
        scxmlBoilerplate.genericSections = genericSections.isEmpty ? nil : genericSections
        stateBoilerplate[stateID] = scxmlBoilerplate
    }

    private func parseExecutableContent(_ parent: XMLElement) throws -> [ExecutableAction] {
        var actions: [ExecutableAction] = []

        for child in parent.children ?? [] {
            guard let elem = child as? XMLElement else { continue }

            switch elem.name {
            case "script":
                if let script = elem.stringValue {
                    actions.append(.script(script))
                }
            case "assign":
                guard let location = elem.attributeValue(forName: "location"),
                    let expr = elem.attributeValue(forName: "expr")
                else {
                    throw SCXMLParserError.missingRequiredAttribute(
                        element: "assign", attribute: "location or expr")
                }
                actions.append(.assign(location: location, expr: expr))
            case "raise":
                guard let event = elem.attributeValue(forName: "event") else {
                    throw SCXMLParserError.missingRequiredAttribute(
                        element: "raise", attribute: "event")
                }
                actions.append(.raise(event: event))
            case "send":
                guard let event = elem.attributeValue(forName: "event") else {
                    throw SCXMLParserError.missingRequiredAttribute(
                        element: "send", attribute: "event")
                }
                let target = elem.attributeValue(forName: "target")
                let delay = elem.attributeValue(forName: "delay")
                actions.append(.send(event: event, target: target, delay: delay))
            case "log":
                let expr = elem.attributeValue(forName: "expr") ?? ""
                let label = elem.attributeValue(forName: "label")
                actions.append(.log(expr: expr, label: label))
            case "if":
                guard let cond = elem.attributeValue(forName: "cond") else {
                    throw SCXMLParserError.missingRequiredAttribute(
                        element: "if", attribute: "cond")
                }
                let thenActions = try parseExecutableContent(elem)
                // Parse else blocks
                let elseActions: [ExecutableAction]? = nil  // TODO: parse else/elseif
                actions.append(.if(condition: cond, actions: thenActions, elseActions: elseActions))
            default:
                // Unknown executable content - store as script
                if let content = elem.stringValue, !content.isEmpty {
                    actions.append(.script("/* \(elem.name ?? "unknown") */\n\(content)"))
                }
            }
        }

        return actions
    }

    private func parseInvokes(_ element: XMLElement, stateID: StateID) {
        var invocations: [Invocation] = []

        for invokeElem in element.elements(forName: "invoke") {
            guard let type = invokeElem.attributeValue(forName: "type") else {
                continue
            }

            let src = invokeElem.attributeValue(forName: "src")
            let id = invokeElem.attributeValue(forName: "id")
            let autoForward = invokeElem.attributeValue(forName: "autoforward") == "true"

            let invocation = Invocation(type: type, src: src, id: id, autoForward: autoForward)
            invocations.append(invocation)
        }

        if !invocations.isEmpty {
            boilerplate.invocations[stateID.uuidString] = invocations
        }
    }

    private func parseLayoutMetadata(_ element: XMLElement, stateID: StateID) {
        // Parse common visual editor attributes
        var x: Double = 0
        var y: Double = 0
        var width: Double = 120
        var height: Double = 80

        // ScxmlEditor uses se:x, se:y, etc.
        if let xAttr = element.attributeValue(forName: "x")
            ?? element.attributeValue(forName: "se:x")
        {
            x = Double(xAttr) ?? 0
        }
        if let yAttr = element.attributeValue(forName: "y")
            ?? element.attributeValue(forName: "se:y")
        {
            y = Double(yAttr) ?? 0
        }
        if let wAttr = element.attributeValue(forName: "width")
            ?? element.attributeValue(forName: "se:width")
        {
            width = Double(wAttr) ?? 120
        }
        if let hAttr = element.attributeValue(forName: "height")
            ?? element.attributeValue(forName: "se:height")
        {
            height = Double(hAttr) ?? 80
        }

        // Create a basic StateLayout with default values
        // Full layout conversion from SCXML visual metadata will be implemented in future iterations
        let topLeft = Coordinate2D(x, y)
        let dimensions = Dimensions2D(width, height)
        let layout = StateLayout(
            isOpen: true,
            openLayout: Rectangle(topLeft: topLeft, dimensions: dimensions),
            closedLayout: Ellipse(topLeft: topLeft, dimensions: dimensions),
            onEntryHeight: 0,
            onExitHeight: 0,
            onSuspendHeight: 0,
            onResumeHeight: 0,
            internalHeight: 0,
            zoomedOnEntryHeight: 0,
            zoomedOnExitHeight: 0,
            zoomedInternalHeight: 0,
            zoomedOnSuspendHeight: 0,
            zoomedOnResumeHeight: 0,
            extraProperties: [:]
        )
        stateLayouts[stateID] = layout
    }

    private func parseTransitions() throws {
        // Parse transitions from all states
        for state in states {
            guard let stateIDString = states.first(where: { $0.id == state.id })?.name,
                let elem = findElement(byID: stateIDString)
            else {
                continue
            }

            for transitionElem in elem.elements(forName: "transition") {
                try parseTransition(transitionElem, sourceStateID: state.id)
            }
        }
    }

    private func parseTransition(_ element: XMLElement, sourceStateID: StateID) throws {
        let transitionID = TransitionID()

        // Parse target
        guard let targetString = element.attributeValue(forName: "target") else {
            // Targetless transitions are valid in SCXML (self-transitions)
            let transition = Transition(
                id: transitionID, label: "", source: sourceStateID, target: sourceStateID)
            transitions.append(transition)
            return
        }

        guard let targetStateID = stateMap[targetString] else {
            throw SCXMLParserError.invalidTransitionTarget(targetString)
        }

        // Create basic transition
        let label = element.attributeValue(forName: "cond") ?? ""
        let transition = Transition(
            id: transitionID, label: label, source: sourceStateID, target: targetStateID)
        transitions.append(transition)

        // Parse SCXML metadata
        var metadata = SCXMLTransitionMetadata()
        metadata.event = element.attributeValue(forName: "event")
        metadata.condition = element.attributeValue(forName: "cond")
        metadata.type =
            element.attributeValue(forName: "type") == "internal" ? .internal : .external

        // Parse executable content
        metadata.actions = try parseExecutableContent(element)

        transitionMetadata[transitionID] = metadata
    }

    private func determineInitialState(_ root: XMLElement) throws -> StateID {
        // Check initial attribute
        if let initialAttr = root.attributeValue(forName: "initial"),
            let initialStateID = stateMap[initialAttr]
        {
            return initialStateID
        }

        // Check for <initial> element
        if let initialElem = root.elements(forName: "initial").first,
            let transitionElem = initialElem.elements(forName: "transition").first,
            let target = transitionElem.attributeValue(forName: "target"),
            let targetStateID = stateMap[target]
        {
            return targetStateID
        }

        // Default to first state
        guard let firstState = states.first else {
            throw SCXMLParserError.parsingFailed("No states found in SCXML document")
        }

        return firstState.id
    }

    private func findElement(byID id: String) -> XMLElement? {
        guard let root = xmlDoc?.rootElement() else { return nil }
        return findElement(byID: id, in: root)
    }

    private func findElement(byID id: String, in parent: XMLElement) -> XMLElement? {
        if parent.attributeValue(forName: "id") == id {
            return parent
        }

        for child in parent.children ?? [] {
            if let elem = child as? XMLElement,
                let found = findElement(byID: id, in: elem)
            {
                return found
            }
        }

        return nil
    }

    private func executableActionsToCode(_ actions: [ExecutableAction]) -> String {
        var code = ""
        for action in actions {
            switch action {
            case .script(let script):
                code += script + "\n"
            case .assign(let location, let expr):
                code += "\(location) = \(expr);\n"
            case .raise(let event):
                code += "raise('\(event)');\n"
            case .send(let event, let target, let delay):
                var sendCode = "send('\(event)'"
                if let tgt = target {
                    sendCode += ", target: '\(tgt)'"
                }
                if let dly = delay {
                    sendCode += ", delay: '\(dly)'"
                }
                sendCode += ");\n"
                code += sendCode
            case .log(let expr, let label):
                if let lbl = label {
                    code += "console.log('\(lbl):', \(expr));\n"
                } else {
                    code += "console.log(\(expr));\n"
                }
            case .if(let cond, let thenActions, let elseActions):
                code += "if (\(cond)) {\n"
                code += executableActionsToCode(thenActions)
                if let elseActs = elseActions {
                    code += "} else {\n"
                    code += executableActionsToCode(elseActs)
                }
                code += "}\n"
            case .forEach(let array, let item, let index, let actions):
                let indexVar = index ?? "_index"
                code +=
                    "for (let \(indexVar) = 0; \(indexVar) < \(array).length; \(indexVar)++) {\n"
                code += "  let \(item) = \(array)[\(indexVar)];\n"
                code += executableActionsToCode(actions)
                code += "}\n"
            case .cancel(let sendId):
                code += "cancel('\(sendId)');\n"
            }
        }
        return code
    }
}

// MARK: - XMLElement Extension for Linux Compatibility

/// Workaround for FoundationXML bug on Linux where attribute(forName:) returns nil
/// when the document has a namespace declaration.
/// See: https://github.com/swiftlang/swift-corelibs-foundation/issues/4943
#if canImport(FoundationXML)
extension XMLElement {
    /// Get attribute value with fallback for namespace bug on Linux.
    ///
    /// On Linux with FoundationXML, when an XML document has a namespace declaration
    /// like `xmlns="http://www.w3.org/2005/07/scxml"`, the standard `attribute(forName:)`
    /// method incorrectly returns nil even when attributes exist.
    ///
    /// This method provides a workaround by manually iterating through the attributes
    /// array when the standard method fails.
    fileprivate func attributeValue(forName name: String) -> String? {
        // Try standard method first (works on macOS and Linux without xmlns)
        if let value = attribute(forName: name)?.stringValue {
            return value
        }

        // Fallback: manually search attributes array (for Linux with xmlns)
        for attr in attributes ?? [] {
            if attr.name == name {
                return attr.stringValue
            }
        }

        return nil
    }
}
#else
extension XMLElement {
    /// Get attribute value - on Darwin platforms, just use the standard method.
    fileprivate func attributeValue(forName name: String) -> String? {
        return attribute(forName: name)?.stringValue
    }
}
#endif
