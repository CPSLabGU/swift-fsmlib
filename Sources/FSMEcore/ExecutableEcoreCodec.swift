import ECore
import EMFBase
import FSM
import Foundation

/// Machine codec for the executable LLFSM metamodel.
///
/// `ExecutableMachineCodec` converts `swift-fsmlib` machines into the legacy
/// typed LLFSM model used by the bundled generators and decodes those models
/// back into `Machine` values. It preserves unsupported source fragments as
/// opaque executable nodes so structural round-trips remain lossless for the
/// supported subset and conservative for everything else.
public struct ExecutableMachineCodec {
    /// Metamodel used for executable conversion.
    public let metamodel: ExecutableLLFSMMetamodel

    /// Arrangement codec used for the single-machine wrapper path.
    public let arrangementCodec: ExecutableArrangementCodec

    /// Create the executable machine codec.
    ///
    /// - Parameter metamodel: Loaded executable metamodel to use for
    ///   conversion.
    public init(metamodel: ExecutableLLFSMMetamodel) {
        self.metamodel = metamodel
        self.arrangementCodec = ExecutableArrangementCodec(metamodel: metamodel)
    }

    /// Encode a machine as an executable LLFSM arrangement.
    ///
    /// The executable legacy model is arrangement-based, so single-machine
    /// exports are wrapped in a one-instance arrangement.
    ///
    /// - Parameters:
    ///   - machine: Machine value to encode.
    ///   - name: Machine name to preserve in the executable model.
    ///   - arrangementName: Optional arrangement name. Defaults to `name`.
    ///   - resource: Resource that will own the encoded objects.
    /// - Returns: Root executable arrangement object.
    public func encode(
        _ machine: Machine,
        name: String,
        arrangementName: String? = nil,
        into resource: Resource
    ) async -> DynamicEObject {
        let instance = Instance(
            name: name,
            typeFile: name + MachineDirectoryWrapper.dottedSuffix,
            machine: machine
        )
        let arrangement = Arrangement(namedInstances: [instance])
        return await arrangementCodec.encode(
            arrangement,
            name: arrangementName ?? name,
            into: resource
        )
    }

    /// Decode a machine from an executable model object.
    ///
    /// - Parameters:
    ///   - object: Executable arrangement or state-machine object to decode.
    ///   - resource: Resource containing the executable graph.
    /// - Returns: Decoded machine name and machine value.
    /// - Throws: Throw an error if the executable graph is missing required
    ///   features.
    public func decode(_ object: DynamicEObject, from resource: Resource) async throws -> (name: String, machine: Machine) {
        if object.eClass.name == metamodel.arrangementClass.name {
            let arrangement = try await arrangementCodec.decode(object, from: resource)
            if let instance = arrangement.namedInstances.first {
                return (instance.name, instance.machine)
            }
            let stateMachineIDs = executableReferenceIDs(
                from: await resource.eGet(objectId: object.id, feature: "stateMachine")
            )
            if let stateMachineID = stateMachineIDs.first,
               let stateMachineObject = await resource.resolve(stateMachineID) as? DynamicEObject {
                let name = await resource.eGet(objectId: stateMachineID, feature: "name") as? String ?? "Machine"
                return (name, try await arrangementCodec.decodeStateMachine(stateMachineObject, from: resource))
            }
            throw ExecutableLLFSMMetamodelError.missingFeature("arrangement instances")
        }
        guard object.eClass.name == metamodel.stateMachineClass.name else {
            throw ExecutableLLFSMMetamodelError.missingFeature("StateMachine root")
        }
        let name = await resource.eGet(objectId: object.id, feature: "name") as? String ?? "Machine"
        return (name, try await arrangementCodec.decodeStateMachine(object, from: resource))
    }
}

/// Arrangement codec for the executable LLFSM metamodel.
///
/// `ExecutableArrangementCodec` converts arrangements into the executable LLFSM
/// object graph used by the bundled templates while preserving structural
/// information such as instance names, boilerplate sections, and layout data
/// through the additional executable fidelity classes.
public struct ExecutableArrangementCodec {
    /// Metamodel used for executable conversion.
    public let metamodel: ExecutableLLFSMMetamodel

    /// Create the executable arrangement codec.
    ///
    /// - Parameter metamodel: Loaded executable metamodel to use for
    ///   conversion.
    public init(metamodel: ExecutableLLFSMMetamodel) {
        self.metamodel = metamodel
    }

    /// Encode an arrangement into an executable object graph.
    ///
    /// - Parameters:
    ///   - arrangement: Arrangement value to encode.
    ///   - name: Arrangement name to store in the executable model.
    ///   - resource: Resource that will own the encoded objects.
    /// - Returns: Root executable arrangement object.
    public func encode(
        _ arrangement: Arrangement,
        name: String,
        into resource: Resource
    ) async -> DynamicEObject {
        var instanceIDs: [EUUID] = []
        var stateMachineIDs: [EUUID] = []

        for instance in arrangement.namedInstances {
            let encoded = await encodeStateMachine(instance.machine, name: instance.name, into: resource)
            stateMachineIDs.append(encoded.id)

            var instanceObject = DynamicEObject(eClass: metamodel.instanceClass)
            instanceObject.eSet("name", value: instance.name)
            instanceObject.eSet("typeFile", value: instance.typeFile)
            instanceObject.eSet("machine", value: encoded.id)
            await resource.register(instanceObject)
            instanceIDs.append(instanceObject.id)
        }

        var arrangementObject = DynamicEObject(eClass: metamodel.arrangementClass)
        arrangementObject.eSet("arrangementName", value: name)
        arrangementObject.eSet("instances", value: instanceIDs)
        arrangementObject.eSet("stateMachine", value: stateMachineIDs)
        await resource.add(arrangementObject)
        return arrangementObject
    }

    /// Decode an arrangement from an executable arrangement object.
    ///
    /// - Parameters:
    ///   - arrangementObject: Executable arrangement object.
    ///   - resource: Resource containing the executable graph.
    /// - Returns: Decoded arrangement value.
    /// - Throws: Throw an error if nested machine decoding fails.
    public func decode(_ arrangementObject: DynamicEObject, from resource: Resource) async throws -> Arrangement {
        let instanceIDs = executableReferenceIDs(
            from: await resource.eGet(objectId: arrangementObject.id, feature: "instances")
        )
        if !instanceIDs.isEmpty {
            var instances: [Instance] = []
            for instanceID in instanceIDs {
                let name = await resource.eGet(objectId: instanceID, feature: "name") as? String ?? ""
                let typeFile = await resource.eGet(objectId: instanceID, feature: "typeFile") as? String ?? ""
                guard let machineID = await resource.eGet(objectId: instanceID, feature: "machine") as? EUUID,
                      let machineObject = await resource.resolve(machineID) as? DynamicEObject else {
                    continue
                }
                let machine = try await decodeStateMachine(machineObject, from: resource)
                instances.append(
                    Instance(
                        name: name.isEmpty ? machineObject.eGet("name") as? String ?? "Machine" : name,
                        typeFile: typeFile.isEmpty ? name + MachineDirectoryWrapper.dottedSuffix : typeFile,
                        machine: machine
                    )
                )
            }
            return Arrangement(namedInstances: instances)
        }

        let machineIDs = executableReferenceIDs(
            from: await resource.eGet(objectId: arrangementObject.id, feature: "stateMachine")
        )
        let instances = try await machineIDs.asyncMap { machineID in
            guard let machineObject = await resource.resolve(machineID) as? DynamicEObject else {
                throw ExecutableLLFSMMetamodelError.missingFeature("stateMachine")
            }
            let machineName = await resource.eGet(objectId: machineID, feature: "name") as? String ?? "Machine"
            let machine = try await decodeStateMachine(machineObject, from: resource)
            return Instance(
                name: machineName,
                typeFile: machineName + MachineDirectoryWrapper.dottedSuffix,
                machine: machine
            )
        }
        return Arrangement(namedInstances: instances)
    }

