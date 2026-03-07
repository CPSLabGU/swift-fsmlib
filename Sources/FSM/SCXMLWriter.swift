//
//  SCXMLWriter.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

/// SCXML writer for converting Machine objects to SCXML XML documents.
///
/// This class handles generation of SCXML 1.0 documents, supporting:
/// - Basic states and transitions
/// - Compound and parallel states
/// - History states (shallow/deep)
/// - Final states
/// - Data models
/// - Executable content (onentry/onexit/script/assign/send/raise)
/// - Layout preservation for visual editors
public final class SCXMLWriter {
    // MARK: - Properties

    /// Current indentation depth (number of `indentString` repetitions).
    private var indentLevel = 0

    /// The string used for a single level of indentation.
    private let indentString = "  "

    // MARK: - Public API

    /// Generate SCXML XML from a Machine object.
    ///
    /// - Parameter machine: The Machine to convert to SCXML
    /// - Returns: SCXML XML string
    /// - Throws: Error if generation fails
    public func generate(from machine: Machine) throws -> String {
        guard let scxmlBoilerplate = machine.boilerplate as? SCXMLBoilerplate else {
            // Use default boilerplate if not SCXML
            return try generateFromGenericMachine(machine)
        }

        indentLevel = 0
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += generateRootAttributes(machine: machine, boilerplate: scxmlBoilerplate)
        indentLevel += 1
        xml += try generateRootContent(machine: machine, boilerplate: scxmlBoilerplate)
        indentLevel -= 1
        xml += "</scxml>\n"
        return xml
    }

    /// Generate the opening `<scxml ...>` tag with all required attributes.
    ///
    /// - Parameters:
    ///   - machine: The machine being serialised.
    ///   - boilerplate: The SCXML boilerplate providing attribute values.
    /// - Returns: The `<scxml ...>\n` opening tag string.
    private func generateRootAttributes(machine: Machine, boilerplate: SCXMLBoilerplate) -> String {
        var xml = "<scxml"
        xml += " xmlns=\"http://www.w3.org/2005/07/scxml\""
        xml += " xmlns:fsm=\"http://mipal.net.au/fsmlib\""
        xml += " xmlns:qt=\"http://www.qt.io/2015/02/scxml-ext\""
        xml += " xmlns:se=\"http://scxmleditor.sf.net\""
        xml += " version=\"\(boilerplate.scxmlVersion)\""
        xml += " datamodel=\"\(boilerplate.datamodel)\""
        xml += " binding=\"\(boilerplate.binding)\""
        if let name = boilerplate.name {
            xml += " name=\"\(name.xmlEscaped)\""
        }
        if let targetLanguage = boilerplate.targetLanguage {
            xml += " fsm:language=\"\(targetLanguage.xmlEscaped)\""
        }
        if let initialState = machine.llfsm.states.first,
            let initialStateName = machine.llfsm.stateName(for: initialState) {
            xml += " initial=\"\(initialStateName.xmlEscaped)\""
        }
        xml += ">\n"
        return xml
    }

    /// Generate the body of the `<scxml>` element (boilerplate, datamodel, script, states).
    ///
    /// - Parameters:
    ///   - machine: The machine being serialised.
    ///   - boilerplate: The SCXML boilerplate for body content.
    /// - Returns: The XML body string.
    /// - Throws: Error if state generation fails.
    private func generateRootContent(machine: Machine, boilerplate: SCXMLBoilerplate) throws -> String {
        var xml = ""
        if let genericSections = boilerplate.genericSections, !genericSections.isEmpty {
            xml += generateFSMLibBoilerplateFromSections(genericSections)
        }
        if !boilerplate.dataDeclarations.isEmpty {
            xml += generateDatamodel(boilerplate.dataDeclarations)
        }
        if let script = boilerplate.initialScript, !script.isEmpty {
            xml += indent() + "<script>\n"
            indentLevel += 1
            xml += indent() + script.xmlEscaped + "\n"
            indentLevel -= 1
            xml += indent() + "</script>\n"
        }
        for stateID in machine.llfsm.states {
            guard let state = machine.llfsm.stateMap[stateID] else { continue }
            if boilerplate.stateMetadata[stateID]?.parentState != nil { continue }
            xml += try generateState(state, machine: machine)
        }
        return xml
    }

