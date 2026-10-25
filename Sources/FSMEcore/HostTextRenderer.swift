//
//  HostTextRenderer.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ATL
import ECore
import EMFBase
import Foundation
import MTL

/// Renders typed kernel nodes of a model as host-language text.
///
/// The renderer runs the host queries of the bundled expression modules:
/// each module that declares a `hostLanguages()` query renders the text of
/// the languages it names. A language without such a module can only
/// render opaque nodes, whose text is kept as written. The renderer also
/// puts the declaration texts of variables back at their lines of the
/// host declarations that held them (see
/// ``VariableDeclarationScanner/merged(remainder:placements:)``).
@MainActor
struct HostTextRenderer {
    /// The names of the queries that the renderer runs.
    enum Query {
        /// The languages whose host text a module renders.
        static let languages = "hostLanguages"
        /// The host text of an expression.
        static let expression = "hostExpression"
        /// The host text of a section of statements.
        static let statements = "hostStatements"
        /// The host text of variable declarations.
        static let declarations = "hostDeclarations"
        /// The text of an opaque expression, for languages without a module.
        static let verbatimExpression = "verbatimExpression"
        /// The text of a section of opaque statements, for languages without a module.
        static let verbatimStatements = "verbatimStatements"
        /// The declarations of no variables, for languages without a module.
        static let verbatimDeclarations = "verbatimDeclarations"
    }

    /// The directory below the templates directory that holds the expression modules.
    static let expressionsDirectory = "expressions"

    /// The module that holds the language-neutral queries.
    static let neutralModule = "kernel"

    /// The query helpers of the module that renders each language.
    private let renderers: [String: [MTLQueryHelper]]

    /// The query helpers of the language-neutral module.
    private let neutral: [MTLQueryHelper]

    /// The resource whose objects the renderer resolves.
    private let resource: Resource

