//
//  KernelMetamodelLoadingTests.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
import Testing
@testable import FSMEcore

/// Tests that the kernel and sectioned levels load from the bundled document.
@Suite("Kernel and sectioned metamodel loading")
struct KernelMetamodelLoadingTests {
    /// Verify that the kernel level resolves its classes, references and enumerations.
    @Test("the kernel level resolves its subpackage, classes and enumerations")
    func kernelLoads() async throws {
        let kernel = try await KernelMetamodel()
        #expect(kernel.rootPackage.nsURI == LLFSMMetamodels.rootNamespaceURI)
        #expect(kernel.package.nsURI == LLFSMMetamodels.kernelNamespaceURI)
        #expect(kernel.package.nsPrefix == "kernel")
        #expect(kernel.typeClass.isAbstract)
        #expect(kernel.expressionClass.isAbstract)
        #expect(kernel.statementClass.isAbstract)
        #expect(kernel.isKind(kernel.integerTypeClass, of: kernel.typeClass))
        #expect(kernel.isKind(kernel.callExpressionClass, of: kernel.expressionClass))
        #expect(kernel.isKind(kernel.assignmentClass, of: kernel.statementClass))
        #expect(!kernel.isKind(kernel.assignmentClass, of: kernel.expressionClass))
        let initial = try #require(kernel.machineClass.getEReference(name: "initial"))
        #expect((initial.eType as? EClass)?.id == kernel.stateClass.id)
        #expect(initial.containment == false)
        let types = try #require(kernel.arrangementClass.getEReference(name: "types"))
        #expect((types.eType as? EClass)?.id == kernel.typeClass.id)
        let operation = try #require(kernel.binaryExpressionClass.getEAttribute(name: "operation"))
        #expect((operation.eType as? EEnum)?.id == kernel.binaryOperationEnum.id)
        #expect(kernel.unaryOperationEnum.literals.map(\.name) == KernelUnaryOperation.allCases.map(\.rawValue))
        #expect(kernel.binaryOperationEnum.literals.map(\.name) == KernelBinaryOperation.allCases.map(\.rawValue))
        #expect(kernel.originRoleEnum.literals.map(\.name) == OriginRole.allCases.map(\.rawValue))
    }