    /// Generate the `<datamodel>` element and its `<data>` children.
    ///
    /// - Parameter declarations: The data declarations to serialise.
    /// - Returns: The `<datamodel>...</datamodel>` XML string.
    private func generateDatamodel(_ declarations: [DataDeclaration]) -> String {
        var xml = indent() + "<datamodel>\n"
        indentLevel += 1
        for decl in declarations {
            xml += indent() + "<data id=\"\(decl.id.xmlEscaped)\""
            if let expr = decl.expr {
                xml += " expr=\"\(expr.xmlEscaped)\""
            }
            if let src = decl.src {
                xml += " src=\"\(src.xmlEscaped)\""
            }
            if let content = decl.content, !content.isEmpty {
                xml += ">\n"
                indentLevel += 1
                xml += indent() + content.xmlEscaped + "\n"
                indentLevel -= 1
                xml += indent() + "</data>\n"
            } else {
                xml += "/>\n"
            }
        }
        indentLevel -= 1
        xml += indent() + "</datamodel>\n"
        return xml
    }

    // MARK: - Private Methods

    /// Return a string of spaces for the current indentation level.
    private func indent() -> String {
        String(repeating: indentString, count: indentLevel)
    }

    /// Generate FSMLib extension sections from generic sections dictionary.
    ///
    /// This writes extension sections (non-standard SCXML sections) as `<fsm:section name="...">`.
    /// Standard SCXML sections (onEntry, onExit) are NOT written here - they're handled
    /// in state generation.
    ///
    /// Extension sections include:
    /// - includePath, includes, variables, functions (machine boilerplate)
    /// - internal, onSuspend, onResume (state activities not in standard SCXML)
    ///
    /// IMPORTANT: Empty sections are preserved for round-trip fidelity.
    private func generateFSMLibBoilerplateFromSections(_ sections: [StandardBoilerplateSection: String]) -> String {
        // Define which sections are extensions (not standard SCXML)
        let extensionSections: Set<StandardBoilerplateSection> = [
            .includePath, .includes, .variables, .functions,
            .internal, .onSuspend, .onResume
        ]

        // Filter to only extension sections (preserve empty strings!)
        let filteredSections = sections.filter { extensionSections.contains($0.key) }
        guard !filteredSections.isEmpty else { return "" }

        var xml = indent() + "<fsm:boilerplate>\n"
        indentLevel += 1

        for section in StandardBoilerplateSection.allCases where extensionSections.contains(section) {
            if let content = sections[section] {
                // Write section even if empty - preserve for round-trip
                xml += indent() + "<fsm:section name=\"\(section.rawValue)\"><![CDATA[\n"
                xml += content
                if !content.hasSuffix("\n") { xml += "\n" }
                xml += indent() + "]]></fsm:section>\n"
            }
        }

        indentLevel -= 1
        xml += indent() + "</fsm:boilerplate>\n"
        return xml
    }

    /// Generate XML for a single state element, recursing into child states.
    ///
    /// - Parameters:
    ///   - state: The state to serialise.
    ///   - machine: The machine that owns the state.
    /// - Returns: The state XML string.
    /// - Throws: Error if transition or child state generation fails.
    private func generateState(_ state: State, machine: Machine) throws -> String {
        guard let scxmlBoilerplate = machine.boilerplate as? SCXMLBoilerplate else {
            return try generateBasicState(state, machine: machine)
        }

        let metadata = scxmlBoilerplate.stateMetadata[state.id]
        let isFinal = metadata?.isFinal ?? false
        let isParallel = metadata?.isParallel ?? false
        let isHistory = metadata?.historyType != nil
        let context = StateTagContext(
            isFinal: isFinal,
            isParallel: isParallel,
            isHistory: isHistory,
            metadata: metadata
        )

        var xml = indent() + stateOpenTag(context: context, state: state, machine: machine)

        let hasChildren = metadata?.childStates?.isEmpty == false
        let hasContent = hasStateContent(state, machine: machine)

        if !hasChildren && !hasContent {
            xml += "/>\n"
            return xml
        }

        xml += ">\n"
        indentLevel += 1
        xml += try generateStateBody(state: state, machine: machine, scxmlBoilerplate: scxmlBoilerplate)
        indentLevel -= 1
        xml += indent() + stateCloseTag(context: context)
        return xml
    }

