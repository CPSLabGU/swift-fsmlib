//
//  CodeBuilder.swift
//
//  Created by Rene Hexel on 16/8/2023.
//  Copyright © 2023, 2025 Rene Hexel. All rights reserved.
//

/// Source code.
public typealias Code = String

/// Extension providing convenience properties for accessing and mutating
/// code.
extension Code {
    /// Marker for ignored code segments.
    ///
    /// This static constant is used to denote code segments that should be
    /// ignored during code generation or processing. It helps to identify
    /// and skip over sections not relevant for the current operation.
    ///
    /// - Note: Useful for code transformation or filtering tasks.
    ///
    /// - SeeAlso: `CodeBuilder`
    ///
    /// - Warning: Ensure this marker does not appear in user code unintentionally.
    ///
    /// - Returns: The ignored code marker string.
    @usableFromInline
    static let ignored = "\n%%i%%\n"
    /// Four-space indentation
    @usableFromInline
    static let fourSpaces = "    "
    /// A code block.
    /// - Parameters:
    ///   - codeBuilder: The original code builder.
    /// - Returns: The indented code.
    static func block(@CodeBuilder codeBuilder: () -> Code) -> Code {
        codeBuilder()
    }
    /// Indented block.
    /// - Parameters:
    ///   - indentation: The indentation to use.
    ///   - codeBuilder: The original code builder.
    /// - Returns: The indented code.
    static func indentedBlock(with indentation: String = fourSpaces, @CodeBuilder codeBuilder: () -> Code) -> Code {
        codeBuilder()
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { indentation + $0 }
            .joined(separator: "\n")
    }
    /// Braced block.
    /// - Parameters:
    ///   - indentation: The indentation to use.
    ///   - codeBuilder: The original code builder.
    /// - Returns: The indented code.
    static func bracedBlock(with indentation: String = fourSpaces, @CodeBuilder codeBuilder: () -> Code) -> Code {
        "{\n" + codeBuilder()
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { indentation + $0 }
            .joined(separator: "\n") +
        "\n}"
    }
    /// Bracketed block.
    /// - Parameters:
    ///   - indentation: The indentation to use.
    ///   - codeBuilder: The original code builder.
    ///   - openingBracket: The opening bracket to use.
    ///   - closingBracket: The closing bracket to use.
    /// - Returns: The indented code.
    static func bracketedBlock(with indentation: String = fourSpaces, openingBracket: String = "[\n", closingBracket: String = "\n]", @CodeBuilder codeBuilder: () -> Code) -> Code {
        openingBracket + codeBuilder()
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { indentation + $0 }
            .joined(separator: "\n") + "\n" +
        closingBracket
    }
    /// C/C++/Objective-C Include File.
    /// - Parameters:
    ///   - indentation: The indentation to use.
    ///   - codeBuilder: The original code builder.
    ///   - openingBracket: The opening bracket to use.
    ///   - closingBracket: The closing bracket to use.
    /// - Returns: The indented code.
    static func includeFile(named name: String, @CodeBuilder codeBuilder: () -> Code) -> Code {
        var isFirst = true
        let defineName = name.uppercased().split {
            guard !isFirst else {
                isFirst = false
                return !($0.isASCII && $0.isLetter)
            }
            return !($0.isASCII && ($0.isNumber || $0.isLetter))
        }.joined(separator: "_")
        return .block {
            "#ifndef \(defineName)"
            "#define \(defineName)"
            ""
            codeBuilder()
            ""
            "#endif /* \(defineName) */\n"
        }
    }
    /// Create code iterating over the given array.
    ///
    /// - Parameters:
    ///   - collection: The collection to iterate over.
    ///   - codeBuilder: The code builder transforming the array into code.
    /// - Returns: The code resulting from iterating over the array.
    static func forEach<Element>(_ collection: some Collection<Element>, @CodeBuilder codeBuilder: (Element) -> Code) -> Code {
        guard !collection.isEmpty else { return .ignored }
        return collection.map(codeBuilder).joined(separator: "\n")
    }
    /// Create code enumerating the given array.
    ///
    /// - Parameters:
    ///   - array: The array to enumerate.
    ///   - codeBuilder: The code builder transforming the array into code.
    /// - Returns: The code resulting from iterating over the array.
    static func enumerating<Element>(array: [Element], @CodeBuilder codeBuilder: (Int, Element) -> Code) -> Code {
        guard !array.isEmpty else { return .ignored }
        return array.enumerated().map(codeBuilder).joined(separator: "\n")
    }
}

/// Result builder for constructing source code blocks.
///
/// This result builder enables the declarative construction of source code by
/// joining lines, handling optionals, and supporting conditional code
/// generation. It is used to build up code blocks in a readable and
/// maintainable way, filtering out ignored lines and supporting conditional and
/// optional code fragments.
///
/// - Note: This is particularly useful for code generation tasks where code
///         structure needs to be composed programmatically, such as when
///         generating C, C++, or Objective-C code from Swift.
@resultBuilder
struct CodeBuilder {
    /// Join lines of code.
    ///
    /// This function joins the lines of code provided,
    /// filtering out any `ignored` lines.
    ///
    /// - Parameter lines: The lines of code to join.
    /// - Returns: The lines of code joined by newlines.
    @usableFromInline
    static func buildBlock(_ lines: Code...) -> Code {
        lines.lazy.filter { $0 != Code.ignored }.joined(separator: "\n")
    }
    /// Build the given code if non-`nil`.
    ///
    /// - Parameter code: The line of code to return (or `nil` to ignore).
    /// - Returns: The line of code or `.ignored` if `nil`.
    static func buildIf(_ code: Code?) -> Code { code ?? .ignored }
    /// Return the given line of code, ignoring optionals.
    ///
    /// - Parameter code: The line of code to return (or `nil` to ignore).
    /// - Returns: The line of code or `.ignored` if `nil`.
    static func buildOptional(_ code: Code?) -> Code { code ?? .ignored }
    /// Return the first line of code.
    /// - Parameter first: The first line of code.
    /// - Returns: The first line of code.
    @usableFromInline
    static func buildEither(first: Code) -> Code { first }
    /// Return the second line of code.
    /// - Parameter second: The second line of code.
    /// - Returns: The second line of code.
    @usableFromInline
    static func buildEither(second: Code) -> Code { second }
}
