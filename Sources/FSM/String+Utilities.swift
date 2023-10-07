//
//  String+Utilities.swift
//  FSMLib
//
//  Created by Rene Hexel on 29/9/16.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
extension StringProtocol {
    /// Convenience initialiser concatenating an array of lines.
    /// - Parameter lines: Array of lines to concatenate.
    @usableFromInline
    init?<S: StringProtocol>(concatenating lines: [S]) {
        self.init(lines.joined(separator: "\n"))
    }

    /// Lines stored in the string
    @usableFromInline var lines: [Self.SubSequence] {
        get { split(separator: "\n") }
        set { self = .init(newValue.joined(separator: "\n")) ?? "" }
    }

    /// The string with whitespace characters trimmed
    @usableFromInline var trimmed: String {
        trimmingCharacters(in: .whitespaces)
    }

    /// The string with the file extension removed
    @usableFromInline var sansExtension: SubSequence {
        guard let dot = lastIndex(of: ".") else { return self[...] }
        return self[..<dot]
    }
}

extension String {
    /// Lines stored in the string
    @usableFromInline var lines: [Substring] {
        get { split(separator: "\n") }
        set { self = newValue.joined(separator: "\n") }
    }

    /// Convenience initialiser concatenating an array of lines.
    /// - Parameter lines: Array of lines to concatenate.
    @usableFromInline
    init?<S: StringProtocol>(concatenating lines: [S]) {
        self.init(lines.joined(separator: "\n"))
    }
}

/// Return the passed string with leading and trailing
/// whitespace characters trimmed.
///
/// - Parameter s: The string to trim.
/// - Returns: The trimmed string.
@usableFromInline
func trimmed<S: StringProtocol>(_ s: S) -> String { s.trimmed }

/// Return whether the given string is non-empty.
///
/// - Parameter s: The string to test.
/// - Returns: `true` if the string is non-empty, `false` otherwise.
@usableFromInline
func nonempty<S: StringProtocol>(_ s: S) -> Bool { !s.isEmpty }
