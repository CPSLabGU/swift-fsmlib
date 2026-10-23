//
//  ExpressionTyper.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// Turns host-language labels and sections into typed kernel nodes where
/// they lie in the supported subset.
///
/// The typer parses the text of a transition label or a state section with
/// the syntax of the machine language and resolves its names against a
/// ``Scope`` of declared variables and functions. Text that lies completely
/// within the subset and is well typed becomes typed kernel expressions and
/// statements; anything else, including text that parses only in part or
/// names an undeclared variable, becomes a single `OpaqueExpression` or
/// `OpaqueStatement` that carries the exact original text and the language.
/// The typer never guesses.
///
/// The subset of the C family (`c`, `c++`, `cpp`, `cxx`, `objc`, `objc++`
/// and `objcpp`) comprises the literals `true`, `false` and decimal
/// integers, declared variables, parentheses, `!` and unary `-`, the binary
/// operators `&&`, `||`, `==`, `!=`, `<`, `<=`, `>`, `>=`, `+`, `-`, `*`,
/// `/` and `%` with C precedence, the conditional `c ? a : b`, the time
/// helpers `timeout(e)`, `after(e)` and `after_ms(e)`, and calls `f(args)`
/// and `recv.f(args)` of declared functions; and the statements `x = e;`,
/// `x[i] = e;`, `f(args);`, `recv.f(args);`, `printf("text\n");` and
/// `puts("text");` with plain literal text. Swift and Java share the
/// operators and statements where their syntax coincides, and print with
/// `print("text")` and `System.out.println("text");`.
///
/// ```swift
/// let typer = ExpressionTyper(language: "c", scope: scope)
/// let label = await typer.condition(from: "counter < 10", in: resource, metamodel: sectioned)
/// let entry = await typer.statements(from: "counter = 0;", in: resource, metamodel: sectioned)
/// ```
public struct ExpressionTyper: Sendable {
    /// The type of a declared variable, parameter or function result.
    public indirect enum ValueType: Sendable, Hashable {
        /// The Boolean type.
        case boolean
        /// An integer type.
        case integer
        /// The enumeration type declared by the object with the given identifier.
        case enumeration(EUUID)
        /// The array type declared by the object with the given identifier.
        case array(EUUID, element: ValueType)
        /// The opaque type declared by the object with the given identifier.
        ///
        /// Values of an opaque type can only receive method calls of that type.
        case opaque(EUUID)
    }

    /// A declared variable that labels and sections may name.
    public struct Variable: Sendable, Hashable {
        /// The name of the variable.
        public var name: String
        /// The identifier of the kernel `Variable` object.
        public var identifier: EUUID
        /// The type of the variable.
        public var type: ValueType

        /// Create a variable declaration.
        ///
        /// - Parameters:
        ///   - name: The name of the variable.
        ///   - identifier: The identifier of the kernel `Variable` object.
        ///   - type: The type of the variable.
        public init(name: String, identifier: EUUID, type: ValueType) {
            self.name = name
            self.identifier = identifier
            self.type = type
        }
    }

    /// A declared function that labels and sections may call.
    public struct Function: Sendable, Hashable {
        /// The name of the function.
        public var name: String
        /// The identifier of the kernel `FunctionDeclaration` object.
        public var identifier: EUUID
        /// The types of the parameters, in order.
        public var parameters: [ValueType]
        /// The type of the result, or `nil` if the function returns nothing.
        public var result: ValueType?
        /// The type whose method the function is, or `nil` for a free function.
        public var receiverType: ValueType?
        /// Whether the function is pure, so that labels may call it.
        public var isPure: Bool

        /// Create a function declaration.
        ///
        /// - Parameters:
        ///   - name: The name of the function.
        ///   - identifier: The identifier of the kernel `FunctionDeclaration` object.
        ///   - parameters: The types of the parameters, in order.
        ///   - result: The type of the result, or `nil` if the function returns nothing.
        ///   - receiverType: The type whose method the function is, or `nil`.
        ///   - isPure: Whether labels may call the function.
        public init(
            name: String,
            identifier: EUUID,
            parameters: [ValueType] = [],
            result: ValueType? = nil,
            receiverType: ValueType? = nil,
            isPure: Bool = false
        ) {
            self.name = name
            self.identifier = identifier
            self.parameters = parameters
            self.result = result
            self.receiverType = receiverType
            self.isPure = isPure
        }
    }

    /// The declarations that names in labels and sections resolve to.
    ///
    /// Earlier declarations take precedence over later ones with the same
    /// name, so machine locals are listed before arrangement variables.
    public struct Scope: Sendable, Hashable {
        /// The declared variables, in order of precedence.
        public var variables: [Variable]
        /// The declared functions, in order of precedence.
        public var functions: [Function]

        /// Create a scope.
        ///
        /// - Parameters:
        ///   - variables: The declared variables, in order of precedence.
        ///   - functions: The declared functions, in order of precedence.
        public init(variables: [Variable] = [], functions: [Function] = []) {
            self.variables = variables
            self.functions = functions
        }

        /// The variable with a name, if it is declared.
        func variable(named name: String) -> Variable? {
            variables.first { $0.name == name }
        }

        /// The function with a name, if it is declared.
        func function(named name: String) -> Function? {
            functions.first { $0.name == name }
        }
    }