    /// Contextual flags for generating a state element tag.
    private struct StateTagContext {
        /// `true` if this is a `<final>` element.
        var isFinal: Bool
        /// `true` if this is a `<parallel>` element.
        var isParallel: Bool
        /// `true` if this is a `<history>` element.
        var isHistory: Bool
        /// Optional SCXML-specific metadata for the state.
        var metadata: SCXMLStateMetadata?
    }

    /// Build the opening tag string (attributes only, no `>` or `/>`) for a state element.
    ///
    /// - Parameters:
    ///   - context: The type flags and metadata for this state.
    ///   - state: The state being serialised.
    ///   - machine: The owning machine (for layout and initial child lookups).
    /// - Returns: The opening tag string including all attributes, without closing `>`.
    private func stateOpenTag(context: StateTagContext, state: State, machine: Machine) -> String {
        var tag: String
        if context.isFinal {
            tag = "<final"
        } else if context.isParallel {
            tag = "<parallel"
        } else if context.isHistory {
            tag = "<history"
        } else {
            tag = "<state"
        }

        tag += " id=\"\(state.name.xmlEscaped)\""
        if let historyType = context.metadata?.historyType {
            tag += " type=\"\(historyType.rawValue)\""
        }
        if let initialChild = context.metadata?.initialChild,
           let initialChildName = machine.llfsm.stateName(for: initialChild) {
            tag += " initial=\"\(initialChildName.xmlEscaped)\""
        }
        if let layout = machine.stateLayout[state.id] {
            let x = Int(layout.openLayout.topLeft.x)
            let y = Int(layout.openLayout.topLeft.y)
            let width = Int(layout.openLayout.dimensions.w)
            let height = Int(layout.openLayout.dimensions.h)
            tag += " se:x=\"\(x)\" se:y=\"\(y)\" se:width=\"\(width)\" se:height=\"\(height)\""
        }
        return tag
    }

    /// Return the closing tag name for a state element.
    ///
    /// - Parameter context: The type flags for the state element.
    /// - Returns: The closing tag string including trailing newline.
    private func stateCloseTag(context: StateTagContext) -> String {
        if context.isFinal { return "</final>\n" }
        if context.isParallel { return "</parallel>\n" }
        if context.isHistory { return "</history>\n" }
        return "</state>\n"
    }

    /// Generate the body content of a state element (activities, invocations, transitions, children).
    ///
    /// - Parameters:
    ///   - state: The state being serialised.
    ///   - machine: The owning machine.
    ///   - scxmlBoilerplate: The SCXML boilerplate for metadata lookups.
    /// - Returns: The state body XML string.
    /// - Throws: Error if transition or child state generation fails.
    private func generateStateBody(
        state: State, machine: Machine, scxmlBoilerplate: SCXMLBoilerplate
    ) throws -> String {
        let sections = machine.stateActivities(for: state.id)
        var xml = generateSCXMLActivities(sections)

        if let invocations = scxmlBoilerplate.invocations[state.id.uuidString] {
            for invocation in invocations {
                xml += generateInvocation(invocation)
            }
        }

        for transitionID in machine.llfsm.transitions {
            guard let transition = machine.llfsm.transitionMap[transitionID],
                transition.source == state.id
            else { continue }
            xml += try generateTransition(transition, machine: machine)
        }

        if let childIDs = scxmlBoilerplate.stateMetadata[state.id]?.childStates {
            for childID in childIDs {
                if let childState = machine.llfsm.stateMap[childID] {
                    xml += try generateState(childState, machine: machine)
                }
            }
        }
        return xml
    }

