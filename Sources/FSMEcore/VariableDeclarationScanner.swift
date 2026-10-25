//
//  VariableDeclarationScanner.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

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
/// Every recognised declaration also records its ``Placement``: the line it
/// was found on, its verbatim text and the text of its documentation
/// comment. ``merged(remainder:placements:)`` puts the placements back
/// into the remaining text, which gives back the scanned text exactly.
///
/// ```swift
/// let scan = VariableDeclarationScanner(language: "c").scan("int\tcounter;\t///< Bean counter\n")
/// // scan.declarations == [.init(name: "counter", type: .integer(name: "int", range: ...))]
/// // scan.placements == [.init(line: 0, text: "int\tcounter;\t///< Bean counter", documentation: "Bean counter")]
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

    /// Where and how a recognised declaration was written.
    public struct Placement: Sendable, Hashable {
        /// The zero-based index of the line that holds the declaration.
        public var line: Int
        /// The line as written, without its line break.
        public var text: String
        /// The text of the documentation comment that follows the
        /// declaration, without the comment marker and surrounding white
        /// space, or `nil` if there is no comment or it is empty.
        public var documentation: String?

        /// Create a placement.
        ///
        /// - Parameters:
        ///   - line: The zero-based index of the line that holds the declaration.
        ///   - text: The line as written, without its line break.
        ///   - documentation: The text of the documentation comment, if any.
        public init(line: Int, text: String, documentation: String?) {
            self.line = line
            self.text = text
            self.documentation = documentation
        }
    }

    /// The outcome of scanning declaration text.
    public struct Result: Sendable, Hashable {
        /// The recognised declarations, in text order.
        public var declarations: [Declaration]
        /// The placements of the recognised declarations, in the order of ``declarations``.
        public var placements: [Placement]
        /// The lines that were not recognised, joined by line breaks.
        public var remainder: String
        /// The number of lines that were not recognised.
        ///
        /// The count tells a ``remainder`` that holds one empty line, as
        /// left by a text that ends with a line break, from one that holds
        /// no line at all.
        public var remainderLineCount: Int
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
        let lines = Self.lines(of: text)
        guard let syntax = HostSyntax.syntax(for: language), !syntax.declarationTypes.isEmpty else {
            return Result(declarations: [], placements: [], remainder: text, remainderLineCount: lines.count)
        }
        var declarations: [Declaration] = []
        var placements: [Placement] = []
        var remaining: [Substring] = []
        var names = Set<String>()
        for (index, line) in lines.enumerated() {
            if let declaration = declaration(in: line, syntax: syntax), names.insert(declaration.name).inserted {
                declarations.append(declaration)
                placements.append(Placement(
                    line: index, text: String(line), documentation: documentation(in: line, syntax: syntax)))
            } else {
                remaining.append(line)
            }
        }
        return Result(
            declarations: declarations,
            placements: placements,
            remainder: remaining.joined(separator: "\n"),
            remainderLineCount: remaining.count
        )
    }

    /// Put recognised declarations back into the text that remained after a scan.
    ///
    /// Each placement is inserted as the line with its index, so that
    /// merging the ``Result/placements`` of a scan into its
    /// ``Result/remainder`` gives back the scanned text. A placement whose
    /// line lies beyond the end of the text is appended, in line order.
    ///
    /// - Parameters:
    ///   - remainder: The lines that were not recognised, joined by line
    ///     breaks, or `nil` if no line remained.
    ///   - placements: The placements of the declarations to insert.
    /// - Returns: The text with the declarations at their lines.
    public static func merged(remainder: String?, placements: [Placement]) -> String {
        let remaining = remainder.map(lines(of:)) ?? []
        let placed = placements.enumerated().sorted { ($0.element.line, $0.offset) < ($1.element.line, $1.offset) }
            .map(\.element)
        var result: [Substring] = []
        var nextPlacement = placed.startIndex
        var nextLine = remaining.startIndex
        while nextPlacement < placed.endIndex || nextLine < remaining.endIndex {
            if nextPlacement < placed.endIndex,
               placed[nextPlacement].line <= result.count || nextLine == remaining.endIndex {
                result.append(Substring(placed[nextPlacement].text))
                nextPlacement += 1
            } else {
                result.append(remaining[nextLine])
                nextLine += 1
            }
        }
        return result.joined(separator: "\n")
    }

    /// The lines of a text, including an empty last line after a final line break.
    private static func lines(of text: String) -> [Substring] {
        text.split(separator: "\n", omittingEmptySubsequences: false)
    }

    /// The text of the documentation comment on a line, if it has a non-empty one.
    private func documentation(in line: Substring, syntax: HostSyntax) -> String? {
        guard let comment = line.range(of: syntax.declarationComment) else { return nil }
        let text = line[comment.upperBound...].trimmingCharacters(in: .whitespaces)
        return text.isEmpty ? nil : text
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