    fileprivate func decodeStateMachine(_ machineObject: DynamicEObject, from resource: Resource) async throws -> Machine {
        let languageName = await resource.eGet(objectId: machineObject.id, feature: "language") as? String ?? ""
        let language: any LanguageBinding = languageBinding(for: languageName)

        guard let initialStateID = await resource.eGet(objectId: machineObject.id, feature: "initialState") as? EUUID else {
            throw ExecutableLLFSMMetamodelError.missingFeature("initialState")
        }

        let stateIDs = executableReferenceIDs(
            from: await resource.eGet(objectId: machineObject.id, feature: "states")
        )
        let orderedStateIDs = [initialStateID] + stateIDs

        var eObjectToStateID: [EUUID: StateID] = [:]
        var states: [State] = []
        for objectID in orderedStateIDs {
            let stateName = await resource.eGet(objectId: objectID, feature: "stateName") as? String ?? ""
            let state = State(name: stateName)
            eObjectToStateID[objectID] = state.id
            states.append(state)
        }

        let transitionObjectIDs = executableReferenceIDs(
            from: await resource.eGet(objectId: machineObject.id, feature: "transitions")
        )
        var transitions: [Transition] = []
        var executableTransitionIDs: [EUUID: TransitionID] = [:]

        for transitionObjectID in transitionObjectIDs {
            let label = try await transitionLabel(for: transitionObjectID, from: resource)
            let sourceObjectID = await resource.eGet(objectId: transitionObjectID, feature: "sourceState") as? EUUID
            let targetObjectID = await resource.eGet(objectId: transitionObjectID, feature: "targetState") as? EUUID
            let transition = Transition(
                label: label,
                source: sourceObjectID.flatMap { eObjectToStateID[$0] } ?? StateID(uuid: UUID_NULL),
                target: targetObjectID.flatMap { eObjectToStateID[$0] } ?? StateID(uuid: UUID_NULL)
            )
            transitions.append(transition)
            executableTransitionIDs[transitionObjectID] = transition.id
        }

        var stateBoilerplateByState: [StateID: any Boilerplate] = [:]
        let stateBoilerplateEntryIDs = executableReferenceIDs(
            from: await resource.eGet(objectId: machineObject.id, feature: "stateBoilerplates")
        )
        var boilerplateSectionsByState: [EUUID: [StandardBoilerplateSection: String]] = [:]
        for entryID in stateBoilerplateEntryIDs {
            guard let stateObjectID = await resource.eGet(objectId: entryID, feature: "state") as? EUUID,
                  let boilerplateID = await resource.eGet(objectId: entryID, feature: "boilerplate") as? EUUID else {
                continue
            }
            boilerplateSectionsByState[stateObjectID] = await decodeBoilerplateSections(boilerplateID, from: resource)
        }

        let suspendStateObjectID = await resource.eGet(objectId: machineObject.id, feature: "suspendState") as? EUUID
        let suspendStateID = suspendStateObjectID.flatMap { eObjectToStateID[$0] }
        let llfsm = LLFSM(states: states, transitions: transitions, suspendState: suspendStateID)
        let machineBoilerplateID = await resource.eGet(objectId: machineObject.id, feature: "boilerplate") as? EUUID
        let machineBoilerplate = await decodeMachineBoilerplate(machineBoilerplateID, from: resource, language: language)

        var machine = Machine()
        machine.language = language
        machine.llfsm = llfsm
        machine.boilerplate = machineBoilerplate

        for objectID in orderedStateIDs {
            guard let stateID = eObjectToStateID[objectID],
                  let stateName = llfsm.stateName(for: stateID) else {
                continue
            }
            var sections = boilerplateSectionsByState[objectID] ?? [:]
            sections[.onEntry] = await decodeSection(feature: "onEntry", stateObjectID: objectID, from: resource)
            sections[.onExit] = await decodeSection(feature: "onExit", stateObjectID: objectID, from: resource)
            sections[.internal] = await decodeSection(feature: "internal", stateObjectID: objectID, from: resource)
            sections[.onSuspend] = await decodeSection(feature: "onSuspend", stateObjectID: objectID, from: resource)
            sections[.onResume] = await decodeSection(feature: "onResume", stateObjectID: objectID, from: resource)
            stateBoilerplateByState[stateID] = language.createStateBoilerplate(from: sections, stateName: stateName)
        }
        machine.stateBoilerplate = stateBoilerplateByState

        let stateLayoutEntryIDs = executableReferenceIDs(
            from: await resource.eGet(objectId: machineObject.id, feature: "stateLayouts")
        )
        var stateLayouts: StateLayouts = [:]
        for entryID in stateLayoutEntryIDs {
            guard let stateObjectID = await resource.eGet(objectId: entryID, feature: "state") as? EUUID,
                  let stateID = eObjectToStateID[stateObjectID],
                  let layoutID = await resource.eGet(objectId: entryID, feature: "layout") as? EUUID else {
                continue
            }
            stateLayouts[stateID] = await decodeStateLayout(layoutID, from: resource)
        }
        machine.stateLayout = stateLayouts

        let transitionLayoutEntryIDs = executableReferenceIDs(
            from: await resource.eGet(objectId: machineObject.id, feature: "transitionLayouts")
        )
        var transitionLayouts: TransitionLayouts = [:]
        for entryID in transitionLayoutEntryIDs {
            guard let transitionObjectID = await resource.eGet(objectId: entryID, feature: "transition") as? EUUID,
                  let transitionID = executableTransitionIDs[transitionObjectID],
                  let layoutID = await resource.eGet(objectId: entryID, feature: "layout") as? EUUID else {
                continue
            }
            transitionLayouts[transitionID] = await decodeTransitionLayout(layoutID, from: resource)
        }
        machine.transitionLayout = transitionLayouts

        if let windowLayoutID = await resource.eGet(objectId: machineObject.id, feature: "windowLayout") as? EUUID,
           let windowLayoutString = await resource.eGet(objectId: windowLayoutID, feature: "data") as? String,
           !windowLayoutString.isEmpty {
            machine.windowLayout = Data(base64Encoded: windowLayoutString)
        }

        return machine
    }

