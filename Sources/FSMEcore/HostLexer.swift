//
//  HostLexer.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//

/// A token of host-language text within the typed subset.
enum HostToken: Equatable, Sendable {
    /// An identifier or keyword.
    case identifier(String)
    /// A decimal integer literal.
    case integer(Int)
    /// A string literal with the text between its quotes, escapes unresolved.
    case string(String)
    /// An operator or punctuation token.
    case symbol(String)
    /// A line break, where line breaks end statements.
    case lineBreak
}

/// Splits host-language text into the tokens of the typed subset.
///
/// The lexer fails on anything outside the subset, such as comments,
/// preprocessor directives, character literals, and integer literals that
/// are not plain decimal numbers within the 32-bit range.
struct HostLexer {
    /// The syntax table of the language.
    let syntax: HostSyntax

    /// The tokens of a text.
    ///
    /// - Parameter text: The host-language text.
    /// - Returns: The tokens, or `nil` if the text lies outside the subset.
    func tokens(of text: String) -> [HostToken]? {
        let characters = Array(text)
        let symbols = syntax.tokens.map(Array.init)
        let comments = syntax.commentStarts.map(Array.init)
        var tokens: [HostToken] = []
        var position = 0
        func matches(_ candidate: [Character]) -> Bool {
            position + candidate.count <= characters.count
                && Array(characters[position..<(position + candidate.count)]) == candidate
        }
        while position < characters.count {
            let character = characters[position]
            if character.isNewline {
                if syntax.lineBreakEndsStatement, tokens.last != .lineBreak { tokens.append(.lineBreak) }
                position += 1
            } else if character.isWhitespace {
                position += 1
            } else if comments.contains(where: matches) {
                return nil
            } else if startsWord(character) {
                guard let scanned = scanWord(in: characters, from: position) else { return nil }
                tokens.append(scanned.token)
                position = scanned.end
            } else if let symbol = symbols.first(where: matches) {
                tokens.append(.symbol(String(symbol)))
                position += symbol.count
            } else {
                return nil
            }
        }
        return tokens
    }

    /// A token together with the position after its last character.
    private struct Scanned {
        /// The token that was scanned.
        let token: HostToken

        /// The position of the first character after the token.
        let end: Int
    }

    /// Whether a character starts an identifier, a number, or a string literal.
    ///
    /// - Parameter character: The character at the current position.
    /// - Returns: Whether the character starts a word.
    private func startsWord(_ character: Character) -> Bool {
        character.isLetter || character == "_" || (character.isASCII && character.isNumber) || character == syntax.quote
    }

    /// Scan an identifier, a number, or a string literal.
    ///
    /// - Parameters:
    ///   - characters: The characters of the text.
    ///   - position: The position of the word's first character.
    /// - Returns: The token, or `nil` if the word lies outside the subset.
    private func scanWord(in characters: [Character], from position: Int) -> Scanned? {
        let character = characters[position]
        if character.isLetter || character == "_" { return scanIdentifier(in: characters, from: position) }
        if character.isASCII, character.isNumber { return scanInteger(in: characters, from: position) }
        return scanString(in: characters, from: position)
    }

    /// Scan an identifier.
    ///
    /// - Parameters:
    ///   - characters: The characters of the text.
    ///   - position: The position of the identifier's first character.
    /// - Returns: The identifier token, or `nil` if it contains a character outside ASCII.
    private func scanIdentifier(in characters: [Character], from position: Int) -> Scanned? {
        var end = position
        while end < characters.count, characters[end].isLetter || characters[end].isNumber || characters[end] == "_" {
            guard characters[end].isASCII else { return nil }
            end += 1
        }
        return Scanned(token: .identifier(String(characters[position..<end])), end: end)
    }

    /// Scan a plain decimal integer within the 32-bit range.
    ///
    /// - Parameters:
    ///   - characters: The characters of the text.
    ///   - position: The position of the number's first digit.
    /// - Returns: The integer token, or `nil` if the number lies outside the subset.
    private func scanInteger(in characters: [Character], from position: Int) -> Scanned? {
        var end = position
        while end < characters.count, characters[end].isASCII, characters[end].isNumber { end += 1 }
        if end < characters.count, characters[end].isLetter || characters[end] == "_" || characters[end] == "." {
            return nil
        }
        let digits = String(characters[position..<end])
        guard digits.count == 1 || digits.first != "0", let value = Int(digits),
              value <= Int(Int32.max) else { return nil }
        return Scanned(token: .integer(value), end: end)
    }

    /// Scan a quoted string literal.
    ///
    /// - Parameters:
    ///   - characters: The characters of the text.
    ///   - position: The position of the opening quote.
    /// - Returns: The string token, or `nil` if the literal is unterminated or spans lines.
    private func scanString(in characters: [Character], from position: Int) -> Scanned? {
        var end = position + 1
        var body: [Character] = []
        while end < characters.count, characters[end] != syntax.quote {
            guard !characters[end].isNewline else { return nil }
            if characters[end] == syntax.escape {
                guard end + 1 < characters.count else { return nil }
                body.append(characters[end])
                end += 1
            }
            body.append(characters[end])
            end += 1
        }
        guard end < characters.count else { return nil }
        return Scanned(token: .string(String(body)), end: end + 1)
    }
}
