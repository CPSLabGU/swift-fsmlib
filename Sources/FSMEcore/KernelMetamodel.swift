//
//  KernelMetamodel.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation

/// The kernel level of the LLFSM metamodel family.
///
/// `KernelMetamodel` resolves the `kernel` subpackage of the bundled
/// `LLFSM.ecore` document and keeps typed handles for every class and
/// enumeration of the sectionless kernel. Use the handles to create and
/// classify kernel model objects without repeating string-based lookups.
///
/// ```swift
/// let kernel = try await KernelMetamodel()
/// let resourceSet = ResourceSet()
/// await kernel.register(in: resourceSet)
/// var state = DynamicEObject(eClass: kernel.stateClass)
/// state.eSet("name", value: "Idle")
/// ```
public struct KernelMetamodel: Sendable {
    /// The root package `llfsm` that contains the kernel subpackage.
    ///
    /// The root package also contains the sectioned subpackage, so
    /// registering it makes both levels known to a resource set.
    public let rootPackage: EPackage

    /// The `kernel` subpackage.
    ///
    /// Its namespace URI is ``LLFSMMetamodels/kernelNamespaceURI``.
    public let package: EPackage

    /// The `Arrangement` class: a closed system of machine instances.
    ///
    /// An arrangement holds the shared types, variables, functions and host declarations, the
    /// machine definitions and the ordered sequence of instances executed round-robin.
    public let arrangementClass: EClass

    /// The `Machine` class: a machine definition.
    ///
    /// A machine holds its local variables, functions, host declarations, states and initial state.
    public let machineClass: EClass

    /// The `Instance` class: a named occurrence of a machine in the execution sequence.
    ///
    /// An instance refers to its machine definition and may bind literal initial values to local
    /// variables of that machine.
    public let instanceClass: EClass

    /// The `Binding` class: an instance-specific initial value of a local variable.
    ///
    /// A binding names a local variable of the instance's machine and a literal value.
    public let bindingClass: EClass

    /// The `State` class: a kernel state with a single action and ordered transitions.
    ///
    /// A pass-through state continues the ringlet when it is entered instead of ending it.
    public let stateClass: EClass

    /// The `Transition` class: a labelled transition to a state of the same machine.
    ///
    /// Transitions of a state are evaluated in order; the first whose Boolean label holds fires.
    public let transitionClass: EClass

    /// The `Origin` class: the record of the sectioned element that a kernel element encodes.
    ///
    /// States and transitions created by the sectioned-to-kernel encoding carry an origin so that
    /// the sectioned model can be rebuilt (see ``OriginAnnotations``).
    public let originClass: EClass

    /// The `Variable` class: a typed variable.
    ///
    /// Variables are shared when declared by an arrangement and local when declared by a machine;
    /// only shared variables may be external. A variable recognised in host-language text keeps
    /// the comment, the text and the line of its declaration.
    public let variableClass: EClass

    /// The `FunctionDeclaration` class: a function or method implemented by the host environment.
    ///
    /// A pure function may be called in labels, binding values and initial values; any function may
    /// be called by a call statement.
    public let functionDeclarationClass: EClass

    /// The `Parameter` class: a typed parameter of a function declaration.
    ///
    /// Call arguments are checked against the parameters in order.
    public let parameterClass: EClass

    /// The `HostDeclarations` class: verbatim host-language preamble for code targets.
    ///
    /// Host declarations hold include paths, includes, declarations and functions, and are
    /// admitted by the relaxed profile only.
    public let hostDeclarationsClass: EClass

    /// The `Type` class: the abstract superclass of all kernel types.
    ///
    /// Every concrete type has a name and is contained by an arrangement.
    public let typeClass: EClass

    /// The `BooleanType` class: the Boolean type.
    ///
    /// Labels and the operands of conjunction, disjunction and negation have this type.
    public let booleanTypeClass: EClass

    /// The `IntegerType` class: a bounded integer range.
    ///
    /// The bounds are inclusive; literals assigned to a variable of this type must lie within them.
    public let integerTypeClass: EClass

    /// The `EnumerationType` class: a finite enumeration of named literals.
    ///
    /// Literals must be unique within their enumeration.
    public let enumerationTypeClass: EClass

    /// The `ArrayType` class: a fixed-size array of a scalar type.
    ///
    /// Arrays are indexed from zero by integer expressions.
    public let arrayTypeClass: EClass

    /// The `OpaqueType` class: a host-language type written verbatim.
    ///
    /// Opaque types are admitted by the relaxed profile only.
    public let opaqueTypeClass: EClass

    /// The `Expression` class: the abstract superclass of all kernel expressions.
    ///
    /// Expressions are side-effect free and statically typed by well-formedness rules.
    public let expressionClass: EClass