    private func encodeStateMachine(_ machine: Machine, name: String, into resource: Resource) async -> DynamicEObject {
        var variableCollector = ExecutableVariableCollector()
        let orderedStateIDs = machine.llfsm.states
        let parsedStates: [(StateID, ParsedSections)] = orderedStateIDs.compactMap { stateID in
            guard machine.llfsm.stateName(for: stateID) != nil else {
                return nil
            }
            return (stateID, ParsedSections(from: machine.stateActivities(for: stateID), collector: &variableCollector))
        }

        let parsedTransitions: [TransitionID: ExecutableBooleanNode] = Dictionary(uniqueKeysWithValues: machine.llfsm.transitions.compactMap { transitionID in
            guard let transition = machine.llfsm.transition(for: transitionID) else {
                return nil
            }
            return (transitionID, ExecutableParser.parseBoolean(transition.label, collector: &variableCollector) ?? .opaque(transition.label))
        })

        let integerVariables = await encodeIntegerVariables(variableCollector.integerVariables, into: resource)
        let booleanVariables = await encodeBooleanVariables(variableCollector.booleanVariables, into: resource)
        let variableLookup = ExecutableVariableLookup(
            integerVariables: integerVariables.lookup,
            booleanVariables: booleanVariables.lookup,
            integerConstants: [:]
        )

        var encodedStates: [StateID: DynamicEObject] = [:]
        for (index, element) in parsedStates.enumerated() {
            guard let stateName = machine.llfsm.stateName(for: element.0) else {
                continue
            }
            var stateObject = DynamicEObject(
                eClass: index == 0 ? metamodel.initialStateClass : metamodel.stateClass
            )
            stateObject.eSet("stateName", value: stateName)
            try? await encodeSections(element.1, on: &stateObject, lookup: variableLookup, into: resource, language: machine.language.name)
            await resource.register(stateObject)
            encodedStates[element.0] = stateObject
        }

        var encodedTransitions: [TransitionID: DynamicEObject] = [:]
        for transitionID in machine.llfsm.transitions {
            guard let transition = machine.llfsm.transition(for: transitionID),
                  let source = encodedStates[transition.source],
                  let target = encodedStates[transition.target],
                  let condition = parsedTransitions[transitionID] else {
                continue
            }
            var transitionObject = DynamicEObject(eClass: metamodel.transitionClass)
            transitionObject.eSet("sourceState", value: source.id)
            transitionObject.eSet("targetState", value: target.id)
            let conditionObject = await encodeBooleanExpression(condition, lookup: variableLookup, into: resource, language: machine.language.name)
            transitionObject.eSet("booleanExpression", value: conditionObject.id)
            await resource.register(transitionObject)
            encodedTransitions[transitionID] = transitionObject
        }

        var stateMachineObject = DynamicEObject(eClass: metamodel.stateMachineClass)
        stateMachineObject.eSet("name", value: name)
        stateMachineObject.eSet("language", value: machine.language.name)
        if let initialState = orderedStateIDs.first, let initialStateObject = encodedStates[initialState] {
            stateMachineObject.eSet("initialState", value: initialStateObject.id)
        }
        stateMachineObject.eSet("states", value: orderedStateIDs.dropFirst().compactMap { encodedStates[$0]?.id })
        stateMachineObject.eSet("transitions", value: machine.llfsm.transitions.compactMap { encodedTransitions[$0]?.id })
        if let suspendState = machine.llfsm.suspendState,
           let suspendStateObject = encodedStates[suspendState] {
            stateMachineObject.eSet("suspendState", value: suspendStateObject.id)
        }
        if let integerList = integerVariables.listID {
            stateMachineObject.eSet("localVariables", value: integerList)
        }
        if let booleanList = booleanVariables.listID {
            stateMachineObject.eSet("booleanLocalVariables", value: booleanList)
        }
        let copies = await encodeIntegerConstant(1, into: resource)
        stateMachineObject.eSet("copies", value: copies.id)
        let machineBoilerplate = await encodeBoilerplate(machine.boilerplate, language: machine.language, into: resource)
        stateMachineObject.eSet("boilerplate", value: machineBoilerplate.id)

        let stateBoilerplateIDs = await encodeStateBoilerplates(machine, stateObjects: encodedStates, into: resource)
        if !stateBoilerplateIDs.isEmpty {
            stateMachineObject.eSet("stateBoilerplates", value: stateBoilerplateIDs)
        }

        let stateLayoutIDs = await encodeStateLayouts(machine.stateLayout, stateObjects: encodedStates, into: resource)
        if !stateLayoutIDs.isEmpty {
            stateMachineObject.eSet("stateLayouts", value: stateLayoutIDs)
        }

        let transitionLayoutIDs = await encodeTransitionLayouts(machine.transitionLayout, transitionObjects: encodedTransitions, into: resource)
        if !transitionLayoutIDs.isEmpty {
            stateMachineObject.eSet("transitionLayouts", value: transitionLayoutIDs)
        }

        if let windowLayout = machine.windowLayout {
            var windowLayoutObject = DynamicEObject(eClass: metamodel.windowLayoutClass)
            windowLayoutObject.eSet("data", value: windowLayout.base64EncodedString())
            await resource.register(windowLayoutObject)
            stateMachineObject.eSet("windowLayout", value: windowLayoutObject.id)
        }

        await resource.register(stateMachineObject)
        return stateMachineObject
    }

    private func encodeSections(
        _ sections: ParsedSections,
        on stateObject: inout DynamicEObject,
        lookup: ExecutableVariableLookup,
        into resource: Resource,
        language: String
    ) async throws {
        let mapping: [(String, [ExecutableStatementNode], EClass)] = [
            ("onEntry", sections.onEntry, metamodel.onEntrySectionClass),
            ("onExit", sections.onExit, metamodel.onExitSectionClass),
            ("internal", sections.internalCode, metamodel.internalSectionClass),
            ("onSuspend", sections.onSuspend, metamodel.onSuspendSectionClass),
            ("onResume", sections.onResume, metamodel.onResumeSectionClass),
        ]

        for (feature, statements, eClass) in mapping where !statements.isEmpty {
            var sectionObject = DynamicEObject(eClass: eClass)
            let statementObjects = await statements.asyncMap { statement in
                await encodeStatement(statement, lookup: lookup, into: resource, language: language)
            }
            sectionObject.eSet("statements", value: statementObjects.map(\.id))
            await resource.register(sectionObject)
            stateObject.eSet(feature, value: sectionObject.id)
        }
    }

    private func encodeStatement(
        _ statement: ExecutableStatementNode,
        lookup: ExecutableVariableLookup,
        into resource: Resource,
        language: String
    ) async -> DynamicEObject {
        switch statement {
        case .outputLine(let line):
            var object = DynamicEObject(eClass: metamodel.outputLineClass)
            object.eSet("theLine", value: line)
            await resource.register(object)
            return object
        case .assignInteger(let variable, let expression):
            var object = DynamicEObject(eClass: metamodel.assignmentIntegerClass)
            object.eSet("variable", value: lookup.integerVariables[variable]?.id)
            let expressionObject = await encodeArithmeticExpression(expression, lookup: lookup, into: resource, language: language)
            object.eSet("anArithmeticExpression", value: expressionObject.id)
            await resource.register(object)
            return object
        case .assignBoolean(let variable, let expression):
            var object = DynamicEObject(eClass: metamodel.assignmentBooleanClass)
            object.eSet("variable", value: lookup.booleanVariables[variable]?.id)
            let expressionObject = await encodeBooleanExpression(expression, lookup: lookup, into: resource, language: language)
            object.eSet("aBooleanExpression", value: expressionObject.id)
            await resource.register(object)
            return object
        case .opaque(let code):
            var object = DynamicEObject(eClass: metamodel.opaqueStatementClass)
            object.eSet("code", value: code)
            object.eSet("language", value: language)
            await resource.register(object)
            return object
        }
    }

