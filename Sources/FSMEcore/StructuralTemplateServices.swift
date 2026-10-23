//
//  StructuralTemplateServices.swift
//  FSMEcore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import AQL
import ECore
import Foundation
import MTL

/// The names of the services that ``StructuralTemplateServices`` offers.
public enum StructuralTemplateServiceName {
    /// The service `number.formatted('spec')`, which formats a number with a C format specification.
    public static let formatted = "formatted"

    /// The service `text.base64Decoded('charset')`, which decodes Base64 text into a string.
    public static let base64Decoded = "base64Decoded"

    /// The service `object.eIsSet('feature')`, which tells whether a feature of a model object has been set.
    public static let eIsSet = "eIsSet"
}

/// The problems found by the template services.
public enum StructuralTemplateServicesError: Error, LocalizedError, Equatable, Sendable {
    /// The format specification is not a single numeric conversion.
    case invalidFormat(String)

    /// An integer conversion was applied to a number with a fractional part.
    case notIntegral(String)

    /// The text is not valid Base64.
    case invalidBase64

    /// The decoded bytes cannot be read in the given character set.
    case undecodable(String)

    /// A description of the problem.
    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let format):
            return "Invalid number format '\(format)': expected exactly one numeric conversion"
        case .notIntegral(let format):
            return "The number format '\(format)' needs a whole number"
        case .invalidBase64:
            return "The text is not valid Base64"
        case .undecodable(let charset):
            return "The decoded bytes are not valid \(charset) text"
        }
    }
}

/// Text services that the structural templates use in addition to the AQL library.
///
/// The services are independent of any target language:
/// - `number.formatted('spec')` formats a number with a C format specification
///   that contains exactly one conversion out of `d`, `i`, `o`, `u`, `x`, `X`
///   (whole numbers) or `e`, `E`, `f`, `F`, `g`, `G`, `a`, `A` (any number),
///   optionally preceded by flags, a field width and a precision. Text around
///   the conversion is copied, and `%%` writes a percent sign. Formatting does
///   not depend on the locale.
/// - `text.base64Decoded('charset')` decodes Base64 text and reads the bytes in
///   a character set that a `file` block can write, such as `UTF-8`, or
///   `ISO-8859-1` to carry arbitrary bytes into a file written in that charset.
/// - `object.eIsSet('feature')` tells whether a feature of a model object has
///   been set, so that a feature that was never set can be told apart from one
///   set to its default value.
public struct StructuralTemplateServices: AQLServiceProvider {
    /// The conversions that format whole numbers.
    static let integerConversions: Set<Character> = ["d", "i", "o", "u", "x", "X"]

    /// The conversions that format floating point numbers.
    static let realConversions: Set<Character> = ["e", "E", "f", "F", "g", "G", "a", "A"]

    /// The flags allowed in a format specification.
    static let flags: Set<Character> = ["-", "+", " ", "#", "0"]

    /// The character that introduces a conversion.
    static let conversionMarker: Character = "%"

    /// The length modifier used to pass whole numbers at their full width.
    static let integerLengthModifier = "ll"

    /// The largest number of digits allowed in a field width or a precision.
    static let maximumDigits = 3

    /// Create the services.
    public init() {}

    /// Format a number with a C format specification.
    ///
    /// - Parameters:
    ///   - number: The number to format.
    ///   - format: A specification with exactly one numeric conversion.
    /// - Returns: The formatted text.
    /// - Throws: ``StructuralTemplateServicesError/invalidFormat(_:)`` if the specification
    ///   does not contain exactly one supported conversion, and
    ///   ``StructuralTemplateServicesError/notIntegral(_:)`` if a whole number conversion is
    ///   applied to a number with a fractional part.
    public static func format(_ number: Double, with format: String) throws -> String {
        let specification = try ConversionSpecification(parsing: format)
        if integerConversions.contains(specification.conversion) {
            guard let integer = Int64(exactly: number) else {
                throw StructuralTemplateServicesError.notIntegral(format)
            }
            return String(format: specification.format(lengthModifier: integerLengthModifier), integer)
        }
        return String(format: specification.format(lengthModifier: ""), number)
    }

    /// Format a whole number with a C format specification.
    ///
    /// - Parameters:
    ///   - number: The number to format.
    ///   - format: A specification with exactly one numeric conversion.
    /// - Returns: The formatted text.
    /// - Throws: ``StructuralTemplateServicesError/invalidFormat(_:)`` if the specification
    ///   does not contain exactly one supported conversion.
    public static func format(_ number: Int, with format: String) throws -> String {
        let specification = try ConversionSpecification(parsing: format)
        if integerConversions.contains(specification.conversion) {
            return String(format: specification.format(lengthModifier: integerLengthModifier), Int64(number))
        }
        return String(format: specification.format(lengthModifier: ""), Double(number))
    }