    /// The `BooleanLiteral` class: a Boolean constant.
    ///
    /// Its type is the Boolean type.
    public let booleanLiteralClass: EClass

    /// The `IntegerLiteral` class: an integer constant.
    ///
    /// Its type is any integer type whose range contains the value.
    public let integerLiteralClass: EClass

    /// The `EnumerationLiteral` class: a literal of an enumeration type.
    ///
    /// The literal must be one of the literals of the referenced enumeration.
    public let enumerationLiteralClass: EClass

    /// The `VariableReference` class: a read of a variable, or of one element of an array variable.
    ///
    /// A variable reference is also the target of an assignment.
    public let variableReferenceClass: EClass

    /// The `UnaryExpression` class: a negation or arithmetic minus.
    ///
    /// The operation is one of ``KernelUnaryOperation``.
    public let unaryExpressionClass: EClass

    /// The `BinaryExpression` class: a logical, arithmetic or comparison operation on two operands.
    ///
    /// The operation is one of ``KernelBinaryOperation``.
    public let binaryExpressionClass: EClass

    /// The `ConditionalExpression` class: a choice between two expressions by a Boolean condition.
    ///
    /// Both branches must have the same type.
    public let conditionalExpressionClass: EClass

    /// The `InStateExpression` class: an observation that an instance occupies a state.
    ///
    /// The state must belong to the machine of the observed instance.
    public let inStateExpressionClass: EClass

    /// The `CallExpression` class: a call of a declared function or method.
    ///
    /// Arguments are checked against the declared parameters; a receiver selects a method.
    public let callExpressionClass: EClass

    /// The `OpaqueExpression` class: host-language expression text.
    ///
    /// Opaque expressions are admitted by the relaxed profile only.
    public let opaqueExpressionClass: EClass

    /// The `Statement` class: the abstract superclass of all kernel statements.
    ///
    /// An action is a straight-line sequence of statements.
    public let statementClass: EClass

    /// The `Assignment` class: an assignment of a value to a variable or array element.
    ///
    /// Within one action a variable is assigned at most once.
    public let assignmentClass: EClass

    /// The `Print` class: a line of observable output.
    ///
    /// Execution targets print the text followed by the values.
    public let printClass: EClass

    /// The `CallStatement` class: a call of a declared function for its effect.
    ///
    /// Any declared function may be called by a statement.
    public let callStatementClass: EClass

    /// The `OpaqueStatement` class: host-language statement text.
    ///
    /// Opaque statements are admitted by the relaxed profile only.
    public let opaqueStatementClass: EClass

    /// The `UnaryOperation` enumeration: the enumeration of unary operations.
    ///
    /// Its literals are those of ``KernelUnaryOperation``.
    public let unaryOperationEnum: EEnum

    /// The `BinaryOperation` enumeration: the enumeration of binary operations.
    ///
    /// Its literals are those of ``KernelBinaryOperation``.
    public let binaryOperationEnum: EEnum

    /// The `OriginRole` enumeration: the enumeration of origin roles.
    ///
    /// Its literals are those of ``OriginRole``.
    public let originRoleEnum: EEnum

    /// Load the kernel level from the bundled metamodel document.
    ///
    /// The document is loaded once per program and shared with
    /// ``SectionedMetamodel`` and ``LLFSMMetamodels``.
    ///
    /// - Throws: An error if the document cannot be found or parsed, or
    ///   ``LLFSMMetamodelsError`` if it lacks a kernel classifier or literal.
    public init() async throws {
        try self.init(rootPackage: try await LLFSMMetamodels.loadBundledRootPackage())
    }

