//
//  SCXMLWriter.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation

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

    private var indentLevel = 0
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
        var xml = ""

        // XML declaration
        xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"

        // SCXML root element
        xml += "<scxml"
        xml += " xmlns=\"http://www.w3.org/2005/07/scxml\""
        xml += " version=\"\(scxmlBoilerplate.scxmlVersion)\""
        xml += " datamodel=\"\(scxmlBoilerplate.datamodel)\""
        xml += " binding=\"\(scxmlBoilerplate.binding)\""

        if let name = scxmlBoilerplate.name {
            xml += " name=\"\(name.xmlEscaped)\""
        }

        // Initial state
        if let initialState = machine.llfsm.states.first,
            let initialStateName = machine.llfsm.stateName(for: initialState)
        {
            xml += " initial=\"\(initialStateName.xmlEscaped)\""
        }

        xml += ">\n"
        indentLevel += 1

        // Datamodel
        if !scxmlBoilerplate.dataDeclarations.isEmpty {
            xml += indent() + "<datamodel>\n"
            indentLevel += 1
            for decl in scxmlBoilerplate.dataDeclarations {
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
        }

        // Initial script
        if let script = scxmlBoilerplate.initialScript, !script.isEmpty {
            xml += indent() + "<script>\n"
            indentLevel += 1
            xml += indent() + script.xmlEscaped + "\n"
            indentLevel -= 1
            xml += indent() + "</script>\n"
        }

        // States
        for stateID in machine.llfsm.states {
            guard let state = machine.llfsm.stateMap[stateID] else { continue }
            xml += try generateState(state, machine: machine)
        }

        indentLevel -= 1
        xml += "</scxml>\n"

        return xml
    }

    // MARK: - Private Methods

    private func indent() -> String {
        String(repeating: indentString, count: indentLevel)
    }

    private func generateFromGenericMachine(_ machine: Machine) throws -> String {
        // Generate basic SCXML from non-SCXML machine
        var boilerplate = SCXMLBoilerplate()
        boilerplate.name = "Machine"
        boilerplate.datamodel = "null"

        indentLevel = 0
        var xml = ""

        xml += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<scxml xmlns=\"http://www.w3.org/2005/07/scxml\" version=\"1.0\" datamodel=\"null\""

        if let initialState = machine.llfsm.states.first,
            let initialStateName = machine.llfsm.stateName(for: initialState)
        {
            xml += " initial=\"\(initialStateName.xmlEscaped)\""
        }

        xml += ">\n"
        indentLevel += 1

        for stateID in machine.llfsm.states {
            guard let state = machine.llfsm.stateMap[stateID] else { continue }
            xml += try generateState(state, machine: machine)
        }

        indentLevel -= 1
        xml += "</scxml>\n"

        return xml
    }

    private func generateState(_ state: State, machine: Machine) throws -> String {
        var xml = ""
        // Read metadata from boilerplate
        guard let scxmlBoilerplate = machine.boilerplate as? SCXMLBoilerplate else {
            // No SCXML metadata, generate as basic state
            return try generateBasicState(state, machine: machine)
        }

        let metadata = scxmlBoilerplate.stateMetadata[state.id]
        let isFinal = metadata?.isFinal ?? false
        let isParallel = metadata?.isParallel ?? false
        let isHistory = metadata?.historyType != nil

        // State element
        xml += indent()
        if isFinal {
            xml += "<final"
        } else if isParallel {
            xml += "<parallel"
        } else if isHistory {
            xml += "<history"
        } else {
            xml += "<state"
        }

        xml += " id=\"\(state.name.xmlEscaped)\""

        // History type
        if let historyType = metadata?.historyType {
            xml += " type=\"\(historyType.rawValue)\""
        }

        // Initial child
        if let initialChild = metadata?.initialChild,
            let initialChildName = machine.llfsm.stateName(for: initialChild)
        {
            xml += " initial=\"\(initialChildName.xmlEscaped)\""
        }

        // Layout metadata (custom attributes for visual editors)
        if let layout = machine.stateLayout[state.id] {
            let x = layout.openLayout.topLeft.x
            let y = layout.openLayout.topLeft.y
            let width = layout.openLayout.dimensions.w
            let height = layout.openLayout.dimensions.h
            xml +=
                " se:x=\"\(Int(x))\" se:y=\"\(Int(y))\" se:width=\"\(Int(width))\" se:height=\"\(Int(height))\""
        }

        let hasChildren = metadata?.childStates != nil && metadata?.childStates?.isEmpty == false
        let hasContent = hasStateContent(state, machine: machine)

        if !hasChildren && !hasContent {
            xml += "/>\n"
            return xml
        }

        xml += ">\n"
        indentLevel += 1

        // OnEntry
        if let actions = machine.activities.actions[state.id], !actions.onEntry.isEmpty {
            xml += indent() + "<onentry>\n"
            indentLevel += 1
            xml += indent() + "<script>\n"
            indentLevel += 1
            xml += indent() + actions.onEntry.xmlEscaped + "\n"
            indentLevel -= 1
            xml += indent() + "</script>\n"
            indentLevel -= 1
            xml += indent() + "</onentry>\n"
        }

        // OnExit
        if let actions = machine.activities.actions[state.id], !actions.onExit.isEmpty {
            xml += indent() + "<onexit>\n"
            indentLevel += 1
            xml += indent() + "<script>\n"
            indentLevel += 1
            xml += indent() + actions.onExit.xmlEscaped + "\n"
            indentLevel -= 1
            xml += indent() + "</script>\n"
            indentLevel -= 1
            xml += indent() + "</onexit>\n"
        }

        // Invocations
        if let scxmlBoilerplate = machine.boilerplate as? SCXMLBoilerplate,
            let invocations = scxmlBoilerplate.invocations[state.id.uuidString]
        {
            for invocation in invocations {
                xml += indent() + "<invoke type=\"\(invocation.type.xmlEscaped)\""
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
            }
        }

        // Transitions
        for transitionID in machine.llfsm.transitions {
            guard let transition = machine.llfsm.transitionMap[transitionID],
                transition.source == state.id
            else {
                continue
            }
            xml += try generateTransition(transition, machine: machine)
        }

        // Child states (recursive)
        if let childIDs = metadata?.childStates {
            for childID in childIDs {
                if let childState = machine.llfsm.stateMap[childID] {
                    xml += try generateState(childState, machine: machine)
                }
            }
        }

        indentLevel -= 1
        xml += indent()
        if isFinal {
            xml += "</final>\n"
        } else if isParallel {
            xml += "</parallel>\n"
        } else if isHistory {
            xml += "</history>\n"
        } else {
            xml += "</state>\n"
        }

        return xml
    }

    private func hasStateContent(_ state: State, machine: Machine) -> Bool {
        // Check if state has onentry/onexit actions
        if let actions = machine.activities.actions[state.id] {
            if !actions.onEntry.isEmpty || !actions.onExit.isEmpty {
                return true
            }
        }

        // Check if state has invocations
        if let scxmlBoilerplate = machine.boilerplate as? SCXMLBoilerplate,
            let invocations = scxmlBoilerplate.invocations[state.id.uuidString],
            !invocations.isEmpty
        {
            return true
        }

        // Check if state has transitions
        for transitionID in machine.llfsm.transitions {
            if let transition = machine.llfsm.transitionMap[transitionID],
                transition.source == state.id
            {
                return true
            }
        }

        return false
    }

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
            let targetName = machine.llfsm.stateName(for: targetID)
        {
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
                indentLevel -= 1
                xml += indent() + "<else>\n"
                indentLevel += 1
                for act in elseActs {
                    xml += try generateExecutableAction(act)
                }
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

    private func generateBasicState(_ state: State, machine: Machine) throws -> String {
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

    private func generateBasicTransition(_ transition: Transition, machine: Machine) throws
        -> String
    {
        var xml = indent() + "<transition"

        // Use label as condition if present
        if !transition.label.isEmpty {
            xml += " cond=\"\(transition.label.xmlEscaped)\""
        }

        // Target
        if let targetID = machine.llfsm.targetState(for: transition.id),
            let targetName = machine.llfsm.stateName(for: targetID)
        {
            xml += " target=\"\(targetName.xmlEscaped)\""
        }

        xml += "/>\n"
        return xml
    }
}

// MARK: - String XML Escaping

extension String {
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