    /// Generate XML-escaped activity elements (`<onentry>`, `<onexit>`, FSMLib extension sections).
    ///
    /// Used for SCXML-native machines where content is XML-escaped rather than CDATA-wrapped.
    ///
    /// - Parameter sections: The activity sections dictionary to serialise.
    /// - Returns: The XML string for all non-empty activity sections.
    private func generateSCXMLActivities(_ sections: [StandardBoilerplateSection: String]) -> String {
        var xml = ""
        if let onEntry = sections[.onEntry], !onEntry.isEmpty {
            xml += indent() + "<onentry>\n"
            indentLevel += 1
            xml += indent() + "<script>\n"
            indentLevel += 1
            xml += indent() + onEntry.xmlEscaped + "\n"
            indentLevel -= 1
            xml += indent() + "</script>\n"
            indentLevel -= 1
            xml += indent() + "</onentry>\n"
        }
        if let onExit = sections[.onExit], !onExit.isEmpty {
            xml += indent() + "<onexit>\n"
            indentLevel += 1
            xml += indent() + "<script>\n"
            indentLevel += 1
            xml += indent() + onExit.xmlEscaped + "\n"
            indentLevel -= 1
            xml += indent() + "</script>\n"
            indentLevel -= 1
            xml += indent() + "</onexit>\n"
        }
        for section in [StandardBoilerplateSection.internal, .onSuspend, .onResume] {
            if let content = sections[section] {
                xml += indent() + "<fsm:section name=\"\(section.rawValue)\"><![CDATA[\n"
                xml += content
                if !content.hasSuffix("\n") { xml += "\n" }
                xml += indent() + "]]></fsm:section>\n"
            }
        }
        return xml
    }

    /// Generate an `<invoke>` element for the given invocation.
    ///
    /// - Parameter invocation: The invocation to serialise.
    /// - Returns: The `<invoke .../>` XML string.
    private func generateInvocation(_ invocation: Invocation) -> String {
        var xml = indent() + "<invoke type=\"\(invocation.type.xmlEscaped)\""
        if let src = invocation.src {
            xml += " src=\"\(src.xmlEscaped)\""
        }
        if let id = invocation.id {
            xml += " id=\"\(id.xmlEscaped)\""
        }
        if invocation.autoForward {
            xml += " autoforward=\"true\""
        }
        xml += "/>\n"
        return xml
    }

    /// Return `true` if the state has any content that requires a closing tag.
    ///
    /// Content includes non-empty activity sections, invocations, and outgoing transitions.
    ///
    /// - Parameters:
    ///   - state: The state to check.
    ///   - machine: The owning machine.
    /// - Returns: `true` if the state element must have a body.
    private func hasStateContent(_ state: State, machine: Machine) -> Bool {
        // Check if state has onentry/onexit actions
        let sections = machine.stateActivities(for: state.id)
        if sections.values.contains(where: { !$0.isEmpty }) {
            return true
        }

        // Check if state has invocations
        if let scxmlBoilerplate = machine.boilerplate as? SCXMLBoilerplate,
            let invocations = scxmlBoilerplate.invocations[state.id.uuidString],
            !invocations.isEmpty {
            return true
        }

        // Check if state has transitions
        for transitionID in machine.llfsm.transitions {
            if let transition = machine.llfsm.transitionMap[transitionID],
                transition.source == state.id {
                return true
            }
        }

        return false
    }

    /// Generate the `<transition>` element XML for the given transition.
    ///
    /// - Parameters:
    ///   - transition: The transition to serialise.
    ///   - machine: The owning machine (for metadata and target state name lookups).
    /// - Returns: The `<transition .../>` or `<transition ...>...</transition>` XML string.
    /// - Throws: Error if executable action generation fails.
    private func generateTransition(_ transition: Transition, machine: Machine) throws -> String {
        var xml = indent() + "<transition"

        // Read metadata from boilerplate
        guard let scxmlBoilerplate = machine.boilerplate as? SCXMLBoilerplate else {
            // No SCXML metadata, generate basic transition
            return try generateBasicTransition(transition, machine: machine)
        }

        let metadata = scxmlBoilerplate.transitionMetadata[transition.id]

        // Event
        if let event = metadata?.event {
            xml += " event=\"\(event.xmlEscaped)\""
        }

        // Condition
        if let condition = metadata?.condition {
            xml += " cond=\"\(condition.xmlEscaped)\""
        } else if !transition.label.isEmpty {
            // Use label as condition if no explicit condition
            xml += " cond=\"\(transition.label.xmlEscaped)\""
        }

        // Target
        if let targetID = machine.llfsm.targetState(for: transition.id),
            let targetName = machine.llfsm.stateName(for: targetID) {
            xml += " target=\"\(targetName.xmlEscaped)\""
        }

        // Type
        if metadata?.type == .internal {
            xml += " type=\"internal\""
        }

        // Check for executable actions
        let hasActions = metadata?.actions.isEmpty == false

        if !hasActions {
            xml += "/>\n"
        } else {
            xml += ">\n"
            indentLevel += 1

            // Generate executable actions
            if let actions = metadata?.actions {
                for action in actions {
                    xml += try generateExecutableAction(action)
                }
            }

            indentLevel -= 1
            xml += indent() + "</transition>\n"
        }

        return xml
    }

