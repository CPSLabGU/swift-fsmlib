//
//  TemplateParitySupport.swift
//  FSMEcoreTests
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation
import Testing
@testable import FSM
@testable import FSMEcore

/// An example machine or arrangement bundle that the parity tests render.
struct ParityExample: CustomTestStringConvertible, Sendable {
    /// The location of the example bundle.
    let url: URL

    /// The name of the bundle without its extension.
    var name: String { url.deletingPathExtension().lastPathComponent }

    /// The bundle name shown in test results.
    var testDescription: String { url.lastPathComponent }
}

/// One parity comparison: an example written in one format with one suspensibility.
struct ParityCase: CustomTestStringConvertible, Sendable {
    /// The example to render.
    let example: ParityExample

    /// The raw value of the output format.
    let formatName: String

    /// Whether to render the suspensible variant.
    let isSuspensible: Bool

    /// Create a parity case.
    ///
    /// - Parameters:
    ///   - example: The example to render.
    ///   - format: The output format.
    ///   - isSuspensible: Whether to render the suspensible variant.
    init(example: ParityExample, format: Format, isSuspensible: Bool) {
        self.example = example
        self.formatName = format.rawValue
        self.isSuspensible = isSuspensible
    }

    /// The output format.
    var format: Format { Format(rawValue: formatName) ?? .c }

    /// The case shown in test results.
    var testDescription: String {
        "\(example.testDescription) as \(format.rawValue), \(isSuspensible ? "suspensible" : "not suspensible")"
    }
}

/// Helpers that render examples through the Swift bindings and the templates and compare the results.
enum TemplateParity {
    /// The bundle extension of arrangements.
    static let arrangementExtension = "arrangement"

    /// The bundle extension of machines.
    static let machineExtension = "machine"

    /// The number of times the Swift rendition of an arrangement is repeated to find the order the templates use.
    ///
    /// The Swift arrangement code lists machine types in the iteration order of a set or dictionary,
    /// which is unspecified; the templates list them in the order of their first instance.
    static let arrangementRenditions = 8

