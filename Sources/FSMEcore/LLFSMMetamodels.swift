//
//  LLFSMMetamodels.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation

/// The kernel and sectioned LLFSM metamodels, loaded together.
///
/// `LLFSMMetamodels` loads the bundled `LLFSM.ecore` document, whose root
/// package `llfsm` holds the `kernel` and `sectioned` subpackages, and keeps
/// typed handles for both levels. Both levels share one root package, so a
/// sectioned model can contain kernel types, variables, expressions and
/// statements, and one registration makes every namespace of the family
/// known to a resource set.
///
/// ```swift
/// let metamodels = try await LLFSMMetamodels()
/// let resourceSet = ResourceSet()
/// await metamodels.register(in: resourceSet)
/// ```
public struct LLFSMMetamodels: Sendable {
    /// The namespace URI of the root package of the LLFSM metamodel family.
    public static let rootNamespaceURI = "http://cpslabgu.github.io/llfsm"

    /// The namespace URI of the kernel subpackage.
    ///
    /// Kernel model documents qualify their elements with this namespace,
    /// conventionally under the prefix `kernel`.
    public static let kernelNamespaceURI = "http://cpslabgu.github.io/llfsm/kernel"

    /// The namespace URI of the sectioned subpackage.
    ///
    /// Sectioned model documents qualify their elements with this namespace,
    /// conventionally under the prefix `sectioned`, and the kernel elements
    /// they contain with ``kernelNamespaceURI``.
    public static let sectionedNamespaceURI = "http://cpslabgu.github.io/llfsm/sectioned"

    /// The name of the bundled metamodel document, without its extension.
    static let documentName = "LLFSM"

    /// The resource directory that holds the bundled metamodel document.
    static let resourceSubdirectory = "Resources"

    /// The name of the resource directory of this target where no bundle is available.
    static let bundleName = ResourceBundleName(package: "FSM", target: "FSMEcore")

    /// The root package `llfsm` of the metamodel family.
    ///
    /// Use it for reflective access across both levels, or to register the
    /// whole family with a resource set.
    public let rootPackage: EPackage

    /// The kernel level of the metamodel family.
    ///
    /// The kernel is the sectionless core into which sectioned models are
    /// encoded and from which verification and code targets are generated.
    public let kernel: KernelMetamodel

    /// The sectioned level of the metamodel family.
    ///
    /// The sectioned level is the traditional view with entry, exit,
    /// internal, suspend and resume sections.
    public let sectioned: SectionedMetamodel

    /// Load both levels from the bundled metamodel document.
    ///
    /// The document is loaded once per program and shared by every caller.
    ///
    /// - Throws: An error if the document cannot be found or parsed, or if it
    ///   lacks a package, classifier or enumeration literal that the levels
    ///   require (see ``LLFSMMetamodelsError``).
    public init() async throws {
        try self.init(rootPackage: try await Self.loadBundledRootPackage())
    }

    /// Wrap an already loaded root package of the metamodel family.
    ///
    /// Use this initialiser when the root package was obtained by other
    /// means, for example from a resource set that loaded the document.
    ///
    /// - Parameter rootPackage: The root package `llfsm` with its `kernel`
    ///   and `sectioned` subpackages.
    /// - Throws: ``LLFSMMetamodelsError`` if a package, classifier or
    ///   enumeration literal that the levels require is missing.
    public init(rootPackage: EPackage) throws {
        self.rootPackage = rootPackage
        kernel = try KernelMetamodel(rootPackage: rootPackage)
        sectioned = try SectionedMetamodel(rootPackage: rootPackage)
    }

    /// Register the metamodel family with a resource set.
    ///
    /// After registration, documents that qualify their elements with the
    /// root, kernel or sectioned namespace are read with the classes of the
    /// corresponding package, and written with one namespace declaration per
    /// package used.
    ///
    /// - Parameter resourceSet: The resource set that should know the metamodels.
    public func register(in resourceSet: ResourceSet) async {
        await Self.register(rootPackage, in: resourceSet)
    }

    /// Load the bundled root package through the shared metamodel cache.
    ///
    /// - Returns: The root package of the bundled document.
    /// - Throws: An error if the document cannot be found or parsed.
    static func loadBundledRootPackage() async throws -> EPackage {
        try await EPackage.bundled(
            named: documentName,
            subdirectory: resourceSubdirectory,
            in: .module,
            bundleName: bundleName
        )
    }