    private func encodeBooleanExpression(
        _ expression: ExecutableBooleanNode,
        lookup: ExecutableVariableLookup,
        into resource: Resource,
        language: String
    ) async -> DynamicEObject {
        switch expression {
        case .constant(let value):
            var object = DynamicEObject(eClass: metamodel.booleanConstantClass)
            object.eSet("aBooleanValue", value: value)
            await resource.register(object)
            return object
        case .variable(let name):
            var object = DynamicEObject(eClass: metamodel.booleanVariableReferenceClass)
            object.eSet("theVariable", value: lookup.booleanVariables[name]?.id)
            await resource.register(object)
            return object
        case .not(let operand):
            var object = DynamicEObject(eClass: metamodel.notExpressionClass)
            let operandObject = await encodeBooleanExpression(operand, lookup: lookup, into: resource, language: language)
            object.eSet("theExpression", value: operandObject.id)
            await resource.register(object)
            return object
        case .and(let lhs, let rhs):
            var object = DynamicEObject(eClass: metamodel.andExpressionClass)
            let left = await encodeBooleanExpression(lhs, lookup: lookup, into: resource, language: language)
            let right = await encodeBooleanExpression(rhs, lookup: lookup, into: resource, language: language)
            object.eSet("leftExpression", value: left.id)
            object.eSet("rightExpression", value: right.id)
            await resource.register(object)
            return object
        case .or(let lhs, let rhs):
            var object = DynamicEObject(eClass: metamodel.orExpressionClass)
            let left = await encodeBooleanExpression(lhs, lookup: lookup, into: resource, language: language)
            let right = await encodeBooleanExpression(rhs, lookup: lookup, into: resource, language: language)
            object.eSet("leftExpression", value: left.id)
            object.eSet("rightExpression", value: right.id)
            await resource.register(object)
            return object
        case .equal(let lhs, let rhs):
            var object = DynamicEObject(eClass: metamodel.equalExpressionClass)
            let left = await encodeArithmeticExpression(lhs, lookup: lookup, into: resource, language: language)
            let right = await encodeArithmeticExpression(rhs, lookup: lookup, into: resource, language: language)
            object.eSet("leftExpression", value: left.id)
            object.eSet("rightExpression", value: right.id)
            await resource.register(object)
            return object
        case .lessThan(let lhs, let rhs):
            var object = DynamicEObject(eClass: metamodel.lessThanExpressionClass)
            let left = await encodeArithmeticExpression(lhs, lookup: lookup, into: resource, language: language)
            let right = await encodeArithmeticExpression(rhs, lookup: lookup, into: resource, language: language)
            object.eSet("leftExpression", value: left.id)
            object.eSet("rightExpression", value: right.id)
            await resource.register(object)
            return object
        case .opaque(let code):
            var object = DynamicEObject(eClass: metamodel.opaqueExpressionClass)
            object.eSet("code", value: code)
            object.eSet("language", value: language)
            await resource.register(object)
            return object
        }
    }

    private func encodeArithmeticExpression(
        _ expression: ExecutableArithmeticNode,
        lookup: ExecutableVariableLookup,
        into resource: Resource,
        language: String
    ) async -> DynamicEObject {
        switch expression {
        case .integer(let value):
            return await encodeIntegerConstant(value, into: resource)
        case .variable(let name):
            var object = DynamicEObject(eClass: metamodel.integerVariableReferenceClass)
            object.eSet("theVariable", value: lookup.integerVariables[name]?.id)
            await resource.register(object)
            return object
        case .predefinedConstant(let name):
            var constantDefinition = DynamicEObject(eClass: metamodel.predefinedIntegerConstantClass)
            if let constant = lookup.integerConstants[name] {
                constantDefinition.eSet("listedIntegerConstant", value: constant.id)
            }
            await resource.register(constantDefinition)
            return constantDefinition
        case .addition(let lhs, let rhs):
            return await encodeBinaryArithmetic(lhs, rhs, eClassName: "AdditionExpression", lookup: lookup, into: resource, language: language)
        case .subtraction(let lhs, let rhs):
            return await encodeBinaryArithmetic(lhs, rhs, eClassName: "SubtractionExpression", lookup: lookup, into: resource, language: language)
        case .multiplication(let lhs, let rhs):
            return await encodeBinaryArithmetic(lhs, rhs, eClassName: "MultiplicationExpression", lookup: lookup, into: resource, language: language)
        case .modulus(let lhs, let rhs):
            return await encodeBinaryArithmetic(lhs, rhs, eClassName: "ModulusExpression", lookup: lookup, into: resource, language: language)
        case .opaque(let code):
            var object = DynamicEObject(eClass: metamodel.opaqueExpressionClass)
            object.eSet("code", value: code)
            object.eSet("language", value: language)
            await resource.register(object)
            return object
        }
    }

    private func encodeBinaryArithmetic(
        _ lhs: ExecutableArithmeticNode,
        _ rhs: ExecutableArithmeticNode,
        eClassName: String,
        lookup: ExecutableVariableLookup,
        into resource: Resource,
        language: String
    ) async -> DynamicEObject {
        let eClass = metamodel.package.getEClass(eClassName) ?? metamodel.opaqueExpressionClass
        var object = DynamicEObject(eClass: eClass)
        let left = await encodeArithmeticExpression(lhs, lookup: lookup, into: resource, language: language)
        let right = await encodeArithmeticExpression(rhs, lookup: lookup, into: resource, language: language)
        object.eSet("leftExpression", value: left.id)
        object.eSet("rightExpression", value: right.id)
        await resource.register(object)
        return object
    }

    private func encodeIntegerConstant(_ value: Int, into resource: Resource) async -> DynamicEObject {
        var object = DynamicEObject(eClass: metamodel.integerConstantClass)
        object.eSet("anIntegerValue", value: value)
        await resource.register(object)
        return object
    }

    private func encodeIntegerVariables(_ names: [String], into resource: Resource) async -> ExecutableVariableListEncoding {
        guard !names.isEmpty else {
            return ExecutableVariableListEncoding(listID: nil, lookup: [:])
        }

        var variableIDs: [EUUID] = []
        var lookup: [String: DynamicEObject] = [:]
        for name in names.sorted() {
            let lower = await encodeIntegerConstant(0, into: resource)
            let upper = await encodeIntegerConstant(100, into: resource)
            var variable = DynamicEObject(eClass: metamodel.integerVariableClass)
            variable.eSet("variableID", value: name)
            variable.eSet("theLowerBound", value: lower.id)
            variable.eSet("theUpperBound", value: upper.id)
            await resource.register(variable)
            variableIDs.append(variable.id)
            lookup[name] = variable
        }

        var list = DynamicEObject(eClass: metamodel.listOfIntegerVariablesClass)
        list.eSet("variables", value: variableIDs)
        await resource.register(list)
        return ExecutableVariableListEncoding(listID: list.id, lookup: lookup)
    }

    private func encodeBooleanVariables(_ names: [String], into resource: Resource) async -> ExecutableVariableListEncoding {
        guard !names.isEmpty else {
            return ExecutableVariableListEncoding(listID: nil, lookup: [:])
        }

        var variableIDs: [EUUID] = []
        var lookup: [String: DynamicEObject] = [:]
        for name in names.sorted() {
            var variable = DynamicEObject(eClass: metamodel.booleanVariableClass)
            variable.eSet("variableID", value: name)
            await resource.register(variable)
            variableIDs.append(variable.id)
            lookup[name] = variable
        }

        var list = DynamicEObject(eClass: metamodel.listOfBooleanVariablesClass)
        list.eSet("variables", value: variableIDs)
        await resource.register(list)
        return ExecutableVariableListEncoding(listID: list.id, lookup: lookup)
    }