    /// Decode Base64 text into a string.
    ///
    /// - Parameters:
    ///   - text: The Base64 text.
    ///   - charset: The character set to read the decoded bytes in.
    /// - Returns: The decoded string.
    /// - Throws: ``StructuralTemplateServicesError/invalidBase64`` if the text is not Base64,
    ///   ``StructuralTemplateServicesError/undecodable(_:)`` if the bytes are not valid in the
    ///   character set, and an error if the character set is not supported.
    public static func base64Decode(_ text: String, charset: String) throws -> String {
        guard let data = Data(base64Encoded: text, options: .ignoreUnknownCharacters) else {
            throw StructuralTemplateServicesError.invalidBase64
        }
        guard let decoded = try MTLCharset.resolve(charset).decode(data) else {
            throw StructuralTemplateServicesError.undecodable(charset)
        }
        return decoded
    }

    /// The services offered: `formatted`, `base64Decoded` and `eIsSet`.
    public var services: [AQLService] {
        [
            AQLService(StructuralTemplateServiceName.formatted, receiver: .number, arity: 1) { call in
                let format = try call.string(0)
                switch call.receiver {
                case let integer as Int: return try Self.format(integer, with: format)
                case let real as Double: return try Self.format(real, with: format)
                case let real as Float: return try Self.format(Double(real), with: format)
                default:
                    guard let integer = AQLValues.integer(call.receiver) else {
                        throw StructuralTemplateServicesError.invalidFormat(format)
                    }
                    return try Self.format(integer, with: format)
                }
            },
            AQLService(StructuralTemplateServiceName.base64Decoded, receiver: .string, arity: 1) { call in
                try Self.base64Decode(try call.receiverString(), charset: try call.string(0))
            },
            AQLService(StructuralTemplateServiceName.eIsSet, receiver: .object, arity: 1) { call in
                let feature = try call.string(0)
                guard let object = call.receiver as? DynamicEObject else { return false }
                return object.eIsSet(feature)
            },
        ]
    }
}

/// A C format specification with exactly one numeric conversion.
struct ConversionSpecification {
    /// The text before the conversion, with `%%` kept as written.
    let prefix: String
    /// The flags, field width and precision of the conversion.
    let modifiers: String
    /// The conversion character.
    let conversion: Character
    /// The text after the conversion, with `%%` kept as written.
    let suffix: String

    /// Parse a format specification.
    ///
    /// - Parameter format: The specification to parse.
    /// - Throws: ``StructuralTemplateServicesError/invalidFormat(_:)`` unless the
    ///   specification contains exactly one supported conversion.
    init(parsing format: String) throws {
        let marker = StructuralTemplateServices.conversionMarker
        let characters = Array(format)
        var index = 0
        var prefix = ""
        var found: (modifiers: String, conversion: Character)?
        var suffix = ""
        while index < characters.count {
            let character = characters[index]
            guard character == marker else {
                if found == nil { prefix.append(character) } else { suffix.append(character) }
                index += 1
                continue
            }
            if index + 1 < characters.count, characters[index + 1] == marker {
                if found == nil { prefix += "%%" } else { suffix += "%%" }
                index += 2
                continue
            }
            guard found == nil else { throw StructuralTemplateServicesError.invalidFormat(format) }
            index += 1
            var modifiers = ""
            while index < characters.count, StructuralTemplateServices.flags.contains(characters[index]) {
                modifiers.append(characters[index])
                index += 1
            }
            let width = Self.digits(in: characters, from: &index)
            modifiers += width
            var precision = ""
            if index < characters.count, characters[index] == "." {
                modifiers.append(".")
                index += 1
                precision = Self.digits(in: characters, from: &index)
                modifiers += precision
            }
            guard width.count <= StructuralTemplateServices.maximumDigits,
                  precision.count <= StructuralTemplateServices.maximumDigits else {
                throw StructuralTemplateServicesError.invalidFormat(format)
            }
            guard index < characters.count,
                  StructuralTemplateServices.integerConversions.contains(characters[index])
                    || StructuralTemplateServices.realConversions.contains(characters[index]) else {
                throw StructuralTemplateServicesError.invalidFormat(format)
            }
            found = (modifiers, characters[index])
            index += 1
        }
        guard let found else { throw StructuralTemplateServicesError.invalidFormat(format) }
        self.prefix = prefix
        self.modifiers = found.modifiers
        self.conversion = found.conversion
        self.suffix = suffix
    }

    /// Read a run of decimal digits.
    ///
    /// - Parameters:
    ///   - characters: The characters of the specification.
    ///   - index: The position to start at, advanced past the digits.
    /// - Returns: The digits read, possibly none.
    private static func digits(in characters: [Character], from index: inout Int) -> String {
        var digits = ""
        while index < characters.count, characters[index].isASCII, characters[index].isNumber {
            digits.append(characters[index])
            index += 1
        }
        return digits
    }

    /// Build the format string to pass to the formatter.
    ///
    /// - Parameter lengthModifier: The length modifier to insert before the conversion.
    /// - Returns: The complete format string.
    func format(lengthModifier: String) -> String {
        prefix + String(StructuralTemplateServices.conversionMarker) + modifiers + lengthModifier
            + String(conversion) + suffix
    }
}
