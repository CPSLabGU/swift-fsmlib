import ECore
import EMFBase
import Foundation

/// LLFSM executable metamodel metadata.
///
/// `ExecutableLLFSMMetamodel` loads the bundled executable metamodel that keeps
/// the legacy LLFSM class and feature names used by the model-to-text
/// generators. It also exposes the additional opaque and fidelity-oriented
/// classifiers added for `swift-fsmlib` round-tripping, such as instance
/// wrappers, suspend and resume sections, and boilerplate and layout classes.
public struct ExecutableLLFSMMetamodel: Sendable {
    /// Loaded package for the executable LLFSM metamodel.
    ///
    /// This package is registered with `swift-ecore` when loading executable
    /// instance models so their namespace URI resolves to the legacy typed
    /// hierarchy rather than anonymous dynamic classes.
    public let package: EPackage

    /// `EClass` for the arrangement root.
    ///
    /// This root class groups machine instances and direct machine references
    /// so both native arrangement workflows and legacy template inputs can be
    /// represented in one executable model.
    public let arrangementClass: EClass
    /// `EClass` for arrangement instance wrappers.
    ///
    /// Instance wrappers preserve the instance name and referenced type file
    /// for arrangement-level generation and round-tripping.
    public let instanceClass: EClass
    /// `EClass` for state machines.
    public let stateMachineClass: EClass
    /// `EClass` for regular states.
    public let stateClass: EClass
    /// `EClass` for initial states.
    public let initialStateClass: EClass
    /// `EClass` for transitions.
    public let transitionClass: EClass
    /// `EClass` for integer variables.
    public let integerVariableClass: EClass
    /// `EClass` for Boolean variables.
    public let booleanVariableClass: EClass
    /// `EClass` for integer variable containers.
    public let listOfIntegerVariablesClass: EClass
    /// `EClass` for Boolean variable containers.
    public let listOfBooleanVariablesClass: EClass
    /// `EClass` for statements.
    public let statementClass: EClass
    /// `EClass` for output statements.
    public let outputLineClass: EClass
    /// `EClass` for integer assignments.
    public let assignmentIntegerClass: EClass
    /// `EClass` for Boolean assignments.
    public let assignmentBooleanClass: EClass
    /// `EClass` for opaque statements.
    public let opaqueStatementClass: EClass
    /// `EClass` for Boolean constants.
    public let booleanConstantClass: EClass
    /// `EClass` for Boolean variable references.
    public let booleanVariableReferenceClass: EClass
    /// `EClass` for conjunctions.
    public let andExpressionClass: EClass
    /// `EClass` for disjunctions.
    public let orExpressionClass: EClass
    /// `EClass` for negations.
    public let notExpressionClass: EClass
    /// `EClass` for less-than comparisons.
    public let lessThanExpressionClass: EClass
    /// `EClass` for equality comparisons.
    public let equalExpressionClass: EClass
    /// `EClass` for integer constants.
    public let integerConstantClass: EClass
    /// `EClass` for integer constant supertype nodes.
    public let integerConstantForDefinitionClass: EClass
    /// `EClass` for integer variable references.
    public let integerVariableReferenceClass: EClass
    /// `EClass` for predefined integer constants.
    public let predefinedIntegerConstantClass: EClass
    /// `EClass` for opaque expressions.
    public let opaqueExpressionClass: EClass
    /// `EClass` for entry sections.
    public let onEntrySectionClass: EClass
    /// `EClass` for exit sections.
    public let onExitSectionClass: EClass
    /// `EClass` for internal sections.
    public let internalSectionClass: EClass
    /// `EClass` for suspend sections.
    public let onSuspendSectionClass: EClass
    /// `EClass` for resume sections.
    public let onResumeSectionClass: EClass
    /// `EClass` for boilerplate nodes.
    public let boilerplateClass: EClass
    /// `EClass` for state boilerplate entries.
    public let stateBoilerplateEntryClass: EClass
    /// `EClass` for state layout entries.
    public let stateLayoutEntryClass: EClass
    /// `EClass` for state layouts.
    public let stateLayoutClass: EClass
    /// `EClass` for transition layout entries.
    public let transitionLayoutEntryClass: EClass
    /// `EClass` for transition layouts.
    public let transitionLayoutClass: EClass
    /// `EClass` for layout points.
    public let point2DClass: EClass
    /// `EClass` for window layout payloads.
    public let windowLayoutClass: EClass

    /// Load the bundled executable metamodel.
    ///
    /// - Throws: Throw an error if the bundled `.ecore` resource cannot be
    ///   found, parsed, or validated.
    public init() async throws {
        guard let url = Bundle.module.url(
            forResource: "LLFSMExecutable",
            withExtension: "ecore",
            subdirectory: "Resources"
        ) else {
            throw ExecutableLLFSMMetamodelError.resourceNotFound
        }
        try await self.init(url: url)
    }