    private func encodeBoilerplate(
        _ boilerplate: any Boilerplate,
        language: any LanguageBinding,
        into resource: Resource
    ) async -> DynamicEObject {
        let sections = language.extractSections(from: boilerplate)
        var object = DynamicEObject(eClass: metamodel.boilerplateClass)
        object.eSet("includePath", value: sections[.includePath] ?? "")
        object.eSet("includes", value: sections[.includes] ?? "")
        object.eSet("variables", value: sections[.variables] ?? "")
        object.eSet("functions", value: sections[.functions] ?? "")
        await resource.register(object)
        return object
    }

    private func encodeStateBoilerplates(
        _ machine: Machine,
        stateObjects: [StateID: DynamicEObject],
        into resource: Resource
    ) async -> [EUUID] {
        var entryIDs: [EUUID] = []
        for stateID in machine.llfsm.states {
            guard let stateObject = stateObjects[stateID],
                  let boilerplate = machine.stateBoilerplate[stateID] else {
                continue
            }
            let boilerplateObject = await encodeBoilerplate(boilerplate, language: machine.language, into: resource)
            var entry = DynamicEObject(eClass: metamodel.stateBoilerplateEntryClass)
            entry.eSet("state", value: stateObject.id)
            entry.eSet("boilerplate", value: boilerplateObject.id)
            await resource.register(entry)
            entryIDs.append(entry.id)
        }
        return entryIDs
    }

    private func encodeStateLayouts(
        _ layouts: StateLayouts,
        stateObjects: [StateID: DynamicEObject],
        into resource: Resource
    ) async -> [EUUID] {
        var entryIDs: [EUUID] = []
        for (stateID, layout) in layouts {
            guard let stateObject = stateObjects[stateID] else {
                continue
            }
            let layoutObject = await encodeStateLayout(layout, into: resource)
            var entry = DynamicEObject(eClass: metamodel.stateLayoutEntryClass)
            entry.eSet("state", value: stateObject.id)
            entry.eSet("layout", value: layoutObject.id)
            await resource.register(entry)
            entryIDs.append(entry.id)
        }
        return entryIDs
    }

    private func encodeStateLayout(_ layout: StateLayout, into resource: Resource) async -> DynamicEObject {
        var object = DynamicEObject(eClass: metamodel.stateLayoutClass)
        object.eSet("isOpen", value: layout.isOpen)
        object.eSet("closedX", value: layout.closedLayout.x)
        object.eSet("closedY", value: layout.closedLayout.y)
        object.eSet("closedW", value: layout.closedLayout.w)
        object.eSet("closedH", value: layout.closedLayout.h)
        object.eSet("openX", value: layout.openLayout.x)
        object.eSet("openY", value: layout.openLayout.y)
        object.eSet("openW", value: layout.openLayout.w)
        object.eSet("openH", value: layout.openLayout.h)
        object.eSet("onEntryHeight", value: layout.onEntryHeight)
        object.eSet("onExitHeight", value: layout.onExitHeight)
        object.eSet("internalHeight", value: layout.internalHeight)
        object.eSet("onSuspendHeight", value: layout.onSuspendHeight)
        object.eSet("onResumeHeight", value: layout.onResumeHeight)
        object.eSet("zoomedOnEntryHeight", value: layout.zoomedOnEntryHeight)
        object.eSet("zoomedOnExitHeight", value: layout.zoomedOnExitHeight)
        object.eSet("zoomedInternalHeight", value: layout.zoomedInternalHeight)
        object.eSet("zoomedOnSuspendHeight", value: layout.zoomedOnSuspendHeight)
        object.eSet("zoomedOnResumeHeight", value: layout.zoomedOnResumeHeight)
        if !layout.extraProperties.isEmpty {
            object.eSet("extraProperties", value: (try? encodeJSON(layout.extraProperties)) ?? "")
        }
        await resource.register(object)
        return object
    }

    private func encodeTransitionLayouts(
        _ layouts: TransitionLayouts,
        transitionObjects: [TransitionID: DynamicEObject],
        into resource: Resource
    ) async -> [EUUID] {
        var entryIDs: [EUUID] = []
        for (transitionID, layout) in layouts {
            guard let transitionObject = transitionObjects[transitionID] else {
                continue
            }
            var pointIDs: [EUUID] = []
            for point in layout.path.points {
                var pointObject = DynamicEObject(eClass: metamodel.point2DClass)
                pointObject.eSet("x", value: point.x)
                pointObject.eSet("y", value: point.y)
                await resource.register(pointObject)
                pointIDs.append(pointObject.id)
            }
            var layoutObject = DynamicEObject(eClass: metamodel.transitionLayoutClass)
            layoutObject.eSet("points", value: pointIDs)
            await resource.register(layoutObject)
            var entry = DynamicEObject(eClass: metamodel.transitionLayoutEntryClass)
            entry.eSet("transition", value: transitionObject.id)
            entry.eSet("layout", value: layoutObject.id)
            await resource.register(entry)
            entryIDs.append(entry.id)
        }
        return entryIDs
    }

    private func decodeMachineBoilerplate(
        _ boilerplateID: EUUID?,
        from resource: Resource,
        language: any LanguageBinding
    ) async -> any Boilerplate {
        guard let boilerplateID else {
            return CBoilerplate()
        }
        return language.createBoilerplate(from: await decodeBoilerplateSections(boilerplateID, from: resource))
    }

    private func decodeBoilerplateSections(
        _ boilerplateID: EUUID,
        from resource: Resource
    ) async -> [StandardBoilerplateSection: String] {
        var sections: [StandardBoilerplateSection: String] = [:]
        sections[.includePath] = await resource.eGet(objectId: boilerplateID, feature: "includePath") as? String ?? ""
        sections[.includes] = await resource.eGet(objectId: boilerplateID, feature: "includes") as? String ?? ""
        sections[.variables] = await resource.eGet(objectId: boilerplateID, feature: "variables") as? String ?? ""
        sections[.functions] = await resource.eGet(objectId: boilerplateID, feature: "functions") as? String ?? ""
        return sections
    }

    private func decodeSection(feature: String, stateObjectID: EUUID, from resource: Resource) async -> String {
        guard let sectionID = await resource.eGet(objectId: stateObjectID, feature: feature) as? EUUID else {
            return ""
        }
        let statementIDs = executableReferenceIDs(
            from: await resource.eGet(objectId: sectionID, feature: "statements")
        )
        let rendered = await statementIDs.asyncMap { statementID in
            await decodeStatement(statementID, from: resource)
        }
        return rendered.filter { !$0.isEmpty }.joined(separator: "\n")
    }

    private func decodeStatement(_ statementID: EUUID, from resource: Resource) async -> String {
        guard let object = await resource.resolve(statementID) as? DynamicEObject else {
            return ""
        }
        switch object.eClass.name {
        case metamodel.outputLineClass.name:
            let line = await resource.eGet(objectId: statementID, feature: "theLine") as? String ?? ""
            return "print(\"\(escapeString(line))\");"
        case metamodel.assignmentIntegerClass.name:
            let variableName = await referencedName(statementID, feature: "variable", nameFeature: "variableID", from: resource)
            let expressionID = await resource.eGet(objectId: statementID, feature: "anArithmeticExpression") as? EUUID
            let expression = await arithmeticExpressionString(expressionID, from: resource)
            return variableName.isEmpty ? "" : "\(variableName) = \(expression);"
        case metamodel.assignmentBooleanClass.name:
            let variableName = await referencedName(statementID, feature: "variable", nameFeature: "variableID", from: resource)
            let expressionID = await resource.eGet(objectId: statementID, feature: "aBooleanExpression") as? EUUID
            let expression = await booleanExpressionString(expressionID, from: resource)
            return variableName.isEmpty ? "" : "\(variableName) = \(expression);"
        case metamodel.opaqueStatementClass.name:
            return await resource.eGet(objectId: statementID, feature: "code") as? String ?? ""
        default:
            return ""
        }
    }