    /// Generate the XML element for a single executable action.
    ///
    /// - Parameter action: The action to serialise.
    /// - Returns: The XML string for the action element.
    /// - Throws: Error if a nested action fails.
    private func generateExecutableAction(_ action: ExecutableAction) throws -> String {
        var xml = ""

        switch action {
        case .script(let content):
            xml += indent() + "<script>\n"
            indentLevel += 1
            xml += indent() + content.xmlEscaped + "\n"
            indentLevel -= 1
            xml += indent() + "</script>\n"

        case .assign(let location, let expr):
            xml +=
                indent()
                + "<assign location=\"\(location.xmlEscaped)\" expr=\"\(expr.xmlEscaped)\"/>\n"

        case .raise(let event):
            xml += indent() + "<raise event=\"\(event.xmlEscaped)\"/>\n"

        case .send(let event, let target, let delay):
            xml += indent() + "<send event=\"\(event.xmlEscaped)\""
            if let tgt = target {
                xml += " target=\"\(tgt.xmlEscaped)\""
            }
            if let dly = delay {
                xml += " delay=\"\(dly.xmlEscaped)\""
            }
            xml += "/>\n"

        case .log(let expr, let label):
            xml += indent() + "<log expr=\"\(expr.xmlEscaped)\""
            if let lbl = label {
                xml += " label=\"\(lbl.xmlEscaped)\""
            }
            xml += "/>\n"

        case .if(let condition, let thenActions, let elseActions):
            xml += indent() + "<if cond=\"\(condition.xmlEscaped)\">\n"
            indentLevel += 1
            for act in thenActions {
                xml += try generateExecutableAction(act)
            }
            if let elseActs = elseActions, !elseActs.isEmpty {
                try generateElseChain(elseActs, into: &xml)
            }
            indentLevel -= 1
            xml += indent() + "</if>\n"

        case .forEach(let array, let item, let index, let actions):
            xml += indent() + "<foreach array=\"\(array.xmlEscaped)\" item=\"\(item.xmlEscaped)\""
            if let idx = index {
                xml += " index=\"\(idx.xmlEscaped)\""
            }
            xml += ">\n"
            indentLevel += 1
            for act in actions {
                xml += try generateExecutableAction(act)
            }
            indentLevel -= 1
            xml += indent() + "</foreach>\n"

        case .cancel(let sendId):
            xml += indent() + "<cancel sendid=\"\(sendId.xmlEscaped)\"/>\n"
        }

        return xml
    }

    /// Flatten a nested `.if` chain into sibling `<elseif>` and `<else/>` markers.
    ///
    /// Per W3C SCXML, `<elseif cond="..."/>` and `<else/>` are self-closing sibling markers
    /// within `<if>`, not nested elements. This method recursively flattens the internal
    /// representation (nested `.if` in `elseActions`) into the correct XML structure.
    ///
    /// - Parameters:
    ///   - elseActions: The else branch actions to flatten.
    ///   - xml: The output string to append to.
    /// - Throws: Error if action generation fails.
    private func generateElseChain(_ elseActions: [ExecutableAction], into xml: inout String) throws {
        // Check if the else branch is a single nested .if (i.e., an elseif chain)
        if elseActions.count == 1,
           case .if(let elseIfCond, let elseIfThen, let elseIfElse) = elseActions[0] {
            // Emit <elseif cond="..."/> as self-closing sibling marker
            indentLevel -= 1
            xml += indent() + "<elseif cond=\"\(elseIfCond.xmlEscaped)\"/>\n"
            indentLevel += 1
            for act in elseIfThen {
                xml += try generateExecutableAction(act)
            }
            // Recurse for further elseif/else
            if let nextElse = elseIfElse, !nextElse.isEmpty {
                try generateElseChain(nextElse, into: &xml)
            }
        } else {
            // Emit <else/> as self-closing sibling marker
            indentLevel -= 1
            xml += indent() + "<else/>\n"
            indentLevel += 1
            for act in elseActions {
                xml += try generateExecutableAction(act)
            }
        }
    }

}