    /// Register a root package and its subpackages under their namespace URIs.
    ///
    /// - Parameters:
    ///   - rootPackage: The root package of the metamodel family.
    ///   - resourceSet: The resource set that should know the metamodels.
    static func register(_ rootPackage: EPackage, in resourceSet: ResourceSet) async {
        await resourceSet.registerMetamodel(rootPackage)
    }

    /// Find a subpackage of the root package and check its namespace URI.
    ///
    /// - Parameters:
    ///   - name: The name of the subpackage.
    ///   - nsURI: The namespace URI the subpackage must declare.
    ///   - rootPackage: The root package of the metamodel family.
    /// - Returns: The subpackage.
    /// - Throws: ``LLFSMMetamodelsError/missingPackage(_:)`` if the root is
    ///   not the expected package or has no matching subpackage.
    static func subpackage(named name: String, nsURI: String, of rootPackage: EPackage) throws -> EPackage {
        guard rootPackage.nsURI == rootNamespaceURI else {
            throw LLFSMMetamodelsError.missingPackage(rootNamespaceURI)
        }
        guard let package = rootPackage.getSubpackage(name), package.nsURI == nsURI else {
            throw LLFSMMetamodelsError.missingPackage(nsURI)
        }
        return package
    }
}

/// Errors raised while the kernel and sectioned metamodels are resolved.
///
/// Each case names the element that the loaded document does not provide,
/// so that a mismatch between a metamodel document and this library can be
/// reported precisely.
public enum LLFSMMetamodelsError: Error, Sendable, Equatable, CustomStringConvertible {
    /// A package with the given namespace URI is missing.
    ///
    /// The root package has a different namespace URI, or it lacks a
    /// subpackage with the expected name and namespace URI.
    case missingPackage(String)

    /// A classifier is missing from a package.
    ///
    /// The associated values are the namespace URI of the package and the
    /// name of the classifier.
    case missingClassifier(package: String, name: String)

    /// An enumeration lacks a literal that this library relies on.
    ///
    /// The associated values are the name of the enumeration and the name of
    /// the literal.
    case missingLiteral(enumeration: String, literal: String)

    /// A sentence that describes the error.
    public var description: String {
        switch self {
        case .missingPackage(let uri):
            return "The LLFSM metamodel lacks the package \(uri)"
        case .missingClassifier(let package, let name):
            return "The package \(package) lacks the classifier \(name)"
        case .missingLiteral(let enumeration, let literal):
            return "The enumeration \(enumeration) lacks the literal \(literal)"
        }
    }
}

/// Typed classifier lookup within one package of the metamodel family.
struct LLFSMClassifierLookup {
    /// The package whose classifiers are looked up.
    let package: EPackage

    /// Find a class by name.
    ///
    /// - Parameter name: The name of the class.
    /// - Returns: The class.
    /// - Throws: ``LLFSMMetamodelsError/missingClassifier(package:name:)`` if absent.
    func eClass(_ name: String) throws -> EClass {
        guard let eClass = package.getEClass(name) else {
            throw LLFSMMetamodelsError.missingClassifier(package: package.nsURI, name: name)
        }
        return eClass
    }

    /// Find an enumeration by name and check that it has every literal of a Swift enumeration.
    ///
    /// - Parameters:
    ///   - name: The name of the enumeration.
    ///   - literals: The Swift enumeration whose raw values name the literals.
    /// - Returns: The enumeration.
    /// - Throws: ``LLFSMMetamodelsError`` if the enumeration or a literal is absent.
    func eEnum<Literal: CaseIterable & RawRepresentable>(
        _ name: String,
        literals: Literal.Type
    ) throws -> EEnum where Literal.RawValue == String {
        guard let eEnum = package.getEEnum(name) else {
            throw LLFSMMetamodelsError.missingClassifier(package: package.nsURI, name: name)
        }
        for literal in Literal.allCases where eEnum.getLiteral(name: literal.rawValue) == nil {
            throw LLFSMMetamodelsError.missingLiteral(enumeration: name, literal: literal.rawValue)
        }
        return eEnum
    }
}
