//
//  SCXMLBinding.swift
//
//  Created by Rene Hexel on 18/10/2025.
//  Copyright © 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// SCXML language binding for reading and writing SCXML documents.
///
/// This binding provides I/O operations for SCXML format while maintaining
/// compatibility with the existing FSM architecture. Use this binding when
/// working with SCXML files (.scxml extension).
public struct SCXMLBinding: Equatable {
    /// Canonical name of the binding
    public let name: String = "scxml"

    /// Default initializer
    public init() {}

    /// Read SCXML file and convert to Machine
    ///
    /// - Parameter url: URL to SCXML file
    /// - Returns: Parsed Machine object
    /// - Throws: SCXMLParserError if parsing fails
    public func read(from url: URL) throws -> Machine {
        let parser = SCXMLParser()
        return try parser.parse(contentsOf: url)
    }

    /// Read SCXML from data and convert to Machine
    ///
    /// - Parameter data: SCXML XML data
    /// - Returns: Parsed Machine object
    /// - Throws: SCXMLParserError if parsing fails
    public func read(from data: Data) throws -> Machine {
        let parser = SCXMLParser()
        return try parser.parse(data)
    }

    /// Write Machine to SCXML file
    ///
    /// - Parameters:
    ///   - machine: Machine to write
    ///   - url: URL to write SCXML file to
    /// - Throws: Error if writing fails
    public func write(_ machine: Machine, to url: URL) throws {
        let writer = SCXMLWriter()
        let xml = try writer.generate(from: machine)
        try xml.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Generate SCXML string from Machine
    ///
    /// - Parameter machine: Machine to convert
    /// - Returns: SCXML XML string
    /// - Throws: Error if generation fails
    public func generateXML(from machine: Machine) throws -> String {
        let writer = SCXMLWriter()
        return try writer.generate(from: machine)
    }
}

/// Equality comparison for SCXMLBinding
public func == (lhs: SCXMLBinding, rhs: SCXMLBinding) -> Bool {
    lhs.name == rhs.name
}