    private func transitionLabel(for transitionObjectID: EUUID, from resource: Resource) async throws -> String {
        let expressionID = await resource.eGet(objectId: transitionObjectID, feature: "booleanExpression") as? EUUID
        return await booleanExpressionString(expressionID, from: resource)
    }

    private func booleanExpressionString(_ expressionID: EUUID?, from resource: Resource) async -> String {
        guard let expressionID, let object = await resource.resolve(expressionID) as? DynamicEObject else {
            return "true"
        }

        switch object.eClass.name {
        case metamodel.booleanConstantClass.name:
            return ((await resource.eGet(objectId: expressionID, feature: "aBooleanValue") as? Bool) ?? false) ? "true" : "false"
        case metamodel.booleanVariableReferenceClass.name:
            return await referencedName(expressionID, feature: "theVariable", nameFeature: "variableID", from: resource)
        case metamodel.notExpressionClass.name:
            let operandID = await resource.eGet(objectId: expressionID, feature: "theExpression") as? EUUID
            return "!\(parenthesiseIfNeeded(await booleanExpressionString(operandID, from: resource)))"
        case metamodel.andExpressionClass.name:
            return await binaryBooleanExpression(expressionID, operatorToken: "&&", from: resource)
        case metamodel.orExpressionClass.name:
            return await binaryBooleanExpression(expressionID, operatorToken: "||", from: resource)
        case metamodel.equalExpressionClass.name:
            return await binaryArithmeticBooleanExpression(expressionID, operatorToken: "==", from: resource)
        case metamodel.lessThanExpressionClass.name:
            return await binaryArithmeticBooleanExpression(expressionID, operatorToken: "<", from: resource)
        case metamodel.opaqueExpressionClass.name:
            return await resource.eGet(objectId: expressionID, feature: "code") as? String ?? "true"
        default:
            return "true"
        }
    }

    private func arithmeticExpressionString(_ expressionID: EUUID?, from resource: Resource) async -> String {
        guard let expressionID, let object = await resource.resolve(expressionID) as? DynamicEObject else {
            return "0"
        }

        switch object.eClass.name {
        case metamodel.integerConstantClass.name:
            return String(await resource.eGet(objectId: expressionID, feature: "anIntegerValue") as? Int ?? 0)
        case metamodel.integerVariableReferenceClass.name:
            return await referencedName(expressionID, feature: "theVariable", nameFeature: "variableID", from: resource)
        case metamodel.predefinedIntegerConstantClass.name:
            return await referencedName(expressionID, feature: "listedIntegerConstant", nameFeature: "Identifier", from: resource)
        case "AdditionExpression":
            return await binaryArithmeticExpression(expressionID, operatorToken: "+", from: resource)
        case "SubtractionExpression":
            return await binaryArithmeticExpression(expressionID, operatorToken: "-", from: resource)
        case "MultiplicationExpression":
            return await binaryArithmeticExpression(expressionID, operatorToken: "*", from: resource)
        case "ModulusExpression":
            return await binaryArithmeticExpression(expressionID, operatorToken: "%", from: resource)
        case metamodel.opaqueExpressionClass.name:
            return await resource.eGet(objectId: expressionID, feature: "code") as? String ?? "0"
        default:
            return "0"
        }
    }

    private func binaryBooleanExpression(_ expressionID: EUUID, operatorToken: String, from resource: Resource) async -> String {
        let leftID = await resource.eGet(objectId: expressionID, feature: "leftExpression") as? EUUID
        let rightID = await resource.eGet(objectId: expressionID, feature: "rightExpression") as? EUUID
        let left = await booleanExpressionString(leftID, from: resource)
        let right = await booleanExpressionString(rightID, from: resource)
        return "(\(left) \(operatorToken) \(right))"
    }

    private func binaryArithmeticBooleanExpression(_ expressionID: EUUID, operatorToken: String, from resource: Resource) async -> String {
        let leftID = await resource.eGet(objectId: expressionID, feature: "leftExpression") as? EUUID
        let rightID = await resource.eGet(objectId: expressionID, feature: "rightExpression") as? EUUID
        let left = await arithmeticExpressionString(leftID, from: resource)
        let right = await arithmeticExpressionString(rightID, from: resource)
        return "(\(left) \(operatorToken) \(right))"
    }

    private func binaryArithmeticExpression(_ expressionID: EUUID, operatorToken: String, from resource: Resource) async -> String {
        let leftID = await resource.eGet(objectId: expressionID, feature: "leftExpression") as? EUUID
        let rightID = await resource.eGet(objectId: expressionID, feature: "rightExpression") as? EUUID
        let left = await arithmeticExpressionString(leftID, from: resource)
        let right = await arithmeticExpressionString(rightID, from: resource)
        return "(\(left) \(operatorToken) \(right))"
    }

    private func referencedName(
        _ objectID: EUUID,
        feature: String,
        nameFeature: String,
        from resource: Resource
    ) async -> String {
        guard let referenceID = await resource.eGet(objectId: objectID, feature: feature) as? EUUID else {
            return ""
        }
        return await resource.eGet(objectId: referenceID, feature: nameFeature) as? String ?? ""
    }

    private func decodeStateLayout(_ layoutID: EUUID, from resource: Resource) async -> StateLayout {
        let closed = Ellipse(
            centre: Coordinate2D(
                await doubleValue(of: "closedX", for: layoutID, in: resource),
                await doubleValue(of: "closedY", for: layoutID, in: resource)
            ),
            dimensions: Dimensions2D(
                await doubleValue(of: "closedW", for: layoutID, in: resource),
                await doubleValue(of: "closedH", for: layoutID, in: resource)
            )
        )
        let open = Rectangle(
            centre: Coordinate2D(
                await doubleValue(of: "openX", for: layoutID, in: resource),
                await doubleValue(of: "openY", for: layoutID, in: resource)
            ),
            dimensions: Dimensions2D(
                await doubleValue(of: "openW", for: layoutID, in: resource),
                await doubleValue(of: "openH", for: layoutID, in: resource)
            )
        )
        return StateLayout(
            isOpen: await booleanValue(of: "isOpen", for: layoutID, in: resource),
            openLayout: open,
            closedLayout: closed,
            onEntryHeight: await doubleValue(of: "onEntryHeight", for: layoutID, in: resource),
            onExitHeight: await doubleValue(of: "onExitHeight", for: layoutID, in: resource),
            onSuspendHeight: await doubleValue(of: "onSuspendHeight", for: layoutID, in: resource),
            onResumeHeight: await doubleValue(of: "onResumeHeight", for: layoutID, in: resource),
            internalHeight: await doubleValue(of: "internalHeight", for: layoutID, in: resource),
            zoomedOnEntryHeight: await doubleValue(of: "zoomedOnEntryHeight", for: layoutID, in: resource),
            zoomedOnExitHeight: await doubleValue(of: "zoomedOnExitHeight", for: layoutID, in: resource),
            zoomedInternalHeight: await doubleValue(of: "zoomedInternalHeight", for: layoutID, in: resource),
            zoomedOnSuspendHeight: await doubleValue(of: "zoomedOnSuspendHeight", for: layoutID, in: resource),
            zoomedOnResumeHeight: await doubleValue(of: "zoomedOnResumeHeight", for: layoutID, in: resource),
            extraProperties: await decodeJSONDictionary(from: resource.eGet(objectId: layoutID, feature: "extraProperties") as? String)
        )
    }

