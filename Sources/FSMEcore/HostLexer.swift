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
            } else if character.isLetter || character == "_" {
                var end = position
                while end < characters.count, characters[end].isLetter || characters[end].isNumber || characters[end] == "_" {
                    guard characters[end].isASCII else { return nil }
                    end += 1
                }
                tokens.append(.identifier(String(characters[position..<end])))
                position = end
            } else if character.isASCII, character.isNumber {
                var end = position
                while end < characters.count, characters[end].isASCII, characters[end].isNumber { end += 1 }
                if end < characters.count, characters[end].isLetter || characters[end] == "_" || characters[end] == "." {
                    return nil
                }
                let digits = String(characters[position..<end])
                guard digits.count == 1 || digits.first != "0", let value = Int(digits),
                      value <= Int(Int32.max) else { return nil }
                tokens.append(.integer(value))
                position = end
            } else if character == syntax.quote {
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
                tokens.append(.string(String(body)))
                position = end + 1
            } else if let symbol = symbols.first(where: matches) {
                tokens.append(.symbol(String(symbol)))
                position += symbol.count
            } else {
                return nil
            }
        }
        return tokens
    }
}