    /// Resolve the kernel level within a loaded root package.
    ///
    /// - Parameter rootPackage: The root package `llfsm` of the metamodel family.
    /// - Throws: ``LLFSMMetamodelsError`` if the kernel subpackage, one of its
    ///   classes, or a literal of one of its enumerations is missing.
    public init(rootPackage: EPackage) throws {
        self.rootPackage = rootPackage
        package = try LLFSMMetamodels.subpackage(
            named: "kernel",
            nsURI: LLFSMMetamodels.kernelNamespaceURI,
            of: rootPackage
        )
        let lookup = LLFSMClassifierLookup(package: package)
        arrangementClass = try lookup.eClass("Arrangement")
        machineClass = try lookup.eClass("Machine")
        instanceClass = try lookup.eClass("Instance")
        bindingClass = try lookup.eClass("Binding")
        stateClass = try lookup.eClass("State")
        transitionClass = try lookup.eClass("Transition")
        originClass = try lookup.eClass("Origin")
        variableClass = try lookup.eClass("Variable")
        functionDeclarationClass = try lookup.eClass("FunctionDeclaration")
        parameterClass = try lookup.eClass("Parameter")
        hostDeclarationsClass = try lookup.eClass("HostDeclarations")
        typeClass = try lookup.eClass("Type")
        booleanTypeClass = try lookup.eClass("BooleanType")
        integerTypeClass = try lookup.eClass("IntegerType")
        enumerationTypeClass = try lookup.eClass("EnumerationType")
        arrayTypeClass = try lookup.eClass("ArrayType")
        opaqueTypeClass = try lookup.eClass("OpaqueType")
        expressionClass = try lookup.eClass("Expression")
        booleanLiteralClass = try lookup.eClass("BooleanLiteral")
        integerLiteralClass = try lookup.eClass("IntegerLiteral")
        enumerationLiteralClass = try lookup.eClass("EnumerationLiteral")
        variableReferenceClass = try lookup.eClass("VariableReference")
        unaryExpressionClass = try lookup.eClass("UnaryExpression")
        binaryExpressionClass = try lookup.eClass("BinaryExpression")
        conditionalExpressionClass = try lookup.eClass("ConditionalExpression")
        inStateExpressionClass = try lookup.eClass("InStateExpression")
        callExpressionClass = try lookup.eClass("CallExpression")
        opaqueExpressionClass = try lookup.eClass("OpaqueExpression")
        statementClass = try lookup.eClass("Statement")
        assignmentClass = try lookup.eClass("Assignment")
        printClass = try lookup.eClass("Print")
        callStatementClass = try lookup.eClass("CallStatement")
        opaqueStatementClass = try lookup.eClass("OpaqueStatement")
        unaryOperationEnum = try lookup.eEnum("UnaryOperation", literals: KernelUnaryOperation.self)
        binaryOperationEnum = try lookup.eEnum("BinaryOperation", literals: KernelBinaryOperation.self)
        originRoleEnum = try lookup.eEnum("OriginRole", literals: OriginRole.self)
    }

    /// Register the metamodel family with a resource set.
    ///
    /// The root package is registered under its namespace URI, which also
    /// makes the kernel and sectioned subpackages available under theirs.
    ///
    /// - Parameter resourceSet: The resource set that should know the metamodels.
    public func register(in resourceSet: ResourceSet) async {
        await LLFSMMetamodels.register(rootPackage, in: resourceSet)
    }

    /// Whether a class is a given kernel class or one of its subclasses.
    ///
    /// - Parameters:
    ///   - eClass: The class to test, typically the class of a model object.
    ///   - kernelClass: The kernel class to compare against.
    /// - Returns: `true` if `eClass` is `kernelClass` or inherits from it.
    public func isKind(_ eClass: EClass, of kernelClass: EClass) -> Bool {
        eClass.id == kernelClass.id || kernelClass.isSuperTypeOf(eClass)
    }
}

/// The unary operations of kernel expressions.
///
/// The raw values are the literal names of the `UnaryOperation`
/// enumeration of the kernel metamodel.
public enum KernelUnaryOperation: String, CaseIterable, Sendable {
    /// Boolean negation of a Boolean operand.
    case negation
    /// Arithmetic minus of an integer operand.
    case minus
}

/// The binary operations of kernel expressions.
///
/// The raw values are the literal names of the `BinaryOperation`
/// enumeration of the kernel metamodel.
public enum KernelBinaryOperation: String, CaseIterable, Sendable {
    /// Boolean conjunction.
    case conjunction
    /// Boolean disjunction.
    case disjunction
    /// Integer addition.
    case addition
    /// Integer subtraction.
    case subtraction
    /// Integer multiplication.
    case multiplication
    /// Integer division.
    case division
    /// Integer remainder.
    case modulo
    /// Equality of two operands of the same type.
    case equal
    /// Inequality of two operands of the same type.
    case notEqual
    /// Integer less-than comparison.
    case lessThan
    /// Integer less-than-or-equal comparison.
    case lessOrEqual
    /// Integer greater-than comparison.
    case greaterThan
    /// Integer greater-than-or-equal comparison.
    case greaterOrEqual

    /// Whether the operation combines two Boolean operands into a Boolean.
    public var isLogical: Bool { self == .conjunction || self == .disjunction }

    /// Whether the operation combines two integer operands into an integer.
    public var isArithmetic: Bool {
        switch self {
        case .addition, .subtraction, .multiplication, .division, .modulo:
            return true
        default:
            return false
        }
    }

    /// Whether the operation compares two operands of the same type for (in)equality.
    public var isEquality: Bool { self == .equal || self == .notEqual }

    /// Whether the operation orders two integer operands.
    public var isComparison: Bool {
        switch self {
        case .lessThan, .lessOrEqual, .greaterThan, .greaterOrEqual:
            return true
        default:
            return false
        }
    }
}