    private func decodeTransitionLayout(_ layoutID: EUUID, from resource: Resource) async -> TransitionLayout {
        let pointIDs = executableReferenceIDs(
            from: await resource.eGet(objectId: layoutID, feature: "points")
        )
        let points = await pointIDs.asyncMap { pointID in
            Point2D(
                await doubleValue(of: "x", for: pointID, in: resource),
                await doubleValue(of: "y", for: pointID, in: resource)
            )
        }
        return TransitionLayout(points)
    }

    private func doubleValue(of feature: String, for objectID: EUUID, in resource: Resource) async -> Double {
        await resource.eGet(objectId: objectID, feature: feature) as? Double ?? 0
    }

    private func booleanValue(of feature: String, for objectID: EUUID, in resource: Resource) async -> Bool {
        await resource.eGet(objectId: objectID, feature: feature) as? Bool ?? false
    }

    private func encodeJSON(_ dictionary: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: dictionary, options: [.sortedKeys])
        return String(decoding: data, as: UTF8.self)
    }

    private func decodeJSONDictionary(from string: String?) -> [String: Any] {
        guard let string, !string.isEmpty,
              let data = string.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            return [:]
        }
        return dictionary
    }

}

private func executableReferenceIDs(from value: Any?) -> [EUUID] {
    switch value {
    case let ids as [EUUID]:
        return ids
    case let id as EUUID:
        return [id]
    default:
        return []
    }
}

private struct ParsedSections {
    let onEntry: [ExecutableStatementNode]
    let onExit: [ExecutableStatementNode]
    let internalCode: [ExecutableStatementNode]
    let onSuspend: [ExecutableStatementNode]
    let onResume: [ExecutableStatementNode]

    init(from sections: [StandardBoilerplateSection: String], collector: inout ExecutableVariableCollector) {
        onEntry = ExecutableParser.parseSection(sections[.onEntry] ?? "", collector: &collector)
        onExit = ExecutableParser.parseSection(sections[.onExit] ?? "", collector: &collector)
        internalCode = ExecutableParser.parseSection(sections[.internal] ?? "", collector: &collector)
        onSuspend = ExecutableParser.parseSection(sections[.onSuspend] ?? "", collector: &collector)
        onResume = ExecutableParser.parseSection(sections[.onResume] ?? "", collector: &collector)
    }
}

private struct ExecutableVariableCollector {
    private(set) var integerVariables: [String] = []
    private(set) var booleanVariables: [String] = []

    mutating func registerInteger(_ name: String) {
        guard !integerVariables.contains(name) else { return }
        integerVariables.append(name)
    }

    mutating func registerBoolean(_ name: String) {
        guard !booleanVariables.contains(name) else { return }
        booleanVariables.append(name)
    }
}

private struct ExecutableVariableLookup {
    let integerVariables: [String: DynamicEObject]
    let booleanVariables: [String: DynamicEObject]
    let integerConstants: [String: DynamicEObject]
}

private struct ExecutableVariableListEncoding {
    let listID: EUUID?
    let lookup: [String: DynamicEObject]
}

private enum ExecutableStatementNode {
    case outputLine(String)
    case assignInteger(variable: String, expression: ExecutableArithmeticNode)
    case assignBoolean(variable: String, expression: ExecutableBooleanNode)
    case opaque(String)
}

private indirect enum ExecutableBooleanNode {
    case constant(Bool)
    case variable(String)
    case not(ExecutableBooleanNode)
    case and(ExecutableBooleanNode, ExecutableBooleanNode)
    case or(ExecutableBooleanNode, ExecutableBooleanNode)
    case equal(ExecutableArithmeticNode, ExecutableArithmeticNode)
    case lessThan(ExecutableArithmeticNode, ExecutableArithmeticNode)
    case opaque(String)
}

private indirect enum ExecutableArithmeticNode {
    case integer(Int)
    case variable(String)
    case predefinedConstant(String)
    case addition(ExecutableArithmeticNode, ExecutableArithmeticNode)
    case subtraction(ExecutableArithmeticNode, ExecutableArithmeticNode)
    case multiplication(ExecutableArithmeticNode, ExecutableArithmeticNode)
    case modulus(ExecutableArithmeticNode, ExecutableArithmeticNode)
    case opaque(String)
}

