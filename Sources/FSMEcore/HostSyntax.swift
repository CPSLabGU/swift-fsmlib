//
//  HostSyntax.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//

/// The host-language syntax that ``ExpressionTyper`` and
/// ``VariableDeclarationScanner`` recognise, as data.
///
/// Each table describes the subset of one family of host languages that maps
/// onto typed kernel nodes: operators and their precedence, literals, the
/// time helpers of the traditional engines, the forms that print a line, the
/// statement separators and the simple declaration types. Languages without
/// a table are never typed.
struct HostSyntax: Sendable {
    /// How the operators of one precedence level group.
    enum Associativity: Sendable {
        /// `a op b op c` groups as `(a op b) op c`.
        case left
        /// `a op b op c` is not part of the subset.
        case none
    }

    /// The binary operators of one precedence level.
    struct Level: Sendable {
        /// The operator tokens and the kernel operations they denote.
        let operators: [String: KernelBinaryOperation]
        /// How chains of operators of this level group.
        let associativity: Associativity
    }

    /// A call that prints one line of literal text.
    struct PrintForm: Sendable {
        /// The dotted name of the function, such as `["printf"]`.
        let callee: [String]
        /// Whether the literal must end with an escaped newline, which is not printed.
        let requiresTrailingNewline: Bool
        /// Whether the literal is a format whose conversion character must not occur.
        let isFormat: Bool
    }

    /// A simple declaration type and the kernel type it denotes.
    struct DeclarationType: Sendable {
        /// The words of the type, such as `["unsigned", "int"]`.
        let words: [String]
        /// The kernel type that a variable of this type receives.
        let kernelType: ScannedType
    }

    /// The language names that the table applies to.
    let languages: Set<String>

    /// The binary operator levels, from the loosest to the tightest binding.
    let levels: [Level]

    /// The prefix operators and the kernel operations they denote.
    let prefixOperators: [String: KernelUnaryOperation]

    /// The tokens of the conditional operator, if the languages have one.
    let conditional: (question: String, colon: String)?

    /// The Boolean literals.
    let booleanLiterals: [String: Bool]

    /// The helpers that compare the time since the current state was entered.
    ///
    /// A call `name(e)` holds once the time in the given unit exceeds `e`.
    let timeHelpers: [String: SectionedTimeUnit]

    /// The calls that print a line of literal text.
    let printForms: [PrintForm]

    /// The token that ends a statement.
    let terminator: String

    /// Whether every statement must end with the terminator.
    let requiresTerminator: Bool

    /// Whether a line break also ends a statement.
    let lineBreakEndsStatement: Bool

    /// The assignment token.
    let assignment: String

    /// The token that selects a method of a receiver.
    let memberAccess: String

    /// The punctuation that delimits calls, indices, arguments and groups.
    let punctuation: [String]

    /// The simple declaration types.
    let declarationTypes: [DeclarationType]

    /// The marker that starts a trailing documentation comment of a declaration.
    let declarationComment: String

    /// The character that starts a conversion in a format literal.
    let formatConversion: Character

    /// The escape character of string literals.
    let escape: Character

    /// The escape sequence of a line break in a string literal.
    let newlineEscape: String

    /// The quote that delimits string literals.
    let quote: Character

    /// The tokens that start comments, which are outside the subset.
    let commentStarts: [String]

    /// Every operator and punctuation token, longest first.
    var tokens: [String] {
        var all = Set(levels.flatMap(\.operators.keys))
        all.formUnion(prefixOperators.keys)
        if let conditional { all.formUnion([conditional.question, conditional.colon]) }
        all.formUnion(punctuation)
        all.formUnion([terminator, assignment, memberAccess])
        return all.sorted { $0.count != $1.count ? $0.count > $1.count : $0 < $1 }
    }

    /// The table that applies to a language.
    ///
    /// - Parameter language: The language name, such as `c` or `objc++`.
    /// - Returns: The table, or `nil` if the language is never typed.
    static func syntax(for language: String) -> HostSyntax? {
        all.first { $0.languages.contains(language) }
    }

    /// The tables of all supported language families.
    static let all: [HostSyntax] = [cFamily, swift, java]

    /// The integer range of the C `int` type in kernel models.
    static let intRange = Int(Int32.min)...Int(Int32.max)

    /// The integer range of the C `unsigned` type in kernel models.
    ///
    /// Kernel integer bounds are 32-bit signed integers, so the range ends at
    /// the largest such integer.
    static let unsignedRange = 0...Int(Int32.max)

    /// The levels of the C family, which Java shares.
    private static let cLevels: [Level] = [
        Level(operators: ["||": .disjunction], associativity: .left),
        Level(operators: ["&&": .conjunction], associativity: .left),
        Level(operators: ["==": .equal, "!=": .notEqual], associativity: .left),
        Level(operators: ["<": .lessThan, "<=": .lessOrEqual, ">": .greaterThan, ">=": .greaterOrEqual],
              associativity: .left),
        Level(operators: ["+": .addition, "-": .subtraction], associativity: .left),
        Level(operators: ["*": .multiplication, "/": .division, "%": .modulo], associativity: .left),
    ]