    /// The directory holding the example bundles of the package.
    static var examplesDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("examples", isDirectory: true)
    }

    /// The example bundles with the given extension, ordered by name.
    ///
    /// - Parameter pathExtension: The bundle extension.
    /// - Returns: The examples.
    static func examples(withExtension pathExtension: String) -> [ParityExample] {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: examplesDirectory, includingPropertiesForKeys: nil)) ?? []
        return urls.filter { $0.pathExtension == pathExtension }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map(ParityExample.init(url:))
    }

    /// The example machines, including the test resource machine.
    static var machineExamples: [ParityExample] {
        var examples = examples(withExtension: machineExtension)
        if let trafficLight = Bundle.module.url(
            forResource: "TrafficLight", withExtension: machineExtension, subdirectory: "Resources") {
            examples.append(ParityExample(url: trafficLight))
        }
        return examples
    }

    /// The example arrangements.
    static var arrangementExamples: [ParityExample] {
        examples(withExtension: arrangementExtension)
    }

    /// The parity cases of a list of examples in one format, for both suspensibility settings.
    ///
    /// - Parameters:
    ///   - examples: The examples.
    ///   - format: The output format.
    /// - Returns: The cases.
    static func cases(of examples: [ParityExample], in format: Format) -> [ParityCase] {
        examples.flatMap { example in
            [true, false].map { ParityCase(example: example, format: format, isSuspensible: $0) }
        }
    }

    /// Create a fresh directory for one rendition.
    ///
    /// - Parameter label: A label for the directory name.
    /// - Returns: The new directory.
    static func makeDirectory(_ label: String) throws -> URL {
        try FSMEcoreTestSupport.makeTemporaryDirectory(prefix: "parity-\(label)")
    }

    /// The location of the bundle or file that a case writes below a directory.
    ///
    /// - Parameters:
    ///   - parityCase: The case.
    ///   - directory: The directory to write into.
    ///   - pathExtension: The extension of the written bundle or file.
    /// - Returns: The location.
    static func destination(of parityCase: ParityCase, in directory: URL, pathExtension: String) -> URL {
        directory.appendingPathComponent(parityCase.example.name).appendingPathExtension(pathExtension)
    }

    /// Write a machine with the Swift binding of a format.
    ///
    /// - Parameters:
    ///   - machine: The machine to write.
    ///   - parityCase: The case that selects the format and suspensibility.
    ///   - directory: The directory to write into.
    /// - Returns: The location of the written bundle or file.
    static func writeSwiftMachine(_ machine: Machine, for parityCase: ParityCase, in directory: URL) throws -> URL {
        let url = destination(of: parityCase, in: directory, pathExtension: parityCase.format.fileExtension)
        if parityCase.format.isSingleFile {
            try MachineStorageFactory.create(for: machine, format: parityCase.format, at: url).write(to: url)
        } else {
            let language = try #require(outputLanguage(for: parityCase.format))
            try machine.write(to: url, language: language, isSuspensible: parityCase.isSuspensible)
        }
        return url
    }

    /// Write a machine through the templates.
    ///
    /// - Parameters:
    ///   - machine: The machine to write.
    ///   - parityCase: The case that selects the format and suspensibility.
    ///   - directory: The directory to write into.
    /// - Returns: The location of the written bundle or file.
    @MainActor
    static func writeTemplateMachine(
        _ machine: Machine, for parityCase: ParityCase, in directory: URL
    ) async throws -> URL {
        let url = destination(of: parityCase, in: directory, pathExtension: parityCase.format.fileExtension)
        let binding = try await TemplateBinding.make(
            for: machine, named: parityCase.example.name, format: parityCase.format,
            isSuspensible: parityCase.isSuspensible)
        try machine.write(to: url, language: binding, isSuspensible: parityCase.isSuspensible)
        return url
    }

    /// Write an arrangement with a language.
    ///
    /// - Parameters:
    ///   - arrangement: The arrangement to write.
    ///   - language: The output language.
    ///   - parityCase: The case that selects the suspensibility.
    ///   - directory: The directory to write into.
    /// - Returns: The location of the written bundle.
    static func writeArrangement(
        _ arrangement: Arrangement, language: any OutputLanguage, for parityCase: ParityCase, in directory: URL
    ) throws -> URL {
        let url = destination(of: parityCase, in: directory, pathExtension: arrangementExtension)
        let wrapper = ArrangementWrapper(
            directoryWithFileWrappers: [:], for: arrangement, named: url.lastPathComponent, language: language)
        wrapper.isSuspensible = parityCase.isSuspensible
        try wrapper.write(to: url)
        return url
    }

    /// Read every file below a bundle, or a single file.
    ///
    /// - Parameter url: The bundle directory or file.
    /// - Returns: The file contents keyed by path relative to the bundle (the file name for a single file).
    static func files(at url: URL) throws -> [String: Data] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return [:] }
        guard isDirectory.boolValue else { return [url.lastPathComponent: try Data(contentsOf: url)] }
        return try StructuralTemplateEngine.files(below: url)
    }

    /// Compare two renditions and record an issue with a unified diff of the first differing file.
    ///
    /// - Parameters:
    ///   - template: The files written through the templates.
    ///   - swift: The files written by the Swift binding.
    ///   - parityCase: The compared case, for the issue description.
    ///   - alternatives: Further Swift renditions; a file matches if any rendition matches.
    ///   - allowsReorderedLines: Whether a file that no rendition matches is accepted if it holds
    ///     the same lines in another order, which is how renditions with an unspecified order of
    ///     machine types differ. Accepted files are reported in the test output.
    ///   - sourceLocation: The location to report issues at.
    static func expectIdentical(
        _ template: [String: Data],
        _ swift: [String: Data],
        case parityCase: ParityCase,
        alternatives: () throws -> [String: Data]? = { nil },
        allowsReorderedLines: Bool = false,
        sourceLocation: SourceLocation = #_sourceLocation
    ) rethrows {
        #expect(
            template.keys.sorted() == swift.keys.sorted(),
            "File sets differ for \(parityCase.testDescription): only templates \(Set(template.keys).subtracting(swift.keys).sorted()), only Swift \(Set(swift.keys).subtracting(template.keys).sorted())",
            sourceLocation: sourceLocation)
        var differing = Set(template.keys.filter { swift[$0] != nil && template[$0] != swift[$0] })
        while !differing.isEmpty, let alternative = try alternatives() {
            differing = differing.filter { alternative[$0] != template[$0] }
        }
        if allowsReorderedLines {
            let reordered = differing.filter { path in
                sortedLines(template[path]) == sortedLines(swift[path])
            }
            if !reordered.isEmpty {
                print("Parity of \(parityCase.testDescription): same lines in another order in \(reordered.sorted())")
            }
            differing.subtract(reordered)
        }
        guard let first = differing.sorted().first else { return }
        let diff = unifiedDiff(
            String(decoding: swift[first] ?? Data(), as: UTF8.self),
            String(decoding: template[first] ?? Data(), as: UTF8.self),
            from: "swift/\(first)", to: "template/\(first)")
        Issue.record(
            "\(differing.count) file(s) differ for \(parityCase.testDescription): \(differing.sorted()); first:\n\(diff)",
            sourceLocation: sourceLocation)
    }

    /// The lines of a file in ascending order.
    ///
    /// - Parameter data: The file content.
    /// - Returns: The sorted lines, empty if there is no content.
    static func sortedLines(_ data: Data?) -> [Substring] {
        guard let data else { return [] }
        return String(decoding: data, as: UTF8.self)
            .split(separator: "\n", omittingEmptySubsequences: false).sorted()
    }

    /// A unified diff of two texts, with three lines of context.
    ///
    /// - Parameters:
    ///   - old: The expected text.
    ///   - new: The actual text.
    ///   - oldName: The name of the expected text.
    ///   - newName: The name of the actual text.
    /// - Returns: The diff, or an empty string if the texts are equal.
    static func unifiedDiff(_ old: String, _ new: String, from oldName: String, to newName: String) -> String {
        let a = old.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let b = new.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard a != b else { return old == new ? "" : "(texts differ only in line endings or encoding)" }
        var lengths = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in stride(from: a.count - 1, through: 0, by: -1) {
            for j in stride(from: b.count - 1, through: 0, by: -1) {
                lengths[i][j] = a[i] == b[j] ? lengths[i + 1][j + 1] + 1 : max(lengths[i + 1][j], lengths[i][j + 1])
            }
        }
        enum Line { case same(String), removed(String), added(String) }
        var lines: [(line: Line, oldIndex: Int, newIndex: Int)] = []
        var i = 0, j = 0
        while i < a.count || j < b.count {
            if i < a.count, j < b.count, a[i] == b[j] {
                lines.append((.same(a[i]), i, j)); i += 1; j += 1
            } else if j < b.count, i == a.count || lengths[i][j + 1] >= lengths[i + 1][j] {
                lines.append((.added(b[j]), i, j)); j += 1
            } else {
                lines.append((.removed(a[i]), i, j)); i += 1
            }
        }
        let context = 3
        var output = "--- \(oldName)\n+++ \(newName)\n"
        var index = 0
        while index < lines.count {
            guard case .same = lines[index].line else {
                let start = max(0, index - context)
                var end = index
                var lastChange = index
                while end < lines.count {
                    if case .same = lines[end].line {
                        if end - lastChange > context * 2 { break }
                    } else {
                        lastChange = end
                    }
                    end += 1
                }
                end = min(lines.count, lastChange + context + 1)
                let hunk = lines[start..<end]
                let oldCount = hunk.filter { if case .added = $0.line { return false }; return true }.count
                let newCount = hunk.filter { if case .removed = $0.line { return false }; return true }.count
                output += "@@ -\(hunk.first!.oldIndex + 1),\(oldCount) +\(hunk.first!.newIndex + 1),\(newCount) @@\n"
                for entry in hunk {
                    switch entry.line {
                    case .same(let text): output += " \(text)\n"
                    case .removed(let text): output += "-\(text)\n"
                    case .added(let text): output += "+\(text)\n"
                    }
                }
                index = end
                continue
            }
            index += 1
        }
        return output
    }
}
