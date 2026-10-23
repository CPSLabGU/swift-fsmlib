//
//  OriginAnnotations.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation

/// The role that a kernel element plays in the encoding of a sectioned state.
///
/// The raw values are the literal names of the `OriginRole` enumeration of
/// the kernel metamodel and the values of the ``OriginAnnotations/roleKey``
/// detail.
public enum OriginRole: String, CaseIterable, Sendable {
    /// The state that runs the entry section of a sectioned state.
    case entry
    /// The state that rests between ringlets of a sectioned state.
    case wait
    /// The pass-through state that runs the internal section.
    case `internal`
    /// The pass-through state that runs the exit section for one transition.
    case exit
    /// The pass-through state that runs the suspend section.
    case suspend
    /// The pass-through state that runs the resume section.
    case resume
    /// The pass-through state that dispatches a resumption to the recorded state.
    case dispatch
    /// An element of the clock machine that advances time.
    case clock
}

/// The origin of a kernel element in a sectioned model.
///
/// An origin names the sectioned state that a kernel state or transition
/// encodes, the role the element plays in that encoding and, for exit
/// states, the index of the sectioned transition.
public struct OriginRecord: Sendable, Equatable, Hashable {
    /// The name of the encoded sectioned state, if there is one.
    ///
    /// Elements that encode no sectioned state, such as those of a clock
    /// machine, have no state.
    public var state: String?

    /// The role of the element in the encoding.
    public var role: OriginRole

    /// The zero-based index of the encoded sectioned transition, if any.
    ///
    /// Only exit states and the transitions created for them carry an index.
    public var transition: Int?

    /// Create an origin record.
    ///
    /// - Parameters:
    ///   - state: The name of the encoded sectioned state, if any.
    ///   - role: The role of the element in the encoding.
    ///   - transition: The index of the encoded sectioned transition, if any.
    public init(state: String?, role: OriginRole, transition: Int? = nil) {
        self.state = state
        self.role = role
        self.transition = transition
    }
}

/// Origin records on kernel states and transitions.
///
/// Instance objects cannot carry Ecore annotations, so the kernel metamodel
/// gives `State` and `Transition` an optional `origin` containment of class
/// `Origin`, whose attributes `state`, `role` and `transition` correspond to
/// the detail keys of the annotation source ``source``. The `Origin` class
/// itself carries an annotation with that source that maps each detail key
/// to its attribute. Use ``details(of:)`` and ``record(fromDetails:)`` to
/// convert between records and annotation details, for example when an
/// origin is exchanged with tools that expect annotations.
///
/// ```swift
/// let record = OriginRecord(state: "Waiting", role: .exit, transition: 0)
/// try await OriginAnnotations.setOrigin(record, on: state.id, in: resource, metamodel: kernel)
/// let read = await OriginAnnotations.origin(of: state.id, in: resource)
/// ```
public enum OriginAnnotations {
    /// The annotation source that identifies origin records.
    public static let source = "http://cpslabgu.github.io/llfsm/origin"

    /// The detail key, and `Origin` attribute, that names the sectioned state.
    public static let stateKey = LLFSMFeature.state.rawValue

    /// The detail key, and `Origin` attribute, that names the role.
    ///
    /// Its values are the raw values of ``OriginRole``.
    public static let roleKey = LLFSMFeature.role.rawValue

    /// The detail key, and `Origin` attribute, that holds the transition index.
    public static let transitionKey = LLFSMFeature.transition.rawValue

    /// The annotation details that describe an origin record.
    ///
    /// Absent values are left out.
    ///
    /// - Parameter record: The origin record to describe.
    /// - Returns: The details, keyed by ``stateKey``, ``roleKey`` and ``transitionKey``.
    public static func details(of record: OriginRecord) -> [String: String] {
        var details = [roleKey: record.role.rawValue]
        if let state = record.state { details[stateKey] = state }
        if let transition = record.transition { details[transitionKey] = String(transition) }
        return details
    }

