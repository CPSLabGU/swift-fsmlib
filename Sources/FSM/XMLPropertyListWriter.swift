//
//  XMLPropertyListWriter.swift
//
//  Created by Rene Hexel on 25/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// Writes property lists in the XML format of `PropertyListSerialization`.
///
/// The output follows the conventions of the Foundation writer byte for
/// byte: dictionaries list their keys in ascending order, one tab indents
/// each nesting level, floating point numbers carry up to seventeen
/// significant digits with zero written as `0.0`, dates are written in UTC
/// and binary data is written in Base64 lines whose length shrinks with the
/// nesting level.
struct XMLPropertyListWriter {
    /// The lines that open a property list document.
    static let prologue = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">

        """

    /// The line that closes a property list document.
    static let epilogue = "</plist>\n"

    /// The text that indents one nesting level.
    static let indentation = "\t"

    /// The longest Base64 line of binary data at the outermost level.
    static let maximumDataLineLength = 76

    /// The characters by which a Base64 line shrinks for each nesting level.
    static let dataLineShrinkage = 8

    /// The deepest nesting level that still shortens Base64 lines.
    static let deepestShrinkingLevel = 8

    /// The `printf` format of a floating point number.
    static let realFormat = "%.17g"

    /// How zero is written as a floating point number.
    static let zeroReal = "0.0"

    /// The `printf` format of a date in UTC.
    static let dateFormat = "%04d-%02d-%02dT%02d:%02d:%02dZ"

    /// The Objective-C type encodings of numbers that hold Boolean values.
    static let booleanEncodings: Set<String> = ["c", "B"]

    /// The Objective-C type encodings of numbers that hold floating point values.
    static let realEncodings: Set<String> = ["f", "d"]

    /// The Objective-C type encoding of numbers that hold unsigned 64-bit values.
    static let unsignedEncoding = "Q"

    /// The text written so far.
    private(set) var text = ""

    /// Creates the XML document of a property list.
    ///
    /// - Parameter propertyList: A dictionary, array, string, number,
    ///   Boolean, date or data value, whose containers hold only such values.
    /// - Returns: The UTF-8 encoded document.
    /// - Throws: `CocoaError.propertyListWriteInvalid` if the value, or a
    ///   value it contains, cannot be part of a property list.
    static func data(from propertyList: Any) throws -> Data {
        var writer = XMLPropertyListWriter()
        try writer.append(propertyList, indent: "")
        return Data((prologue + writer.text + epilogue).utf8)
    }

    /// Appends one value and its contents.
    ///
    /// - Parameters:
    ///   - value: The value to write.
    ///   - indent: The indentation of the value's lines.
    /// - Throws: `CocoaError.propertyListWriteInvalid` for an unsupported value.
    mutating func append(_ value: Any, indent: String) throws {
        switch value {
        case let boolean as Bool where type(of: value) == Bool.self:
            appendBoolean(boolean, indent: indent)
        case let real as Double where type(of: value) == Double.self:
            appendReal(real, indent: indent)
        case let real as Float where type(of: value) == Float.self:
            appendReal(Double(real), indent: indent)
        case let real as CGFloat where type(of: value) == CGFloat.self:
            appendReal(Double(real), indent: indent)
        case let integer as Int where type(of: value) == Int.self:
            appendLine("<integer>\(integer)</integer>", indent: indent)
        case let number as NSNumber:
            appendNumber(number, indent: indent)
        case let integer as any BinaryInteger:
            appendLine("<integer>\(integer)</integer>", indent: indent)
        case let string as String:
            appendLine("<string>\(Self.escaped(string))</string>", indent: indent)
        case let data as Data:
            appendData(data, indent: indent)
        case let date as Date:
            appendLine("<date>\(Self.formatted(date))</date>", indent: indent)
        case let dictionary as NSDictionary:
            try appendDictionary(dictionary, indent: indent)
        case let array as NSArray:
            try appendArray(Array(array), indent: indent)
        case let array as [Any]:
            try appendArray(array, indent: indent)
        default:
            throw CocoaError(.propertyListWriteInvalid)
        }
    }

    /// Appends one line.
    ///
    /// - Parameters:
    ///   - line: The line without indentation and line break.
    ///   - indent: The indentation of the line.
    mutating func appendLine(_ line: String, indent: String) {
        text += indent + line + "\n"
    }

    /// Appends a Boolean value.
    mutating func appendBoolean(_ boolean: Bool, indent: String) {
        appendLine(boolean ? "<true/>" : "<false/>", indent: indent)
    }

    /// Appends a floating point value.
    mutating func appendReal(_ real: Double, indent: String) {
        appendLine("<real>\(Self.formatted(real))</real>", indent: indent)
    }

    /// Appends a Foundation number according to the type it holds.
    mutating func appendNumber(_ number: NSNumber, indent: String) {
        let encoding = String(cString: number.objCType)
        if Self.booleanEncodings.contains(encoding) {
            appendBoolean(number.boolValue, indent: indent)
        } else if Self.realEncodings.contains(encoding) {
            appendReal(number.doubleValue, indent: indent)
        } else if encoding == Self.unsignedEncoding {
            appendLine("<integer>\(number.uint64Value)</integer>", indent: indent)
        } else {
            appendLine("<integer>\(number.int64Value)</integer>", indent: indent)
        }
    }

    /// Appends binary data as Base64 lines.
    mutating func appendData(_ data: Data, indent: String) {
        appendLine("<data>", indent: indent)
        let level = min(indent.count, Self.deepestShrinkingLevel)
        let width = Self.maximumDataLineLength - Self.dataLineShrinkage * level
        var remainder = Substring(data.base64EncodedString())
        while !remainder.isEmpty {
            appendLine(String(remainder.prefix(width)), indent: indent)
            remainder = remainder.dropFirst(width)
        }
        appendLine("</data>", indent: indent)
    }

    /// Appends a dictionary with its keys in ascending order.
    ///
    /// - Throws: `CocoaError.propertyListWriteInvalid` for a key that is not
    ///   a string, or an unsupported value.
    mutating func appendDictionary(_ dictionary: NSDictionary, indent: String) throws {
        var entries: [(key: String, value: Any)] = []
        for (key, value) in dictionary {
            guard let key = key as? String else { throw CocoaError(.propertyListWriteInvalid) }
            entries.append((key, value))
        }
        guard !entries.isEmpty else {
            appendLine("<dict/>", indent: indent)
            return
        }
        entries.sort { $0.key.utf16.lexicographicallyPrecedes($1.key.utf16) }
        appendLine("<dict>", indent: indent)
        let inner = indent + Self.indentation
        for entry in entries {
            appendLine("<key>\(Self.escaped(entry.key))</key>", indent: inner)
            try append(entry.value, indent: inner)
        }
        appendLine("</dict>", indent: indent)
    }

    /// Appends an array.
    ///
    /// - Throws: `CocoaError.propertyListWriteInvalid` for an unsupported element.
    mutating func appendArray(_ array: [Any], indent: String) throws {
        guard !array.isEmpty else {
            appendLine("<array/>", indent: indent)
            return
        }
        appendLine("<array>", indent: indent)
        let inner = indent + Self.indentation
        for element in array {
            try append(element, indent: inner)
        }
        appendLine("</array>", indent: indent)
    }

    /// Text with the characters that XML reserves replaced by entities.
    ///
    /// - Parameter text: The text to escape.
    /// - Returns: The text with `&`, `<` and `>` replaced.
    static func escaped(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    /// A floating point number as a property list writes it.
    ///
    /// - Parameter real: The number.
    /// - Returns: `0.0` for zero, `nan`, `+infinity` or `-infinity` for
    ///   the special values, and up to seventeen significant digits otherwise.
    static func formatted(_ real: Double) -> String {
        if real.isNaN { return "nan" }
        if real.isInfinite { return real < 0 ? "-infinity" : "+infinity" }
        if real == 0 { return zeroReal }
        return String(format: realFormat, real)
    }

    /// A date as a property list writes it.
    ///
    /// - Parameter date: The date.
    /// - Returns: The date and time of day in UTC, to the second.
    static func formatted(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let fields = [parts.year, parts.month, parts.day, parts.hour, parts.minute, parts.second]
        return String(format: dateFormat, arguments: fields.map { ($0 ?? 0) as CVarArg })
    }
}