    /// Verify that states and transitions have an optional origin containment.
    @Test("states and transitions have an optional origin containment")
    func originContainment() async throws {
        let kernel = try await KernelMetamodel()
        for owner in [kernel.stateClass, kernel.transitionClass] {
            let origin = try #require(owner.getEReference(name: "origin"))
            #expect(origin.containment)
            #expect(origin.lowerBound == 0)
            #expect(origin.upperBound == 1)
            #expect((origin.eType as? EClass)?.id == kernel.originClass.id)
        }
        let role = try #require(kernel.originClass.getEAttribute(name: OriginAnnotations.roleKey))
        #expect((role.eType as? EEnum)?.id == kernel.originRoleEnum.id)
        #expect(kernel.originClass.getEAttribute(name: OriginAnnotations.stateKey) != nil)
        #expect(kernel.originClass.getEAttribute(name: OriginAnnotations.transitionKey) != nil)
        let annotation = try #require(kernel.originClass.getEAnnotation(source: OriginAnnotations.source))
        #expect(Set(annotation.details.keys) == [
            OriginAnnotations.stateKey, OriginAnnotations.roleKey, OriginAnnotations.transitionKey,
        ])
        for (key, attribute) in annotation.details {
            #expect(kernel.originClass.getEAttribute(name: attribute) != nil, "detail \(key)")
        }
    }

    /// Verify that the sectioned level reuses the expressions and statements of the kernel.
    @Test("the sectioned level reuses the kernel's expressions and statements")
    func sectionedLoads() async throws {
        let sectioned = try await SectionedMetamodel()
        let kernel = sectioned.kernel
        #expect(sectioned.package.nsURI == LLFSMMetamodels.sectionedNamespaceURI)
        #expect(sectioned.package.nsPrefix == "sectioned")
        #expect(kernel.isKind(sectioned.stateTimeExpressionClass, of: kernel.expressionClass))
        #expect(kernel.isKind(sectioned.inStateExpressionClass, of: kernel.expressionClass))
        #expect(kernel.isKind(sectioned.machineControlStatementClass, of: kernel.statementClass))
        let onEntry = try #require(sectioned.stateClass.getEReference(name: "onEntry"))
        #expect((onEntry.eType as? EClass)?.id == kernel.statementClass.id)
        let bindings = try #require(sectioned.instanceClass.getEReference(name: "bindings"))
        #expect((bindings.eType as? EClass)?.id == kernel.bindingClass.id)
        #expect(sectioned.timeUnitEnum.literals.map(\.name) == SectionedTimeUnit.allCases.map(\.rawValue))
        #expect(sectioned.controlOperationEnum.literals.map(\.name)
                == SectionedControlOperation.allCases.map(\.rawValue))
    }

    /// Verify that both levels share one root package.
    @Test("both levels share one root package loaded once")
    func levelsShareRootPackage() async throws {
        let metamodels = try await LLFSMMetamodels()
        let kernel = try await KernelMetamodel()
        #expect(metamodels.rootPackage.id == kernel.rootPackage.id)
        #expect(metamodels.kernel.stateClass.id == kernel.stateClass.id)
        #expect(metamodels.sectioned.kernel.stateClass.id == kernel.stateClass.id)
        #expect(metamodels.sectioned.stateClass.id != kernel.stateClass.id)
    }

    /// Verify that registration makes every package available by namespace URI.
    @Test("registration makes the root and both subpackages available by namespace URI")
    func registration() async throws {
        let metamodels = try await LLFSMMetamodels()
        for register in [
            { (set: ResourceSet) in await metamodels.register(in: set) },
            { (set: ResourceSet) in await metamodels.kernel.register(in: set) },
            { (set: ResourceSet) in await metamodels.sectioned.register(in: set) },
        ] {
            let resourceSet = ResourceSet()
            await register(resourceSet)
            #expect(await resourceSet.getMetamodel(uri: LLFSMMetamodels.rootNamespaceURI)?.name == "llfsm")
            #expect(await resourceSet.getMetamodel(uri: LLFSMMetamodels.kernelNamespaceURI)?.name == "kernel")
            #expect(await resourceSet.getMetamodel(uri: LLFSMMetamodels.sectionedNamespaceURI)?.name == "sectioned")
        }
    }

    /// Verify that a root package lacking the expected subpackages or classifiers is rejected.
    @Test("a root package without the expected subpackages is rejected")
    func missingSubpackage() throws {
        let wrongRoot = EPackage(name: "other", nsURI: "http://example.org/other", nsPrefix: "other")
        #expect(throws: LLFSMMetamodelsError.missingPackage(LLFSMMetamodels.rootNamespaceURI)) {
            try KernelMetamodel(rootPackage: wrongRoot)
        }
        let bareRoot = EPackage(name: "llfsm", nsURI: LLFSMMetamodels.rootNamespaceURI, nsPrefix: "llfsm")
        #expect(throws: LLFSMMetamodelsError.missingPackage(LLFSMMetamodels.kernelNamespaceURI)) {
            try KernelMetamodel(rootPackage: bareRoot)
        }
        let kernelOnly = EPackage(
            name: "llfsm",
            nsURI: LLFSMMetamodels.rootNamespaceURI,
            nsPrefix: "llfsm",
            eSubpackages: [EPackage(name: "kernel", nsURI: LLFSMMetamodels.kernelNamespaceURI, nsPrefix: "kernel")]
        )
        #expect(throws: LLFSMMetamodelsError.missingClassifier(
            package: LLFSMMetamodels.kernelNamespaceURI, name: "Arrangement")) {
            try KernelMetamodel(rootPackage: kernelOnly)
        }
        #expect(!LLFSMMetamodelsError.missingLiteral(enumeration: "E", literal: "l").description.isEmpty)
    }
}
