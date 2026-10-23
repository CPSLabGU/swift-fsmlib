//
//  VariableDeclarationScanner.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//

/// Recognises simple variable declarations in host-language declaration text.
///
/// The scanner reads the text line by line. A line that declares exactly
/// one variable of a simple type, such as `int counter;`, `bool flag;`,
/// `unsigned ticks;` or `int samples[4];`, optionally followed by a `///<`
/// documentation comment, is recognised; every other line, including
/// comments, blank lines and declarations with initialisers or several
/// names, is kept verbatim. The kernel types are conservative: `int` and
/// `signed` have the 32-bit range, `unsigned` the non-negative part of it,
/// and `bool` is Boolean.
///
/// ```swift
/// let scan = VariableDeclarationScanner(language: "c").scan("int\tcounter;\t///< Bean counter\n")
/// // scan.declarations == [.init(name: "counter", type: .integer(name: "int", range: ...))]
/// ```
public struct VariableDeclarationScanner: Sendable {
    /// A recognised variable declaration.
    public struct Declaration: Sendable, Hashable {
        /// The name of the variable.
        public var name: String
        /// The kernel type of the variable.
        public var type: ScannedType

        /// Create a declaration.
        ///
        /// - Parameters:
        ///   - name: The name of the variable.
        ///   - type: The kernel type of the variable.
        public init(name: String, type: ScannedType) {
            self.name = name
            self.type = type
        }
    }

    /// The outcome of scanning declaration text.
    public struct Result: Sendable, Hashable {
        /// The recognised declarations, in text order.
        public var declarations: [Declaration]
        /// The lines that were not recognised, joined by line breaks.
        public var remainder: String
    }

    /// The language of the declaration text.
    public let language: String

    /// Create a scanner for a language.
    ///
    /// - Parameter language: The machine language. Text of a language
    ///   without simple declaration types is kept verbatim.
    public init(language: String) {
        self.language = language
    }

    /// Scan declaration text.
    ///
    /// - Parameter text: The host-language declarations.
    /// - Returns: The recognised declarations and the remaining text.
    public func scan(_ text: String) -> Result {
        guard let syntax = HostSyntax.syntax(for: language), !syntax.declarationTypes.isEmpty else {
            return Result(declarations: [], remainder: text)
        }
        var declarations: [Declaration] = []
        var remaining: [Substring] = []
        var names = Set<String>()
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if let declaration = declaration(in: line, syntax: syntax), names.insert(declaration.name).inserted {
                declarations.append(declaration)
            } else {
                remaining.append(line)
            }
        }
        return Result(declarations: declarations, remainder: remaining.joined(separator: "\n"))
    }

    /// The declaration on one line, if the line holds exactly one simple declaration.
    private func declaration(in line: Substring, syntax: HostSyntax) -> Declaration? {
        var code = line
        if let comment = line.range(of: syntax.declarationComment) {
            code = line[..<comment.lowerBound]
        }
        guard let terminator = code.lastIndex(of: Character(syntax.terminator)),
              code[code.index(after: terminator)...].allSatisfy(\.isWhitespace) else { return nil }
        let words = Self.words(of: code[..<terminator])
        guard let words else { return nil }
        var size: Int?
        var parts = words
        if parts.count >= 4, parts[parts.count - 3] == "[", parts.last == "]" {
            guard let count = Int(parts[parts.count - 2]), count > 0, count <= Int(Int32.max) else { return nil }
            size = count
            parts.removeLast(3)
        }
        guard let name = parts.popLast(), Self.isIdentifier(name),
              let type = syntax.declarationTypes.first(where: { $0.words == parts }),
              !syntax.declarationTypes.contains(where: { $0.words == [name] }) else { return nil }
        let kernelType = size.map { ScannedType.array(element: type.kernelType, size: $0) } ?? type.kernelType
        return Declaration(name: name, type: kernelType)
    }

    /// The words and brackets of a declaration, or `nil` if it holds other characters.
    private static func words(of text: Substring) -> [String]? {
        var words: [String] = []
        var current = ""
        for character in text {
            if character.isASCII, character.isLetter || character.isNumber || character == "_" {
                current.append(character)
                continue
            }
            if !current.isEmpty { words.append(current); current = "" }
            if character == "[" || character == "]" {
                words.append(String(character))
            } else if !character.isWhitespace {
                return nil
            }
        }
        if !current.isEmpty { words.append(current) }
        return words
    }

    /// Whether a word is an identifier.
    private static func isIdentifier(_ word: String) -> Bool {
        guard let first = word.first, first.isLetter || first == "_" else { return false }
        return word.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_") }
    }
}