private enum ExecutableParser {
    private static let identifier = try! NSRegularExpression(pattern: "^[A-Za-z_][A-Za-z0-9_]*$")
    private static let printCall = try! NSRegularExpression(pattern: #"^(?:print|puts)\("([^"]*)"\);?$"#)
    private static let assignment = try! NSRegularExpression(pattern: #"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+?);?$"#)

    static func parseSection(_ source: String, collector: inout ExecutableVariableCollector) -> [ExecutableStatementNode] {
        let normalised = source.replacingOccurrences(of: "\r\n", with: "\n")
        if normalised.isEmpty {
            return []
        }
        if normalised.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return [.opaque(normalised)]
        }

        let lines = normalised.split(separator: "\n", omittingEmptySubsequences: false)
        var statements: [ExecutableStatementNode] = []
        for line in lines {
            let rawLine = String(line)
            let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            statements.append(parseStatement(trimmed, collector: &collector) ?? .opaque(rawLine))
        }

        return statements.isEmpty ? [.opaque(normalised)] : statements
    }

    static func parseBoolean(_ source: String, collector: inout ExecutableVariableCollector) -> ExecutableBooleanNode? {
        var parser = ExpressionParser(source: source, collector: collector)
        let expression = parser.parseBoolean()
        if expression != nil {
            collector = parser.collector
        }
        return expression
    }

    private static func parseStatement(_ source: String, collector: inout ExecutableVariableCollector) -> ExecutableStatementNode? {
        if let line = firstCapture(in: source, using: printCall, group: 1) {
            return .outputLine(line)
        }

        let matches = assignment.matches(in: source, range: NSRange(source.startIndex..., in: source))
        guard let match = matches.first,
              let variable = capture(from: source, match: match, group: 1),
              let expressionSource = capture(from: source, match: match, group: 2) else {
            return nil
        }

        var workingCollector = collector
        var booleanParser = ExpressionParser(source: expressionSource, collector: workingCollector)
        if let boolean = booleanParser.parseBoolean() {
            collector = booleanParser.collector
            collector.registerBoolean(variable)
            return .assignBoolean(variable: variable, expression: boolean)
        }

        workingCollector = collector
        var arithmeticParser = ExpressionParser(source: expressionSource, collector: workingCollector)
        if let arithmetic = arithmeticParser.parseArithmetic() {
            collector = arithmeticParser.collector
            collector.registerInteger(variable)
            return .assignInteger(variable: variable, expression: arithmetic)
        }

        return nil
    }

    private static func firstCapture(in source: String, using regex: NSRegularExpression, group: Int) -> String? {
        let matches = regex.matches(in: source, range: NSRange(source.startIndex..., in: source))
        guard let match = matches.first else {
            return nil
        }
        return capture(from: source, match: match, group: group)
    }

    private static func capture(from source: String, match: NSTextCheckingResult, group: Int) -> String? {
        guard let range = Range(match.range(at: group), in: source) else {
            return nil
        }
        return String(source[range])
    }

    private struct ExpressionParser {
        let tokens: [ExpressionToken]
        var index: Int = 0
        var collector: ExecutableVariableCollector

        init(source: String, collector: ExecutableVariableCollector) {
            tokens = Tokeniser.tokenise(source)
            self.collector = collector
        }

        mutating func parseBoolean() -> ExecutableBooleanNode? {
            guard let expression = parseOr(), isAtEnd else {
                return nil
            }
            return expression
        }

        mutating func parseArithmetic() -> ExecutableArithmeticNode? {
            guard let expression = parseAdditive(), isAtEnd else {
                return nil
            }
            return expression
        }

        private mutating func parseOr() -> ExecutableBooleanNode? {
            guard var expression = parseAnd() else {
                return nil
            }
            while match(.or) {
                guard let rhs = parseAnd() else { return nil }
                expression = .or(expression, rhs)
            }
            return expression
        }

        private mutating func parseAnd() -> ExecutableBooleanNode? {
            guard var expression = parseComparison() else {
                return nil
            }
            while match(.and) {
                guard let rhs = parseComparison() else { return nil }
                expression = .and(expression, rhs)
            }
            return expression
        }

        private mutating func parseComparison() -> ExecutableBooleanNode? {
            if match(.not) {
                guard let operand = parseComparison() else { return nil }
                return .not(operand)
            }

            let checkpoint = index
            if let arithmetic = parseAdditive() {
                if match(.equal) {
                    guard let rhs = parseAdditive() else { return nil }
                    return .equal(arithmetic, rhs)
                }
                if match(.lessThan) {
                    guard let rhs = parseAdditive() else { return nil }
                    return .lessThan(arithmetic, rhs)
                }
                if case .variable(let name) = arithmetic, !isArithmeticContinuation {
                    collector.registerBoolean(name)
                    return .variable(name)
                }
                if case .opaque(let code) = arithmetic, !isArithmeticContinuation {
                    return .opaque(code)
                }
            }
            index = checkpoint

            if match(.leftParen) {
                guard let expression = parseOr(), match(.rightParen) else { return nil }
                return expression
            }

            if match(.trueLiteral) { return .constant(true) }
            if match(.falseLiteral) { return .constant(false) }
            return nil
        }

        private var isArithmeticContinuation: Bool {
            peek == .plus || peek == .minus || peek == .asterisk || peek == .percent || peek == .rightParen
        }

        private mutating func parseAdditive() -> ExecutableArithmeticNode? {
            guard var expression = parseMultiplicative() else {
                return nil
            }
            while true {
                if match(.plus) {
                    guard let rhs = parseMultiplicative() else { return nil }
                    expression = .addition(expression, rhs)
                } else if match(.minus) {
                    guard let rhs = parseMultiplicative() else { return nil }
                    expression = .subtraction(expression, rhs)
                } else {
                    break
                }
            }
            return expression
        }

        private mutating func parseMultiplicative() -> ExecutableArithmeticNode? {
            guard var expression = parsePrimaryArithmetic() else {
                return nil
            }
            while true {
                if match(.asterisk) {
                    guard let rhs = parsePrimaryArithmetic() else { return nil }
                    expression = .multiplication(expression, rhs)
                } else if match(.percent) {
                    guard let rhs = parsePrimaryArithmetic() else { return nil }
                    expression = .modulus(expression, rhs)
                } else {
                    break
                }
            }
            return expression
        }

        private mutating func parsePrimaryArithmetic() -> ExecutableArithmeticNode? {
            if case .integer(let value) = peek {
                index += 1
                return .integer(value)
            }
            if case .identifier(let name) = peek {
                index += 1
                if name.first?.isUppercase == true {
                    return .predefinedConstant(name)
                }
                collector.registerInteger(name)
                return .variable(name)
            }
            if match(.leftParen) {
                guard let expression = parseAdditive(), match(.rightParen) else { return nil }
                return expression
            }
            return nil
        }

        private var isAtEnd: Bool {
            peek == .end
        }

        private var peek: ExpressionToken {
            tokens.indices.contains(index) ? tokens[index] : .end
        }

        @discardableResult
        private mutating func match(_ token: ExpressionToken) -> Bool {
            guard peek == token else { return false }
            index += 1
            return true
        }
    }

    private enum ExpressionToken: Equatable {
        case identifier(String)
        case integer(Int)
        case trueLiteral
        case falseLiteral
        case not
        case and
        case or
        case equal
        case lessThan
        case plus
        case minus
        case asterisk
        case percent
        case leftParen
        case rightParen
        case end
    }

    private enum Tokeniser {
        static func tokenise(_ source: String) -> [ExpressionToken] {
            var tokens: [ExpressionToken] = []
            let characters = Array(source.trimmingCharacters(in: .whitespacesAndNewlines))
            var index = 0

            while index < characters.count {
                let character = characters[index]
                if character.isWhitespace {
                    index += 1
                    continue
                }

                if character.isNumber {
                    let start = index
                    index += 1
                    while index < characters.count, characters[index].isNumber {
                        index += 1
                    }
                    tokens.append(.integer(Int(String(characters[start..<index])) ?? 0))
                    continue
                }

                if character.isLetter || character == "_" {
                    let start = index
                    index += 1
                    while index < characters.count, characters[index].isLetter || characters[index].isNumber || characters[index] == "_" {
                        index += 1
                    }
                    let identifier = String(characters[start..<index])
                    switch identifier {
                    case "true":
                        tokens.append(.trueLiteral)
                    case "false":
                        tokens.append(.falseLiteral)
                    default:
                        tokens.append(.identifier(identifier))
                    }
                    continue
                }

                if character == "&", index + 1 < characters.count, characters[index + 1] == "&" {
                    tokens.append(.and)
                    index += 2
                    continue
                }
                if character == "|", index + 1 < characters.count, characters[index + 1] == "|" {
                    tokens.append(.or)
                    index += 2
                    continue
                }
                if character == "=", index + 1 < characters.count, characters[index + 1] == "=" {
                    tokens.append(.equal)
                    index += 2
                    continue
                }

                switch character {
                case "!":
                    tokens.append(.not)
                case "<":
                    tokens.append(.lessThan)
                case "+":
                    tokens.append(.plus)
                case "-":
                    tokens.append(.minus)
                case "*":
                    tokens.append(.asterisk)
                case "%":
                    tokens.append(.percent)
                case "(":
                    tokens.append(.leftParen)
                case ")":
                    tokens.append(.rightParen)
                default:
                    return [.end]
                }
                index += 1
            }

            tokens.append(.end)
            return tokens
        }
    }
}

private func escapeString(_ string: String) -> String {
    string
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
}

private func parenthesiseIfNeeded(_ string: String) -> String {
    if string.hasPrefix("(") && string.hasSuffix(")") {
        return string
    }
    return "(\(string))"
}

private extension Array {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var result: [T] = []
        result.reserveCapacity(count)
        for element in self {
            result.append(try await transform(element))
        }
        return result
    }
}
