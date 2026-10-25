//
//  XMLPropertyListWriterTests.swift
//  FSMTests
//
//  Created by Rene Hexel on 25/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing
@testable import FSM

/// Tests that property lists are written as the Foundation XML writer writes them.
@Suite("XML property list writer")
struct XMLPropertyListWriterTests {
    /// A property list with every kind of value that layouts use.
    static var sample: NSDictionary {
        NSDictionary(dictionary: [
            "b": true,
            "a": 1.5,
            "zero": 0.0,
            "int": 42,
            "text": "a<b&c>",
            "empty": NSArray(),
            "none": NSDictionary(),
            "nested": NSDictionary(dictionary: ["x": NSArray(array: [1.0, 2.0])]),
            "list": NSArray(array: ["s", false]),
            "precise": 607.27668023017429,
        ])
    }

    /// The XML document of ``sample``.
    static let sampleDocument = [
        #"<?xml version="1.0" encoding="UTF-8"?>"#,
        #"<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">"#,
        #"<plist version="1.0">"#,
        "<dict>",
        "\t<key>a</key>",
        "\t<real>1.5</real>",
        "\t<key>b</key>",
        "\t<true/>",
        "\t<key>empty</key>",
        "\t<array/>",
        "\t<key>int</key>",
        "\t<integer>42</integer>",
        "\t<key>list</key>",
        "\t<array>",
        "\t\t<string>s</string>",
        "\t\t<false/>",
        "\t</array>",
        "\t<key>nested</key>",
        "\t<dict>",
        "\t\t<key>x</key>",
        "\t\t<array>",
        "\t\t\t<real>1</real>",
        "\t\t\t<real>2</real>",
        "\t\t</array>",
        "\t</dict>",
        "\t<key>none</key>",
        "\t<dict/>",
        "\t<key>precise</key>",
        "\t<real>607.27668023017429</real>",
        "\t<key>text</key>",
        "\t<string>a&lt;b&amp;c&gt;</string>",
        "\t<key>zero</key>",
        "\t<real>0.0</real>",
        "</dict>",
        "</plist>",
        "",
    ].joined(separator: "\n")

    /// A property list with binary data and a date.
    static var dataAndDate: NSDictionary {
        NSDictionary(dictionary: [
            "data": Data(repeating: 0xAB, count: 100),
            "date": Date(timeIntervalSince1970: 86_400 + 3_723),
        ])
    }

    /// Writes a property list and decodes the document as text.
    private func document(of propertyList: Any) throws -> String {
        try #require(String(bytes: try XMLPropertyListWriter.data(from: propertyList), encoding: .utf8))
    }

    /// Checks the layout of a document with every kind of value but data and dates.
    @Test("dictionaries, arrays, numbers, Booleans and strings are written in the Foundation layout")
    func sampleLayout() throws {
        #expect(try document(of: Self.sample) == Self.sampleDocument)
    }

    /// Checks the Base64 lines of binary data and the UTC form of dates.
    @Test("binary data is written in Base64 lines that shrink with the nesting level, and dates in UTC")
    func dataAndDates() throws {
        let base64 = Data(repeating: 0xAB, count: 100).base64EncodedString()
        let width = 68
        let expected = [
            #"<?xml version="1.0" encoding="UTF-8"?>"#,
            #"<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">"#,
            #"<plist version="1.0">"#,
            "<dict>",
            "\t<key>data</key>",
            "\t<data>",
            "\t" + base64.prefix(width),
            "\t" + base64.dropFirst(width).prefix(width),
            "\t</data>",
            "\t<key>date</key>",
            "\t<date>1970-01-02T01:02:03Z</date>",
            "</dict>",
            "</plist>",
            "",
        ].joined(separator: "\n")
        #expect(try document(of: Self.dataAndDate) == expected)
    }

    /// Checks how special floating point values are written.
    @Test("special floating point values are written by name")
    func specialReals() {
        #expect(XMLPropertyListWriter.formatted(Double.nan) == "nan")
        #expect(XMLPropertyListWriter.formatted(Double.infinity) == "+infinity")
        #expect(XMLPropertyListWriter.formatted(-Double.infinity) == "-infinity")
        #expect(XMLPropertyListWriter.formatted(-0.0) == "0.0")
        #expect(XMLPropertyListWriter.formatted(0.1) == "0.10000000000000001")
    }

    /// Checks that values outside the property list types are rejected.
    @Test("values that a property list cannot hold are rejected")
    func invalidValues() {
        #expect(throws: CocoaError.self) { try XMLPropertyListWriter.data(from: NSObject()) }
        #expect(throws: CocoaError.self) {
            try XMLPropertyListWriter.data(from: NSDictionary(dictionary: [1: "number key"]))
        }
    }

    #if !os(WASI)
    // WASI cannot write these property lists with PropertyListSerialization.
    /// The machines whose layouts are compared with the Foundation writer.
    static var machineURLs: [URL] {
        let tests = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let examples = tests.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("examples", isDirectory: true)
        let machines = ((try? FileManager.default.contentsOfDirectory(at: examples, includingPropertiesForKeys: nil)) ?? [])
            .filter { $0.pathExtension == "machine" }
        return (machines + [tests.appendingPathComponent("Resources/TrafficLight.machine", isDirectory: true)])
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Compares the sample documents with those of `PropertyListSerialization`.
    @Test("the documents match those of PropertyListSerialization")
    func matchesFoundation() throws {
        for propertyList in [Self.sample, Self.dataAndDate] {
            let expected = try PropertyListSerialization.data(fromPropertyList: propertyList, format: .xml, options: 0)
            #expect(try XMLPropertyListWriter.data(from: propertyList) == expected)
        }
    }

    /// Compares the layout documents of the example machines with those of `PropertyListSerialization`.
    @Test("machine layouts match those of PropertyListSerialization", arguments: machineURLs)
    func layoutsMatchFoundation(_ url: URL) throws {
        let layouts = try stateNameLayouts(from: url.appendingPathComponent("Layout.plist"))
        try #require(!layouts.isEmpty)
        let propertyList = dictionary(from: layouts)
        let expected = try PropertyListSerialization.data(fromPropertyList: propertyList, format: .xml, options: 0)
        #expect(try XMLPropertyListWriter.data(from: propertyList) == expected)
    }
    #endif
}
