//
//  HostParser.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//

/// An expression of the typed host-language subset, before name resolution.
indirect enum HostExpression: Equatable, Sendable {
    /// A Boolean literal.
    case boolean(Bool)
    /// A decimal integer literal.
    case integer(Int)
    /// A name, optionally indexed.
    case name(String, index: HostExpression?)
    /// A prefix operation.
    case unary(KernelUnaryOperation, HostExpression)
    /// A binary operation.
    case binary(KernelBinaryOperation, HostExpression, HostExpression)
    /// A conditional expression.
    case conditional(HostExpression, HostExpression, HostExpression)
    /// A call of a named function, optionally of a method of a receiver.
    case call(String, receiver: HostExpression?, arguments: [HostExpression])
}

/// A statement of the typed host-language subset, before name resolution.
enum HostStatement: Equatable, Sendable {
    /// An assignment to a name, optionally indexed.
    case assignment(String, index: HostExpression?, value: HostExpression)
    /// A call evaluated for its effect.
    case call(HostExpression)
    /// A call that prints one line of literal text.
    case print(String)
}

/// Parses host-language tokens into expressions and statements of the typed subset.
///
/// The parser follows the precedence levels and associativity of the
/// syntax table and fails, rather than guessing, on any construct outside
/// the subset or on input that is not consumed completely.
struct HostParser {
    /// The syntax table of the language.
    let syntax: HostSyntax

    /// The tokens being parsed.
    private var tokens: [HostToken]

    /// The position of the next token.
    private var position = 0

    /// Create a parser for a list of tokens.
    ///
    /// - Parameters:
    ///   - syntax: The syntax table of the language.
    ///   - tokens: The tokens to parse.
    init(syntax: HostSyntax, tokens: [HostToken]) {
        self.syntax = syntax
        self.tokens = tokens
    }

    // MARK: - Entry Points

    /// Parse the tokens as one complete expression.
    ///
    /// - Returns: The expression, or `nil` if the tokens are not exactly one expression.
    mutating func completeExpression() -> HostExpression? {
        skipLineBreaks()
        guard let expression = expression() else { return nil }
        skipLineBreaks()
        return position == tokens.count ? expression : nil
    }

    /// Parse the tokens as a sequence of statements.
    ///
    /// - Returns: The statements, or `nil` if any part of the tokens is not a statement.
    mutating func completeStatements() -> [HostStatement]? {
        var statements: [HostStatement] = []
        skipSeparators()
        while position < tokens.count {
            guard let statement = statement() else { return nil }
            statements.append(statement)
            if consume(.symbol(syntax.terminator)) || consume(.lineBreak) {
                skipSeparators()
            } else if position < tokens.count || syntax.requiresTerminator {
                return nil
            }
        }
        return statements
    }

    // MARK: - Statements

    /// Parse one statement without its terminator.
    private mutating func statement() -> HostStatement? {
        let start = position
        if let text = printStatement() { return .print(text) }
        position = start
        if case .identifier(let name)? = peek(), !syntax.booleanLiterals.keys.contains(name) {
            advance()
            var index: HostExpression?
            if consume(.symbol("[")) {
                guard let subscriptExpression = expression(), consume(.symbol("]")) else { return nil }
                index = subscriptExpression
            }
            if consume(.symbol(syntax.assignment)) {
                guard let value = expression() else { return nil }
                return .assignment(name, index: index, value: value)
            }
        }
        position = start
        guard let call = postfix(), case .call = call else { return nil }
        return .call(call)
    }

    /// Parse a call of a print form with a plain literal.
    ///
    /// - Returns: The text printed, without the line break, or `nil` if the
    ///   tokens are no such call.
    private mutating func printStatement() -> String? {
        for form in syntax.printForms {
            let start = position
            if let text = printCall(form) { return text }
            position = start
        }
        return nil
    }

