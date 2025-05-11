//
//  String+Utilities.swift
//  FSMLib
//
//  Created by Rene Hexel on 29/9/16.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
// swiftlint:disable:this type_contents_order

/// Extension providing utility initialisers and computed properties for
/// StringProtocol types, including line splitting, trimming, and extension
/// handling. These utilities are useful for text processing, code generation,
/// and file manipulation tasks.
extension StringProtocol {
    /// Convenience initialiser concatenating an array of lines.
    /// - Parameter lines: Array of lines to concatenate.
    @usableFromInline
    init?<S: StringProtocol>(concatenating lines: [S]) {
        self.init(lines.joined(separator: "\n"))
    }

    /// Lines stored in the string
    ///
    /// An array of lines contained in the string,
    /// split by newline characters.
    /// Setting this property will join the lines
    /// using newline characters.
    @usableFromInline var lines: [Self.SubSequence] {
        get { split(separator: "\n") }
        set { self = .init(newValue.joined(separator: "\n")) ?? "" }
    }

    /// The string with whitespace characters trimmed from both ends.
    @usableFromInline var trimmed: String {
        trimmingCharacters(in: .whitespaces)
    }

    /// String with the file extension removed
    ///
    /// The string with the file extension removed,
    /// if present. If no file extension exists,
    /// this returns the full string.
    @usableFromInline var sansExtension: SubSequence {
        guard let dot = lastIndex(of: ".") else { return self[...] }
        return self[..<dot]
    }

    /// Returns the file extension.
    ///
    /// This returns the file extension (suffix)from the string,
    /// including the dot. If no extension exists,
    /// this returns the full string.
    @usableFromInline var dottedExtension: SubSequence {
        guard let dot = lastIndex(of: ".") else { return self[...] }
        return self[dot...]
    }
}

/// Extension providing utility initialisers and computed properties for
/// String, including line splitting and joining. These utilities are useful
/// for text processing, code generation, and file manipulation tasks.
extension String {
    /// Lines stored in the string.
    ///
    /// An array of lines contained in the string,
    /// split by newline characters.
    /// Setting this property will join the lines
    /// using newline characters.
    @usableFromInline var lines: [Substring] {
        get { split(separator: "\n") }
        set { self = newValue.joined(separator: "\n") }
    }

    /// Convenience initialiser concatenating an array of lines.
    ///
    /// This initialiser concatenates an array of lines
    /// into a single string, separated by newline characters.
    /// - Parameter lines: Array of lines to concatenate.
    @usableFromInline
    init?<S: StringProtocol>(concatenating lines: [S]) {
        self.init(lines.joined(separator: "\n"))
    }
}

/// Return the passed string with leading and trailing whitespace characters trimmed.
///
/// This function returns a new string with all leading and trailing whitespace
/// characters removed from the input string.
///
/// - Note: This function is useful for sanitising user
///         input, processing configuration files, or preparing strings
///         for comparison.
///
/// - Parameter s: The string to trim.
/// - Returns: The trimmed string.
@usableFromInline
func trimmed<S: StringProtocol>(_ s: S) -> String { s.trimmed }

/// Return whether the given string is non-empty.
///
/// This function returns `true` if the input string contains at least one
/// character, and `false` otherwise.
///
/// - Note: This function is useful for validating input,
///         filtering collections, or checking for the presence of data.
///
/// - Parameter s: The string to test.
/// - Returns: `true` if the string is non-empty, `false` otherwise.
@usableFromInline
func nonempty<S: StringProtocol>(_ s: S) -> Bool { !s.isEmpty }
