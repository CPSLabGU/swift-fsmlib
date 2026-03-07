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
    /// The XML document is malformed or cannot be parsed.
    case invalidXML(String)

    /// A required XML attribute is absent from the given element.
    case missingRequiredAttribute(element: String, attribute: String)

    /// A state reference could not be resolved to a known state.
    case invalidStateReference(String)

    /// A transition target could not be resolved to a known state.
    case invalidTransitionTarget(String)

    /// A circular parent–child relationship was detected in the state hierarchy.
    case circularStateHierarchy(String)

    /// Two or more states share the same identifier.
    case duplicateStateID(String)

    /// The datamodel type specified is not supported by this parser.
    case unsupportedDatamodel(String)

    /// Parsing failed for a general reason described by the message.
    case parsingFailed(String)

    /// Human-readable description of the error.
    public var description: String {
        switch self {
        case .invalidXML(let msg):
            return "Invalid XML: \(msg)"
        case .missingRequiredAttribute(let elem, let attr):
            return "Missing required attribute '\(attr)' on element '\(elem)'"
        case .invalidStateReference(let ref):
            return "Invalid state reference: \(ref)"
        case .invalidTransitionTarget(let target):
            return "Invalid transition target: \(target)"
        case .circularStateHierarchy(let state):
            return "Circular state hierarchy detected: \(state)"
        case .duplicateStateID(let id):
            return "Duplicate state ID: \(id)"
        case .unsupportedDatamodel(let dm):
            return "Unsupported datamodel: \(dm)"
        case .parsingFailed(let msg):
            return "Parsing failed: \(msg)"
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

    /// The parsed XML document, set during `parse(_:)`.
    private var xmlDoc: XMLDocument?

    /// Map from SCXML state ID strings to internal `StateID` UUIDs.
    private var stateMap: [String: StateID] = [:]

    /// Ordered list of states accumulated during parsing.
    private var states: [State] = []

    /// Ordered list of transitions accumulated during parsing.
    private var transitions: [Transition] = []

    /// SCXML-specific metadata for each state, keyed by `StateID`.
    private var stateMetadata: SCXMLStateMetadataMap = [:]

    /// SCXML-specific metadata for each transition, keyed by `TransitionID`.
    private var transitionMetadata: SCXMLTransitionMetadataMap = [:]

    /// Machine-level SCXML boilerplate accumulated during parsing.
    private var boilerplate = SCXMLBoilerplate()

    /// Per-state boilerplate (activities), keyed by `StateID`.
    private var stateBoilerplate: [StateID: any Boilerplate] = [:]

    /// Visual layout data for each state, keyed by `StateID`.
    private var stateLayouts: StateLayouts = [:]

    /// Visual layout data for each transition, keyed by `TransitionID`.
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

    /// Reset all accumulated parsing state to prepare for a new parse operation.
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

    /// Parse the attributes of the root `<scxml>` element and populate `boilerplate`.
    ///
    /// - Parameter element: The root `<scxml>` XML element.
    /// - Throws: `SCXMLParserError.missingRequiredAttribute` if the `version` attribute is absent.
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


    /// Recursively parse all child state elements (`<state>`, `<parallel>`, `<final>`, `<history>`) of `parent`.
    ///
    /// - Parameters:
    ///   - parent: The XML element whose children will be parsed.
    ///   - parentStateID: The internal ID of the enclosing state, or `nil` for top-level states.
    /// - Throws: `SCXMLParserError` if any child state is invalid.
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

    /// Parse a single state element and register it in `states` and `stateMap`.
    ///
    /// - Parameters:
    ///   - element: The `<state>`, `<parallel>`, or `<final>` XML element.
    ///   - parentStateID: The internal ID of the enclosing state, or `nil` for top-level states.
    ///   - isParallel: `true` if this state is a `<parallel>` element.
    ///   - isFinal: `true` if this state is a `<final>` element.
    /// - Throws: `SCXMLParserError` if required attributes are missing or the ID is a duplicate.
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
            let countBefore = states.count
            try parseStates(element, parent: stateID)
            // Populate childStates with direct children only (not grandchildren)
            metadata.childStates = states[countBefore...].compactMap { child in
                stateMetadata[child.id]?.parentState == stateID ? child.id : nil
            }
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

    /// Parse a `<history>` element and register it as a pseudo-state.
    ///
    /// - Parameters:
    ///   - element: The `<history>` XML element.
    ///   - parentStateID: The internal ID of the enclosing state, or `nil` for top-level elements.
    /// - Throws: `SCXMLParserError.missingRequiredAttribute` if the `id` attribute is absent.
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
            transitionElem.attributeValue(forName: "target") != nil {
            // Will resolve after all states parsed
        }

        stateMetadata[stateID] = metadata
    }

    /// Parse `<onentry>`, `<onexit>`, and FSMLib extension sections from a state element.
    ///
    /// - Parameters:
    ///   - element: The state XML element containing action children.
    ///   - stateID: The internal ID of the state being parsed.
    /// - Throws: `SCXMLParserError` if any executable content is invalid.
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

        // Parse FSMLib legacy extension sections
        parseLegacyFSMLibSections(element, into: &genericSections)

        // Create SCXMLBoilerplate for state
        var scxmlBoilerplate = SCXMLBoilerplate()
        scxmlBoilerplate.genericSections = genericSections.isEmpty ? nil : genericSections
        stateBoilerplate[stateID] = scxmlBoilerplate
    }

    /// Parse legacy FSMLib extension elements (`fsm:internal`, `fsm:onSuspend`, `fsm:onResume`) into `sections`.
    ///
    /// Supports the old element-per-section format for backwards compatibility.
    ///
    /// - Parameters:
    ///   - element: The state XML element to search for legacy sections.
    ///   - sections: The dictionary to populate with parsed section content.
    private func parseLegacyFSMLibSections(
        _ element: XMLElement,
        into sections: inout [StandardBoilerplateSection: String]
    ) {
        let legacyNames: [(elementName: String, section: StandardBoilerplateSection)] = [
            ("fsm:internal", .internal),
            ("fsm:onSuspend", .onSuspend),
            ("fsm:onResume", .onResume),
        ]
        for (elementName, section) in legacyNames {
            let elems = element.elements(forName: elementName)
            guard !elems.isEmpty else { continue }
            let code = elems.compactMap { $0.stringValue }.joined()
            sections[section] = code
        }
    }

    /// Determine the initial state ID from the root `<scxml>` element.
    ///
    /// Resolution order: `initial` attribute → `<initial>` child element → first state.
    ///
    /// - Parameter root: The root `<scxml>` XML element.
    /// - Returns: The `StateID` of the initial state.
    /// - Throws: `SCXMLParserError.parsingFailed` if no states have been parsed.
    private func determineInitialState(_ root: XMLElement) throws -> StateID {
        // Check initial attribute
        if let initialAttr = root.attributeValue(forName: "initial"),
            let initialStateID = stateMap[initialAttr] {
            return initialStateID
        }

        // Check for <initial> element
        if let initialElem = root.elements(forName: "initial").first,
            let transitionElem = initialElem.elements(forName: "transition").first,
            let target = transitionElem.attributeValue(forName: "target"),
            let targetStateID = stateMap[target] {
            return targetStateID
        }

        // Default to first state
        guard let firstState = states.first else {
            throw SCXMLParserError.parsingFailed("No states found in SCXML document")
        }

        return firstState.id
    }

    /// Search the parsed XML document for an element whose `id` attribute matches `id`.
    ///
    /// - Parameter id: The XML `id` attribute value to search for.
    /// - Returns: The matching `XMLElement`, or `nil` if not found.
    private func findElement(byID id: String) -> XMLElement? {
        guard let root = xmlDoc?.rootElement() else { return nil }
        return findElement(byID: id, in: root)
    }

    /// Recursively search `parent` and its descendants for an element with the given `id`.
    ///
    /// - Parameters:
    ///   - id: The XML `id` attribute value to search for.
    ///   - parent: The element to search within.
    /// - Returns: The matching `XMLElement`, or `nil` if not found.
    private func findElement(byID id: String, in parent: XMLElement) -> XMLElement? {
        if parent.attributeValue(forName: "id") == id {
            return parent
        }

        for case let elem as XMLElement in parent.children ?? [] {
            if let found = findElement(byID: id, in: elem) {
                return found
            }
        }

        return nil
    }

}