    /// Parse a call of one print form with a plain literal.
    private mutating func printCall(_ form: HostSyntax.PrintForm) -> String? {
        for (offset, word) in form.callee.enumerated() {
            if offset > 0, !consume(.symbol(syntax.memberAccess)) { return nil }
            guard consume(.identifier(word)) else { return nil }
        }
        guard consume(.symbol("(")), case .string(let literal)? = peek() else { return nil }
        advance()
        guard consume(.symbol(")")) else { return nil }
        var text = literal
        if form.requiresTrailingNewline {
            guard text.hasSuffix(syntax.newlineEscape) else { return nil }
            text.removeLast(syntax.newlineEscape.count)
        }
        guard !text.contains(syntax.escape) else { return nil }
        if form.isFormat, text.contains(syntax.formatConversion) { return nil }
        return text
    }

    // MARK: - Expressions

    /// Parse an expression, including a conditional.
    private mutating func expression() -> HostExpression? {
        guard let condition = binary(level: 0) else { return nil }
        guard let conditional = syntax.conditional, consume(.symbol(conditional.question)) else {
            return condition
        }
        guard let whenTrue = expression(), consume(.symbol(conditional.colon)),
              let whenFalse = expression() else { return nil }
        return .conditional(condition, whenTrue, whenFalse)
    }

    /// Parse the operators of one precedence level and the levels above it.
    private mutating func binary(level: Int) -> HostExpression? {
        guard level < syntax.levels.count else { return unary() }
        let operators = syntax.levels[level].operators
        guard var left = binary(level: level + 1) else { return nil }
        var count = 0
        while case .symbol(let symbol)? = peek(), let operation = operators[symbol] {
            if syntax.levels[level].associativity == .none, count > 0 { return nil }
            advance()
            guard let right = binary(level: level + 1) else { return nil }
            left = .binary(operation, left, right)
            count += 1
        }
        return left
    }

    /// Parse a prefix operation or a postfix expression.
    private mutating func unary() -> HostExpression? {
        if case .symbol(let symbol)? = peek(), let operation = syntax.prefixOperators[symbol] {
            advance()
            guard let operand = unary() else { return nil }
            return .unary(operation, operand)
        }
        return postfix()
    }

    /// Parse a primary expression, a call, an index, or a method call.
    private mutating func postfix() -> HostExpression? {
        guard let token = peek() else { return nil }
        advance()
        let primary: HostExpression
        switch token {
        case .integer(let value):
            return .integer(value)
        case .identifier(let name):
            if let value = syntax.booleanLiterals[name] { return .boolean(value) }
            if consume(.symbol("(")) {
                guard let arguments = arguments() else { return nil }
                primary = .call(name, receiver: nil, arguments: arguments)
            } else if consume(.symbol("[")) {
                guard let index = expression(), consume(.symbol("]")) else { return nil }
                primary = .name(name, index: index)
            } else {
                primary = .name(name, index: nil)
            }
        case .symbol("("):
            guard let inner = expression(), consume(.symbol(")")) else { return nil }
            return inner
        default:
            return nil
        }
        guard consume(.symbol(syntax.memberAccess)) else { return primary }
        guard case .name = primary, case .identifier(let method)? = peek() else { return nil }
        advance()
        guard consume(.symbol("(")), let arguments = arguments() else { return nil }
        if case .symbol(syntax.memberAccess)? = peek() { return nil }
        return .call(method, receiver: primary, arguments: arguments)
    }

    /// Parse the arguments of a call after its opening parenthesis.
    private mutating func arguments() -> [HostExpression]? {
        var arguments: [HostExpression] = []
        if consume(.symbol(")")) { return arguments }
        repeat {
            guard let argument = expression() else { return nil }
            arguments.append(argument)
        } while consume(.symbol(","))
        return consume(.symbol(")")) ? arguments : nil
    }

    // MARK: - Tokens

    /// The next token, if any.
    private func peek() -> HostToken? {
        position < tokens.count ? tokens[position] : nil
    }

    /// Move past the next token.
    private mutating func advance() {
        position += 1
    }

    /// Move past the next token if it is the given one.
    ///
    /// - Parameter token: The expected token.
    /// - Returns: Whether the token was present.
    private mutating func consume(_ token: HostToken) -> Bool {
        guard peek() == token else { return false }
        advance()
        return true
    }

    /// Move past line breaks.
    private mutating func skipLineBreaks() {
        while consume(.lineBreak) {}
    }

    /// Move past line breaks and statement terminators.
    private mutating func skipSeparators() {
        while consume(.lineBreak) || consume(.symbol(syntax.terminator)) {}
    }
}