// MARK: - Legacy and Generic Boilerplate Generation

/// Extension providing helpers for generic machine generation and legacy C boilerplate serialisation.
private extension SCXMLWriter {
    /// Generate an `<fsm:boilerplate>` element from a `CBoilerplate` for C/C++ round-trip conversion.
    ///
    /// - Parameter cBoilerplate: The C boilerplate whose sections will be serialised.
    /// - Returns: The `<fsm:boilerplate>...</fsm:boilerplate>` XML string.
    func generateFSMLibBoilerplate(_ cBoilerplate: CBoilerplate) -> String {
        var xml = ""

        xml += indent() + "<fsm:boilerplate>\n"
        indentLevel += 1

        // Include path
        if let includePath = cBoilerplate.sections[.includePath], !includePath.isEmpty {
            xml += indent() + "<fsm:includePath><![CDATA[\n"
            xml += includePath
            if !includePath.hasSuffix("\n") { xml += "\n" }
            xml += indent() + "]]></fsm:includePath>\n"
        }

        // Includes
        if let includes = cBoilerplate.sections[.includes], !includes.isEmpty {
            xml += indent() + "<fsm:includes><![CDATA[\n"
            xml += includes
            if !includes.hasSuffix("\n") { xml += "\n" }
            xml += indent() + "]]></fsm:includes>\n"
        }

        // Variables
        if let variables = cBoilerplate.sections[.variables], !variables.isEmpty {
            xml += indent() + "<fsm:variables><![CDATA[\n"
            xml += variables
            if !variables.hasSuffix("\n") { xml += "\n" }
            xml += indent() + "]]></fsm:variables>\n"
        }

        // Functions
        if let functions = cBoilerplate.sections[.functions], !functions.isEmpty {
            xml += indent() + "<fsm:functions><![CDATA[\n"
            xml += functions
            if !functions.hasSuffix("\n") { xml += "\n" }
            xml += indent() + "]]></fsm:functions>\n"
        }

        indentLevel -= 1
        xml += indent() + "</fsm:boilerplate>\n"

        return xml
    }

    /// Generate basic SCXML from a non-SCXML machine using only standard boilerplate sections.
    ///
    /// - Parameter machine: The machine to serialise (must have a non-SCXML boilerplate).
    /// - Returns: The SCXML XML string.
    /// - Throws: Error if state generation fails.
    func generateFromGenericMachine(_ machine: Machine) throws -> String {
        // Generate basic SCXML from non-SCXML machine
        indentLevel = 0
        var xml = ""

        xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<scxml xmlns=\"http://www.w3.org/2005/07/scxml\""
        xml += " xmlns:fsm=\"http://mipal.net.au/fsmlib\""
        xml += " version=\"1.0\" datamodel=\"null\""

        if let initialState = machine.llfsm.states.first,
            let initialStateName = machine.llfsm.stateName(for: initialState) {
            xml += " initial=\"\(initialStateName.xmlEscaped)\""
        }

        xml += ">\n"
        indentLevel += 1

        // Embed machine boilerplate sections if they exist
        let machineSections = machine.language.extractSections(from: machine.boilerplate)
        if !machineSections.isEmpty {
            xml += generateFSMLibBoilerplateFromSections(machineSections)
        }

        for stateID in machine.llfsm.states {
            guard let state = machine.llfsm.stateMap[stateID] else { continue }
            xml += try generateStateWithActivities(state, machine: machine)
        }

        indentLevel -= 1
        xml += "</scxml>\n"

        return xml
    }

    /// Generate a state with activities from a generic (non-SCXML) machine.
    ///
    /// This extracts activities from state boilerplate via the language binding.
    ///
    /// - Parameters:
    ///   - state: The state to serialise.
    ///   - machine: The owning machine (non-SCXML).
    /// - Returns: The state XML string.
    /// - Throws: Error if transition generation fails.
    func generateStateWithActivities(_ state: State, machine: Machine) throws -> String {
        let sections = machine.stateActivities(for: state.id)
        let hasActivities = sections.values.contains(where: { !$0.isEmpty })
        let hasTransitions = machine.llfsm.transitions.contains { transitionID in
            guard let transition = machine.llfsm.transitionMap[transitionID] else { return false }
            return transition.source == state.id
        }

        var xml = indent() + "<state id=\"\(state.name.xmlEscaped)\""
        if !hasActivities && !hasTransitions {
            xml += "/>\n"
            return xml
        }

        xml += ">\n"
        indentLevel += 1
        xml += generateCDATAActivities(sections)
        for transitionID in machine.llfsm.transitions {
            guard let transition = machine.llfsm.transitionMap[transitionID],
                transition.source == state.id
            else { continue }
            xml += try generateBasicTransition(transition, machine: machine)
        }
        indentLevel -= 1
        xml += indent() + "</state>\n"
        return xml
    }