// MARK: - Transition & Layout Parsing

/// Extension providing transition, layout, and executable content parsing for `SCXMLParser`.
private extension SCXMLParser {
    /// Parse all `<invoke>` child elements and store them in `boilerplate.invocations`.
    ///
    /// - Parameters:
    ///   - element: The state XML element containing `<invoke>` children.
    ///   - stateID: The internal ID of the owning state.
    func parseInvokes(_ element: XMLElement, stateID: StateID) {
        var invocations: [Invocation] = []
        for invokeElem in element.elements(forName: "invoke") {
            guard let type = invokeElem.attributeValue(forName: "type") else { continue }
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

    /// Parse visual layout attributes from a state element and store in `stateLayouts`.
    ///
    /// Supports `x`, `y`, `width`, `height` and their `se:` namespace equivalents.
    ///
    /// - Parameters:
    ///   - element: The state XML element that may contain layout attributes.
    ///   - stateID: The internal ID of the state being laid out.
    func parseLayoutMetadata(_ element: XMLElement, stateID: StateID) {
        var x: Double = 0
        var y: Double = 0
        var width: Double = 120
        var height: Double = 80
        if let xAttr = element.attributeValue(forName: "x") ?? element.attributeValue(forName: "se:x") {
            x = Double(xAttr) ?? 0
        }
        if let yAttr = element.attributeValue(forName: "y") ?? element.attributeValue(forName: "se:y") {
            y = Double(yAttr) ?? 0
        }
        if let wAttr = element.attributeValue(forName: "width") ?? element.attributeValue(forName: "se:width") {
            width = Double(wAttr) ?? 120
        }
        if let hAttr = element.attributeValue(forName: "height") ?? element.attributeValue(forName: "se:height") {
            height = Double(hAttr) ?? 80
        }
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

    /// Parse all `<transition>` child elements for every state in `states`.
    ///
    /// - Throws: `SCXMLParserError` if a transition target references an unknown state.
    func parseTransitions() throws {
        for state in states {
            guard let stateIDString = states.first(where: { $0.id == state.id })?.name,
                let elem = findElement(byID: stateIDString)
            else { continue }
            for transitionElem in elem.elements(forName: "transition") {
                try parseTransition(transitionElem, sourceStateID: state.id)
            }
        }
    }

    /// Parse a single `<transition>` element and append the result to `transitions`.
    ///
    /// - Parameters:
    ///   - element: The `<transition>` XML element.
    ///   - sourceStateID: The internal ID of the state that owns this transition.
    /// - Throws: `SCXMLParserError.invalidTransitionTarget` if the target state is unknown.
    func parseTransition(_ element: XMLElement, sourceStateID: StateID) throws {
        let transitionID = TransitionID()
        guard let targetString = element.attributeValue(forName: "target") else {
            let transition = Transition(
                id: transitionID, label: "", source: sourceStateID, target: sourceStateID)
            transitions.append(transition)
            return
        }
        guard let targetStateID = stateMap[targetString] else {
            throw SCXMLParserError.invalidTransitionTarget(targetString)
        }
        let label = element.attributeValue(forName: "cond") ?? ""
        let transition = Transition(
            id: transitionID, label: label, source: sourceStateID, target: targetStateID)
        transitions.append(transition)
        var metadata = SCXMLTransitionMetadata()
        metadata.event = element.attributeValue(forName: "event")
        metadata.condition = element.attributeValue(forName: "cond")
        metadata.type =
            element.attributeValue(forName: "type") == "internal" ? .internal : .external
        metadata.actions = try parseExecutableContent(element)
        transitionMetadata[transitionID] = metadata
    }

    /// Parse all child elements of `parent` as executable actions.
    ///
    /// - Parameter parent: The XML element whose children are executable content.
    /// - Returns: An array of parsed `ExecutableAction` values.
    /// - Throws: `SCXMLParserError` if any child element is invalid.
    func parseExecutableContent(_ parent: XMLElement) throws -> [ExecutableAction] {
        var actions: [ExecutableAction] = []
        for child in parent.children ?? [] {
            guard let elem = child as? XMLElement else { continue }
            if let action = try parseSingleAction(elem) {
                actions.append(action)
            }
        }
        return actions
    }

    /// Parse a single executable action element.
    ///
    /// - Parameter elem: The XML element to parse.
    /// - Returns: The parsed action, or `nil` if the element is empty/ignorable.
    /// - Throws: `SCXMLParserError` if required attributes are missing.
    func parseSingleAction(_ elem: XMLElement) throws -> ExecutableAction? {
        switch elem.name {
        case "script":
            return elem.stringValue.map { .script($0) }
        case "assign":
            guard let location = elem.attributeValue(forName: "location"),
                let expr = elem.attributeValue(forName: "expr")
            else {
                throw SCXMLParserError.missingRequiredAttribute(
                    element: "assign", attribute: "location or expr")
            }
            return .assign(location: location, expr: expr)
        case "raise":
            guard let event = elem.attributeValue(forName: "event") else {
                throw SCXMLParserError.missingRequiredAttribute(
                    element: "raise", attribute: "event")
            }
            return .raise(event: event)
        case "send":
            guard let event = elem.attributeValue(forName: "event") else {
                throw SCXMLParserError.missingRequiredAttribute(
                    element: "send", attribute: "event")
            }
            return .send(
                event: event,
                target: elem.attributeValue(forName: "target"),
                delay: elem.attributeValue(forName: "delay")
            )
        case "log":
            return .log(
                expr: elem.attributeValue(forName: "expr") ?? "",
                label: elem.attributeValue(forName: "label")
            )
        case "if":
            guard let cond = elem.attributeValue(forName: "cond") else {
                throw SCXMLParserError.missingRequiredAttribute(element: "if", attribute: "cond")
            }
            return try parseIfElement(cond: cond, element: elem)
        case "foreach":
            guard let array = elem.attributeValue(forName: "array") else {
                throw SCXMLParserError.missingRequiredAttribute(
                    element: "foreach", attribute: "array")
            }
            guard let item = elem.attributeValue(forName: "item") else {
                throw SCXMLParserError.missingRequiredAttribute(
                    element: "foreach", attribute: "item")
            }
            let body = try parseExecutableContent(elem)
            return .forEach(
                array: array,
                item: item,
                index: elem.attributeValue(forName: "index"),
                actions: body
            )
        case "cancel":
            guard let sendId = elem.attributeValue(forName: "sendid") else {
                throw SCXMLParserError.missingRequiredAttribute(
                    element: "cancel", attribute: "sendid")
            }
            return .cancel(sendId: sendId)
        default:
            if let content = elem.stringValue, !content.isEmpty {
                return .script("/* \(elem.name ?? "unknown") */\n\(content)")
            }
            return nil
        }
    }

    /// Parse an `<if>` element, handling `<elseif>` and `<else>` children.
    ///
    /// - Parameters:
    ///   - cond: The condition for this `<if>` element.
    ///   - element: The `<if>` XML element.
    /// - Returns: The parsed `.if` action.
    /// - Throws: `SCXMLParserError` if required attributes are missing.
    func parseIfElement(cond: String, element: XMLElement) throws -> ExecutableAction {
        var thenActions: [ExecutableAction] = []
        var elseIfChain: [(condition: String, elements: [XMLElement])] = []
        var elseElements: [XMLElement]?
        enum CollectionPhase { case then; case elseIf(index: Int); case elseBlock }
        var phase = CollectionPhase.then

        for child in element.children ?? [] {
            guard let elem = child as? XMLElement else { continue }
            switch elem.name {
            case "elseif":
                guard let elseIfCond = elem.attributeValue(forName: "cond") else {
                    throw SCXMLParserError.missingRequiredAttribute(
                        element: "elseif", attribute: "cond")
                }
                elseIfChain.append((condition: elseIfCond, elements: []))
                phase = .elseIf(index: elseIfChain.count - 1)
            case "else":
                elseElements = []
                phase = .elseBlock
            default:
                switch phase {
                case .then:
                    if let action = try parseSingleAction(elem) { thenActions.append(action) }
                case .elseIf(let index):
                    elseIfChain[index].elements.append(elem)
                case .elseBlock:
                    elseElements?.append(elem)
                }
            }
        }
        var currentElseActions: [ExecutableAction]?
        if let elseElems = elseElements {
            var actions: [ExecutableAction] = []
            for elem in elseElems {
                if let action = try parseSingleAction(elem) { actions.append(action) }
            }
            currentElseActions = actions
        }
        for entry in elseIfChain.reversed() {
            var actions: [ExecutableAction] = []
            for elem in entry.elements {
                if let action = try parseSingleAction(elem) { actions.append(action) }
            }
            let nestedIf = ExecutableAction.if(
                condition: entry.condition, actions: actions, elseActions: currentElseActions)
            currentElseActions = [nestedIf]
        }
        return .if(condition: cond, actions: thenActions, elseActions: currentElseActions)
    }
}

// MARK: - FSMLib Boilerplate & Datamodel Parsing

/// Extension providing FSMLib boilerplate and datamodel parsing for `SCXMLParser`.
private extension SCXMLParser {
    /// Parse FSMLib-specific boilerplate from the `<fsm:boilerplate>` child of the root element.
    ///
    /// - Parameter root: The root `<scxml>` XML element.
    func parseFSMLibBoilerplate(_ root: XMLElement) {
        for child in root.children ?? [] {
            guard let elem = child as? XMLElement,
                  elem.name == "fsm:boilerplate" || elem.name == "boilerplate"
            else { continue }

            var genericSections: [StandardBoilerplateSection: String] = [:]

            for sectionElem in elem.elements(forName: "fsm:section") {
                guard let sectionName = sectionElem.attributeValue(forName: "name"),
                      let section = StandardBoilerplateSection(rawValue: sectionName) else {
                    continue
                }
                let content = sectionElem.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                genericSections[section] = content
            }

            parseLegacyBoilerplateSections(elem, into: &genericSections)

            if !genericSections.isEmpty {
                boilerplate.genericSections = genericSections
            }
            break
        }
    }

    /// Parse legacy named boilerplate elements (`fsm:includePath`, etc.) into `sections`.
    ///
    /// - Parameters:
    ///   - elem: The `<fsm:boilerplate>` element to search.
    ///   - sections: The dictionary to populate with parsed section content.
    func parseLegacyBoilerplateSections(
        _ elem: XMLElement,
        into sections: inout [StandardBoilerplateSection: String]
    ) {
        struct LegacyEntry {
            var primary: String
            var fallback: String
            var section: StandardBoilerplateSection
        }
        let legacyMap: [LegacyEntry] = [
            LegacyEntry(primary: "fsm:includePath", fallback: "includePath", section: .includePath),
            LegacyEntry(primary: "fsm:includes", fallback: "includes", section: .includes),
            LegacyEntry(primary: "fsm:variables", fallback: "variables", section: .variables),
            LegacyEntry(primary: "fsm:functions", fallback: "functions", section: .functions),
        ]
        for entry in legacyMap {
            if let legacyElem = elem.elements(forName: entry.primary).first
                ?? elem.elements(forName: entry.fallback).first {
                let content = legacyElem.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                sections[entry.section] = content
            }
        }
    }

    /// Parse the `<datamodel>` element and populate `boilerplate.dataDeclarations`.
    ///
    /// - Parameter element: The `<datamodel>` XML element.
    /// - Throws: `SCXMLParserError.missingRequiredAttribute` if a `<data>` element has no `id`.
    func parseDatamodel(_ element: XMLElement) throws {
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
}

// MARK: - Executable Action Code Generation

/// Extension providing code generation helpers for `SCXMLParser`.
private extension SCXMLParser {
    /// Convert a list of executable actions to a code string for storage in boilerplate.
    ///
    /// - Parameter actions: The actions to serialise.
    /// - Returns: A multi-line code string representing the actions.
    func executableActionsToCode(_ actions: [ExecutableAction]) -> String {
        var code = ""
        for action in actions {
            code += executableActionToCode(action)
        }
        return code
    }

    /// Convert a single executable action to its code representation.
    ///
    /// - Parameter action: The action to serialise.
    /// - Returns: A code string for the action.
    func executableActionToCode(_ action: ExecutableAction) -> String {
        switch action {
        case .script(let script):
            return script + "\n"
        case .assign(let location, let expr):
            return "\(location) = \(expr);\n"
        case .raise(let event):
            return "raise('\(event)');\n"
        case .send(let event, let target, let delay):
            return sendActionToCode(event: event, target: target, delay: delay)
        case .log(let expr, let label):
            if let lbl = label {
                return "console.log('\(lbl):', \(expr));\n"
            } else {
                return "console.log(\(expr));\n"
            }
        case .if(let cond, let thenActions, let elseActions):
            var code = "if (\(cond)) {\n"
            code += executableActionsToCode(thenActions)
            if let elseActs = elseActions {
                code += "} else {\n"
                code += executableActionsToCode(elseActs)
            }
            code += "}\n"
            return code
        case .forEach(let array, let item, let index, let actions):
            let indexVar = index ?? "_index"
            var code = "for (let \(indexVar) = 0; \(indexVar) < \(array).length; \(indexVar)++) {\n"
            code += "  let \(item) = \(array)[\(indexVar)];\n"
            code += executableActionsToCode(actions)
            code += "}\n"
            return code
        case .cancel(let sendId):
            return "cancel('\(sendId)');\n"
        }
    }

    /// Build a send action code string from its components.
    ///
    /// - Parameters:
    ///   - event: The event name to send.
    ///   - target: Optional target recipient.
    ///   - delay: Optional delay string.
    /// - Returns: A code string for the send action.
    func sendActionToCode(event: String, target: String?, delay: String?) -> String {
        var sendCode = "send('\(event)'"
        if let tgt = target {
            sendCode += ", target: '\(tgt)'"
        }
        if let dly = delay {
            sendCode += ", delay: '\(dly)'"
        }
        sendCode += ");\n"
        return sendCode
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
        return (attributes ?? []).first(where: { $0.name == name })?.stringValue
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
