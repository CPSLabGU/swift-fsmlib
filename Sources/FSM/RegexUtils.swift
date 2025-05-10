//
//  RegexUtils.swift
//
//  Created by Rene Hexel on 19/10/2016.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Return an substring contained in a matching, bracketed
/// regular expression pattern.
///
/// - Parameters:
///   - content: The string to examine.
///   - expr: The regular expression pattern to match.
/// - Returns: The substring contained in the first bracketed expression.
@usableFromInline
func string(containedIn content: String, matching expr: Regex<(Substring, Substring)>) -> Substring? {
    try? expr.firstMatch(in: content)?.1
}