    /// The origin record that annotation details describe.
    ///
    /// - Parameter details: The details of an annotation with source ``source``.
    /// - Returns: The record, or `nil` if the role is missing or unknown, or
    ///   the transition index is not an integer.
    public static func record(fromDetails details: [String: String]) -> OriginRecord? {
        guard let roleName = details[roleKey], let role = OriginRole(rawValue: roleName) else {
            return nil
        }
        var transition: Int?
        if let text = details[transitionKey] {
            guard let index = Int(text) else { return nil }
            transition = index
        }
        return OriginRecord(state: details[stateKey], role: role, transition: transition)
    }

    /// The origin record of a kernel state or transition.
    ///
    /// - Parameters:
    ///   - objectID: The identifier of the state or transition.
    ///   - resource: The resource that holds the object and its origin.
    /// - Returns: The origin record, or `nil` if the object has none.
    public static func origin(of objectID: EUUID, in resource: Resource) async -> OriginRecord? {
        guard let object = await resource.resolve(objectID) as? DynamicEObject,
              let originID = object.identifier(.origin),
              let origin = await resource.resolve(originID) as? DynamicEObject,
              let roleName = origin.string(.role),
              let role = OriginRole(rawValue: roleName)
        else {
            return nil
        }
        let state = origin.isSet(.state) ? origin.string(.state) : nil
        let transition = origin.isSet(.transition) ? origin.int(.transition) : nil
        return OriginRecord(state: state, role: role, transition: transition)
    }

    /// Record, replace or remove the origin of a kernel state or transition.
    ///
    /// A new `Origin` object is registered with the resource and contained
    /// by the object; a previous origin is removed from the resource.
    ///
    /// - Parameters:
    ///   - record: The origin to record, or `nil` to remove the origin.
    ///   - objectID: The identifier of the state or transition.
    ///   - resource: The resource that holds the object.
    ///   - metamodel: The kernel metamodel whose `Origin` class is used.
    /// - Throws: ``OriginAnnotationsError`` if the object is not in the
    ///   resource or its class has no origin.
    public static func setOrigin(
        _ record: OriginRecord?,
        on objectID: EUUID,
        in resource: Resource,
        metamodel: KernelMetamodel
    ) async throws {
        guard let object = await resource.resolve(objectID) as? DynamicEObject else {
            throw OriginAnnotationsError.objectNotFound
        }
        guard object.eClass.getEReference(name: LLFSMFeature.origin.rawValue) != nil else {
            throw OriginAnnotationsError.notAnnotatable(className: object.eClass.name)
        }
        if let previous = object.identifier(.origin) {
            await resource.remove(id: previous)
        }
        guard let record else {
            await resource.eSet(objectId: objectID, feature: LLFSMFeature.origin.rawValue, value: nil)
            return
        }
        var origin = DynamicEObject(eClass: metamodel.originClass)
        origin.eSet(roleKey, value: record.role.rawValue)
        if let state = record.state { origin.eSet(stateKey, value: state) }
        if let transition = record.transition { origin.eSet(transitionKey, value: transition) }
        await resource.register(origin)
        await resource.eSet(objectId: objectID, feature: LLFSMFeature.origin.rawValue, value: origin.id)
    }
}

/// Errors raised while an origin record is written.
public enum OriginAnnotationsError: Error, Sendable, Equatable, CustomStringConvertible {
    /// The object to annotate is not part of the resource.
    case objectNotFound

    /// The class of the object has no origin.
    ///
    /// Only kernel states and transitions carry origins; the associated
    /// value is the name of the class of the object.
    case notAnnotatable(className: String)

    /// A sentence that describes the error.
    public var description: String {
        switch self {
        case .objectNotFound:
            return "The object to annotate is not part of the resource"
        case .notAnnotatable(let className):
            return "Objects of class \(className) cannot carry an origin"
        }
    }
}