    /// The language of the text, such as `c` or `objc++`.
    public let language: String

    /// The declarations that names resolve to.
    public let scope: Scope

    /// Create a typer for a language and a scope.
    ///
    /// - Parameters:
    ///   - language: The machine language. Text of a language without a
    ///     syntax table is never typed.
    ///   - scope: The declarations that names resolve to.
    public init(language: String, scope: Scope) {
        self.language = language
        self.scope = scope
    }

    // MARK: - Typing Text

    /// The typed form of an expression, without creating model objects.
    ///
    /// - Parameter text: The host-language text of the expression.
    /// - Returns: The typed expression and its type, or `nil` if the text is
    ///   outside the subset or not well typed.
    func typedExpression(from text: String) -> (node: TypedNode, type: TypedValue)? {
        guard let syntax = HostSyntax.syntax(for: language),
              let tokens = HostLexer(syntax: syntax).tokens(of: text) else { return nil }
        var parser = HostParser(syntax: syntax, tokens: tokens)
        guard let expression = parser.completeExpression() else { return nil }
        return TypeResolver(syntax: syntax, scope: scope).resolve(expression, inLabel: false)
    }

    /// The typed form of a Boolean condition, without creating model objects.
    ///
    /// - Parameter text: The host-language text of the condition.
    /// - Returns: The typed condition, or `nil` if the text is outside the
    ///   subset, not well typed, not Boolean, or calls an impure function.
    func typedCondition(from text: String) -> TypedNode? {
        guard let syntax = HostSyntax.syntax(for: language),
              let tokens = HostLexer(syntax: syntax).tokens(of: text) else { return nil }
        var parser = HostParser(syntax: syntax, tokens: tokens)
        guard let expression = parser.completeExpression(),
              let (node, type) = TypeResolver(syntax: syntax, scope: scope).resolve(expression, inLabel: true),
              type == .boolean else { return nil }
        return node
    }

    /// The typed form of a sequence of statements, without creating model objects.
    ///
    /// - Parameter text: The host-language text of the statements.
    /// - Returns: The typed statements, empty for blank text, or `nil` if any
    ///   part of the text is outside the subset or not well typed.
    func typedStatements(from text: String) -> [TypedStatement]? {
        guard let syntax = HostSyntax.syntax(for: language),
              let tokens = HostLexer(syntax: syntax).tokens(of: text) else { return nil }
        var parser = HostParser(syntax: syntax, tokens: tokens)
        guard let statements = parser.completeStatements() else { return nil }
        let resolver = TypeResolver(syntax: syntax, scope: scope)
        var typed: [TypedStatement] = []
        for statement in statements {
            guard let resolved = resolver.resolve(statement) else { return nil }
            typed.append(resolved)
        }
        return typed
    }

    // MARK: - Creating Nodes

    /// Create the kernel node for an expression.
    ///
    /// - Parameters:
    ///   - text: The host-language text of the expression.
    ///   - resource: The resource that registers the created objects.
    ///   - metamodel: The sectioned metamodel whose classes are instantiated.
    /// - Returns: The root of the typed expression, or an `OpaqueExpression`
    ///   with the exact text and the language.
    public func expression(
        from text: String,
        in resource: Resource,
        metamodel: SectionedMetamodel
    ) async -> DynamicEObject {
        let builder = TypedNodeBuilder(metamodel: metamodel, resource: resource)
        guard let (node, _) = typedExpression(from: text) else {
            return await builder.opaqueExpression(text, language: language)
        }
        return await builder.make(node)
    }

    /// Create the kernel node for a transition label.
    ///
    /// A label types only if it is a Boolean expression that calls pure functions only.
    ///
    /// - Parameters:
    ///   - text: The host-language text of the label.
    ///   - resource: The resource that registers the created objects.
    ///   - metamodel: The sectioned metamodel whose classes are instantiated.
    /// - Returns: The root of the typed label, or an `OpaqueExpression`
    ///   with the exact text and the language.
    public func condition(
        from text: String,
        in resource: Resource,
        metamodel: SectionedMetamodel
    ) async -> DynamicEObject {
        let builder = TypedNodeBuilder(metamodel: metamodel, resource: resource)
        guard let node = typedCondition(from: text) else {
            return await builder.opaqueExpression(text, language: language)
        }
        return await builder.make(node)
    }

    /// Create the kernel nodes for the statements of a section.
    ///
    /// The section types only as a whole: if any statement lies outside the
    /// subset, the result is one `OpaqueStatement` with the whole text.
    ///
    /// - Parameters:
    ///   - text: The host-language text of the section.
    ///   - resource: The resource that registers the created objects.
    ///   - metamodel: The sectioned metamodel whose classes are instantiated.
    /// - Returns: The typed statements, none for blank text, or one
    ///   `OpaqueStatement` with the exact text and the language.
    public func statements(
        from text: String,
        in resource: Resource,
        metamodel: SectionedMetamodel
    ) async -> [DynamicEObject] {
        let builder = TypedNodeBuilder(metamodel: metamodel, resource: resource)
        guard let statements = typedStatements(from: text) else {
            return [await builder.opaqueStatement(text, language: language)]
        }
        var objects: [DynamicEObject] = []
        for statement in statements { objects.append(await builder.make(statement)) }
        return objects
    }
}