    /// Generate CDATA-wrapped activity sections (`<onentry>`, `<onexit>`, FSMLib sections).
    ///
    /// Used for generic (non-SCXML) machines where CDATA wrapping is appropriate.
    ///
    /// - Parameter sections: The activity sections dictionary to serialise.
    /// - Returns: The XML string for all non-empty activity sections.
    func generateCDATAActivities(_ sections: [StandardBoilerplateSection: String]) -> String {
        var xml = ""
        if let onEntry = sections[.onEntry], !onEntry.isEmpty {
            xml += indent() + "<onentry>\n"
            indentLevel += 1
            xml += indent() + "<script><![CDATA[\n"
            xml += onEntry
            if !onEntry.hasSuffix("\n") { xml += "\n" }
            xml += indent() + "]]></script>\n"
            indentLevel -= 1
            xml += indent() + "</onentry>\n"
        }
        if let onExit = sections[.onExit], !onExit.isEmpty {
            xml += indent() + "<onexit>\n"
            indentLevel += 1
            xml += indent() + "<script><![CDATA[\n"
            xml += onExit
            if !onExit.hasSuffix("\n") { xml += "\n" }
            xml += indent() + "]]></script>\n"
            indentLevel -= 1
            xml += indent() + "</onexit>\n"
        }
        for section in [StandardBoilerplateSection.internal, .onSuspend, .onResume] {
            if let content = sections[section] {
                xml += indent() + "<fsm:section name=\"\(section.rawValue)\"><![CDATA[\n"
                xml += content
                if !content.hasSuffix("\n") { xml += "\n" }
                xml += indent() + "]]></fsm:section>\n"
            }
        }
        return xml
    }

    /// Generate a minimal `<state>` element with only transitions and no SCXML metadata.
    ///
    /// - Parameters:
    ///   - state: The state to serialise.
    ///   - machine: The owning machine.
    /// - Returns: The state XML string.
    /// - Throws: Error if transition generation fails.
    func generateBasicState(_ state: State, machine: Machine) throws -> String {
        var xml = indent() + "<state id=\"\(state.name.xmlEscaped)\""

        let hasContent = hasStateContent(state, machine: machine)
        if !hasContent {
            xml += "/>\n"
            return xml
        }

        xml += ">\n"
        indentLevel += 1

        // Transitions
        for transitionID in machine.llfsm.transitions {
            guard let transition = machine.llfsm.transitionMap[transitionID],
                transition.source == state.id
            else {
                continue
            }
            xml += try generateBasicTransition(transition, machine: machine)
        }

        indentLevel -= 1
        xml += indent() + "</state>\n"

        return xml
    }

    /// Generate a minimal `<transition>` element with condition and target only.
    ///
    /// - Parameters:
    ///   - transition: The transition to serialise.
    ///   - machine: The owning machine (for target state name lookup).
    /// - Returns: The `<transition .../>` XML string.
    /// - Throws: Unused; declared for API consistency.
    func generateBasicTransition(_ transition: Transition, machine: Machine) throws -> String {
        var xml = indent() + "<transition"

        // Use label as condition if present
        if !transition.label.isEmpty {
            xml += " cond=\"\(transition.label.xmlEscaped)\""
        }

        // Target
        if let targetID = machine.llfsm.targetState(for: transition.id),
            let targetName = machine.llfsm.stateName(for: targetID) {
            xml += " target=\"\(targetName.xmlEscaped)\""
        }

        xml += "/>\n"
        return xml
    }
}

// MARK: - String XML Escaping

/// Extension on `String` providing XML character-escaping utilities for SCXML generation.
extension String {
    /// Return the string with XML special characters replaced by their entity references.
    fileprivate var xmlEscaped: String {
        var result = self
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }
}