    /// Load the expression modules for a model.
    ///
    /// - Parameter resource: The resource that holds the nodes to render.
    /// - Throws: ``LLFSMTransformationError/missingTransformation(_:)`` if the
    ///   expression modules are not bundled, and the errors of the template parser.
    init(resource: Resource) async throws {
        guard let templates = KernelTemplateGenerator.templatesDirectory else {
            throw LLFSMTransformationError.missingTransformation(Self.expressionsDirectory)
        }
        let directory = templates.appendingPathComponent(Self.expressionsDirectory, isDirectory: true)
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == MTLSyntax.moduleFileExtension }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        var renderers: [String: [MTLQueryHelper]] = [:]
        var neutral: [MTLQueryHelper] = []
        for file in files {
            let module = try await MTLParser(searchPaths: [templates]).parse(file)
            let isNeutral = module.name == Self.neutralModule
            guard isNeutral || module.queries[Query.languages] != nil else { continue }
            let generator = MTLGenerator(module: module, generationStrategy: MTLInMemoryStrategy())
            await generator.registerModel(LLFSMTransformationNames.Alias.source, resource: resource)
            let helpers = MTLQueryHelpers.helpers(for: module, generator: generator)
            if isNeutral {
                neutral = helpers
                continue
            }
            let languages = try await MTLQueryHelpers.call(Query.languages, arguments: [], among: helpers)
            for case let language as String in Self.elements(of: languages) where renderers[language] == nil {
                renderers[language] = helpers
            }
        }
        self.renderers = renderers
        self.neutral = neutral
        self.resource = resource
    }

    /// The languages whose typed nodes the renderer can render.
    var languages: Set<String> { Set(renderers.keys) }

    /// The helpers that transformations call to render host text.
    ///
    /// Each rendering helper takes the node or nodes to render followed by
    /// the language; the merging helper takes the declarations text and the
    /// variables whose declaration texts it puts back.
    var nativeHelpers: [ATLNativeHelper] {
        let renderer = self
        func helper(_ name: String, _ query: String, _ verbatim: String, many: Bool) -> ATLNativeHelper {
            ATLNativeHelper(name: name, parameterTypes: ["OclAny", "String"], returnType: "String") { _, arguments in
                try await renderer.render(
                    arguments.first.flatMap { $0 },
                    language: arguments.last as? String ?? "",
                    query: query,
                    verbatim: verbatim,
                    many: many
                )
            }
        }
        return [
            helper(
                LLFSMTransformationNames.NativeHelper.renderExpression,
                Query.expression,
                Query.verbatimExpression,
                many: false
            ),
            helper(
                LLFSMTransformationNames.NativeHelper.renderStatements,
                Query.statements,
                Query.verbatimStatements,
                many: true
            ),
            helper(
                LLFSMTransformationNames.NativeHelper.renderDeclarations,
                Query.declarations,
                Query.verbatimDeclarations,
                many: true
            ),
            ATLNativeHelper(
                name: LLFSMTransformationNames.NativeHelper.mergeDeclarations,
                parameterTypes: ["String", "OclAny"],
                returnType: "String"
            ) { _, arguments in
                await renderer.merge(
                    arguments.first.flatMap { $0 as? String },
                    variables: arguments.count > 1 ? arguments[1] : nil
                )
            },
        ]
    }

    /// Put the declaration texts of variables back at their lines of a declarations text.
    ///
    /// A variable without a declaration line is placed after the text.
    ///
    /// - Parameters:
    ///   - text: The declarations that remained after the variables were recognised, or `nil` for none.
    ///   - variables: The variable or sequence of variables whose declaration texts to put back.
    /// - Returns: The declarations with the declaration texts at their lines.
    func merge(_ text: String?, variables: (any EcoreValue)?) async -> String {
        var placements: [VariableDeclarationScanner.Placement] = []
        for element in Self.elements(of: variables) {
            guard let variable = await resolved(element) as? DynamicEObject,
                  let declaration = variable.string(.declarationText) else { continue }
            let line = variable.isSet(.declarationLine) ? variable.int(.declarationLine) ?? Int.max : Int.max
            placements.append(VariableDeclarationScanner.Placement(
                line: line, text: declaration, documentation: variable.string(.documentation)))
        }
        return VariableDeclarationScanner.merged(remainder: text, placements: placements)
    }

    /// Render a node or a sequence of nodes in a language.
    ///
    /// - Parameters:
    ///   - value: The node, or the sequence of nodes.
    ///   - language: The language of the machine that holds the nodes.
    ///   - query: The host query of a language module.
    ///   - verbatim: The neutral query for languages without a module.
    ///   - many: Whether the value is a sequence of nodes.
    /// - Returns: The host text.
    /// - Throws: ``HostTextRendererError`` if the language has no module and a node is typed.
    func render(
        _ value: (any EcoreValue)?,
        language: String,
        query: String,
        verbatim: String,
        many: Bool
    ) async throws -> String {
        let argument: any EcoreValue
        if many {
            var objects: [any EcoreValue] = []
            for element in Self.elements(of: value) { objects.append(await resolved(element)) }
            argument = EcoreValueArray(objects)
        } else if let value {
            argument = await resolved(value)
        } else {
            return ""
        }
        if let helpers = renderers[language] {
            return try await MTLQueryHelpers.call(query, arguments: [argument], among: helpers) as? String ?? ""
        }
        guard let text = try await MTLQueryHelpers.call(verbatim, arguments: [argument], among: neutral) as? String
        else {
            throw HostTextRendererError.unsupportedLanguage(language)
        }
        return text
    }

    /// The model object that a value denotes, resolving identifiers.
    private func resolved(_ value: any EcoreValue) async -> any EcoreValue {
        guard let identifier = value as? EUUID, let object = await resource.resolve(identifier) else { return value }
        return object
    }

    /// The elements of a collection value, or the value itself.
    private static func elements(of value: (any EcoreValue)?) -> [any EcoreValue] {
        switch value {
        case nil:
            return []
        case let array as EcoreValueArray:
            return array.values
        case let collection as ATLCollectionValue:
            return collection.values
        case let values as [any EcoreValue]:
            return values
        case let value?:
            return [value]
        }
    }
}

/// The problems that stop the rendering of host-language text.
public enum HostTextRendererError: Error, Sendable, Equatable, CustomStringConvertible {
    /// A typed node belongs to a machine whose language no bundled module renders.
    ///
    /// The associated value is the language.
    case unsupportedLanguage(String)

    /// A sentence that describes the problem.
    public var description: String {
        switch self {
        case .unsupportedLanguage(let language):
            return "Typed nodes cannot be written as host text in the language '\(language)'"
        }
    }
}