    /// The prefix operators of the C family, Swift and Java.
    private static let prefixes: [String: KernelUnaryOperation] = ["!": .negation, "-": .minus]

    /// The punctuation of the C family, Swift and Java.
    private static let delimiters = ["(", ")", "[", "]", ","]

    /// The Boolean literals of the C family, Swift and Java.
    private static let booleans = ["true": true, "false": false]

    /// The comment starts of the C family, Swift and Java.
    private static let comments = ["//", "/*"]

    /// The C family: C, C++, Objective-C and Objective-C++.
    static let cFamily = HostSyntax(
        languages: ["c", "c++", "cpp", "cxx", "objc", "objc++", "objcpp"],
        levels: cLevels,
        prefixOperators: prefixes,
        conditional: ("?", ":"),
        booleanLiterals: booleans,
        timeHelpers: ["timeout": .microseconds, "after": .seconds, "after_ms": .milliseconds],
        printForms: [
            PrintForm(callee: ["printf"], requiresTrailingNewline: true, isFormat: true),
            PrintForm(callee: ["puts"], requiresTrailingNewline: false, isFormat: false),
        ],
        terminator: ";",
        requiresTerminator: true,
        lineBreakEndsStatement: false,
        assignment: "=",
        memberAccess: ".",
        punctuation: delimiters,
        declarationTypes: [
            DeclarationType(words: ["int"], kernelType: .integer(name: "int", range: intRange)),
            DeclarationType(words: ["signed", "int"], kernelType: .integer(name: "int", range: intRange)),
            DeclarationType(words: ["signed"], kernelType: .integer(name: "int", range: intRange)),
            DeclarationType(words: ["unsigned", "int"],
                            kernelType: .integer(name: "unsigned", range: unsignedRange)),
            DeclarationType(words: ["unsigned"], kernelType: .integer(name: "unsigned", range: unsignedRange)),
            DeclarationType(words: ["bool"], kernelType: .boolean(name: "bool")),
        ],
        declarationComment: "///<",
        formatConversion: "%",
        escape: "\\",
        newlineEscape: "\\n",
        quote: "\"",
        commentStarts: comments
    )

    /// Swift, whose comparison operators share one non-associative level.
    static let swift = HostSyntax(
        languages: ["swift"],
        levels: [
            Level(operators: ["||": .disjunction], associativity: .left),
            Level(operators: ["&&": .conjunction], associativity: .left),
            Level(operators: ["==": .equal, "!=": .notEqual, "<": .lessThan, "<=": .lessOrEqual,
                              ">": .greaterThan, ">=": .greaterOrEqual], associativity: .none),
            Level(operators: ["+": .addition, "-": .subtraction], associativity: .left),
            Level(operators: ["*": .multiplication, "/": .division, "%": .modulo], associativity: .left),
        ],
        prefixOperators: prefixes,
        conditional: ("?", ":"),
        booleanLiterals: booleans,
        timeHelpers: [:],
        printForms: [PrintForm(callee: ["print"], requiresTrailingNewline: false, isFormat: false)],
        terminator: ";",
        requiresTerminator: false,
        lineBreakEndsStatement: true,
        assignment: "=",
        memberAccess: ".",
        punctuation: delimiters,
        declarationTypes: [],
        declarationComment: "///<",
        formatConversion: "%",
        escape: "\\",
        newlineEscape: "\\n",
        quote: "\"",
        commentStarts: comments
    )

    /// Java, which shares the operator levels of the C family.
    static let java = HostSyntax(
        languages: ["java"],
        levels: cLevels,
        prefixOperators: prefixes,
        conditional: ("?", ":"),
        booleanLiterals: booleans,
        timeHelpers: [:],
        printForms: [PrintForm(callee: ["System", "out", "println"], requiresTrailingNewline: false, isFormat: false)],
        terminator: ";",
        requiresTerminator: true,
        lineBreakEndsStatement: false,
        assignment: "=",
        memberAccess: ".",
        punctuation: delimiters,
        declarationTypes: [],
        declarationComment: "///<",
        formatConversion: "%",
        escape: "\\",
        newlineEscape: "\\n",
        quote: "\"",
        commentStarts: comments
    )
}

/// The kernel type of a recognised host-language declaration.
public enum ScannedType: Sendable, Hashable {
    /// A Boolean type with the given kernel type name.
    case boolean(name: String)
    /// An integer type with the given kernel type name and range.
    case integer(name: String, range: ClosedRange<Int>)
    /// A fixed-size array of a scalar type.
    indirect case array(element: ScannedType, size: Int)

    /// The name of the kernel type.
    ///
    /// An array type is named after its element type and its size, such as `intArray4`.
    public var name: String {
        switch self {
        case .boolean(let name), .integer(let name, _): return name
        case .array(let element, let size): return element.name + ScannedType.arrayInfix + String(size)
        }
    }

    /// The word that joins the element type and the size in the name of an array type.
    public static let arrayInfix = "Array"
}