    /// Load the executable metamodel from a file URL.
    ///
    /// - Parameter url: URL of the `.ecore` document to load.
    /// - Throws: Throw an error if parsing fails or a required classifier is
    ///   missing.
    public init(url: URL) async throws {
        package = try await EPackage(url: url)

        arrangementClass = try Self.requireClass("Arrangement", in: package)
        instanceClass = try Self.requireClass("Instance", in: package)
        stateMachineClass = try Self.requireClass("StateMachine", in: package)
        stateClass = try Self.requireClass("State", in: package)
        initialStateClass = try Self.requireClass("InitialState", in: package)
        transitionClass = try Self.requireClass("Transition", in: package)
        integerVariableClass = try Self.requireClass("IntegerVariable", in: package)
        booleanVariableClass = try Self.requireClass("BooleanVariable", in: package)
        listOfIntegerVariablesClass = try Self.requireClass("ListOfIntegerVariables", in: package)
        listOfBooleanVariablesClass = try Self.requireClass("ListOfBooleanVariables", in: package)
        statementClass = try Self.requireClass("Statement", in: package)
        outputLineClass = try Self.requireClass("OutputLine", in: package)
        assignmentIntegerClass = try Self.requireClass("AssignmentIntegerLHS", in: package)
        assignmentBooleanClass = try Self.requireClass("AssignmentBooleanLHS", in: package)
        opaqueStatementClass = try Self.requireClass("OpaqueStatement", in: package)
        booleanConstantClass = try Self.requireClass("BooleanConstant", in: package)
        booleanVariableReferenceClass = try Self.requireClass("BooleanVariableReference", in: package)
        andExpressionClass = try Self.requireClass("AndExpression", in: package)
        orExpressionClass = try Self.requireClass("OrExpression", in: package)
        notExpressionClass = try Self.requireClass("NotExpression", in: package)
        lessThanExpressionClass = try Self.requireClass("LessThanExpression", in: package)
        equalExpressionClass = try Self.requireClass("EqualExpression", in: package)
        integerConstantClass = try Self.requireClass("IntegerConstant", in: package)
        integerConstantForDefinitionClass = try Self.requireClass("IntegerConstantForDefinition", in: package)
        integerVariableReferenceClass = try Self.requireClass("IntegerVariableReference", in: package)
        predefinedIntegerConstantClass = try Self.requireClass("PredefinedIntegerConstant", in: package)
        opaqueExpressionClass = try Self.requireClass("OpaqueExpression", in: package)
        onEntrySectionClass = try Self.requireClass("OnEntrySection", in: package)
        onExitSectionClass = try Self.requireClass("OnExitSection", in: package)
        internalSectionClass = try Self.requireClass("InternalSection", in: package)
        onSuspendSectionClass = try Self.requireClass("OnSuspendSection", in: package)
        onResumeSectionClass = try Self.requireClass("OnResumeSection", in: package)
        boilerplateClass = try Self.requireClass("Boilerplate", in: package)
        stateBoilerplateEntryClass = try Self.requireClass("StateBoilerplateEntry", in: package)
        stateLayoutEntryClass = try Self.requireClass("StateLayoutEntry", in: package)
        stateLayoutClass = try Self.requireClass("StateLayout", in: package)
        transitionLayoutEntryClass = try Self.requireClass("TransitionLayoutEntry", in: package)
        transitionLayoutClass = try Self.requireClass("TransitionLayout", in: package)
        point2DClass = try Self.requireClass("Point2D", in: package)
        windowLayoutClass = try Self.requireClass("WindowLayout", in: package)
    }

    /// Look up a required executable classifier by name.
    ///
    /// This helper centralises missing-class validation so initialisation fails
    /// at the first missing dependency instead of leaving partially initialised
    /// metadata behind.
    ///
    /// - Parameters:
    ///   - name: Name of the expected classifier.
    ///   - package: Package containing the classifier.
    /// - Returns: Matching executable `EClass`.
    /// - Throws: Throw an error if the classifier is absent.
    private static func requireClass(_ name: String, in package: EPackage) throws -> EClass {
        guard let eClass = package.getEClass(name) else {
            throw ExecutableLLFSMMetamodelError.missingClass(name)
        }
        return eClass
    }
}

/// Errors raised while loading the executable LLFSM metamodel.
public enum ExecutableLLFSMMetamodelError: Error, CustomStringConvertible {
    /// Missing bundled `.ecore` resource.
    case resourceNotFound
    /// Missing required `EClass`.
    case missingClass(String)
    /// Missing required structural feature.
    case missingFeature(String)

    /// Human-readable error description.
    ///
    /// This value provides short diagnostics that are suitable for test output
    /// and command-line error reporting.
    public var description: String {
        switch self {
        case .resourceNotFound:
            return "LLFSMExecutable.ecore resource not found in bundle"
        case .missingClass(let name):
            return "Missing expected executable EClass: \(name)"
        case .missingFeature(let name):
            return "Missing expected executable feature: \(name)"
        }
    }
}
