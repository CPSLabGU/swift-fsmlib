//
//  KernelModelIndex.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase

/// A snapshot of the containment tree of a model resource.
///
/// The index records, for every object reachable from the roots of a
/// resource through containment references, its container, the containing
/// feature and a readable path, so that validation rules can navigate the
/// model synchronously.
struct KernelModelIndex {
    /// One object of the containment tree.
    struct Node {
        /// The object.
        let object: DynamicEObject
        /// The identifier of the container, or `nil` for a root.
        let parent: EUUID?
        /// The name of the containment reference that holds the object.
        let feature: String?
        /// The readable path of the object from its root.
        let path: String
    }

    /// A containment value whose object is not part of the resource.
    struct MissingChild {
        /// The identifier of the containing object.
        let owner: EUUID
        /// The name of the containment reference.
        let feature: String
    }

    /// The objects of the tree, by identifier.
    private(set) var nodes: [EUUID: Node] = [:]

    /// The identifiers of the objects of the tree, depth first in containment order.
    private(set) var order: [EUUID] = []

    /// The identifiers of the root objects, in resource order.
    private(set) var roots: [EUUID] = []

    /// The containment values that could not be resolved.
    private(set) var missingChildren: [MissingChild] = []

    /// The identifiers of the objects directly contained by each object, in containment order.
    private var children: [EUUID: [EUUID]] = [:]

    /// Build the index of a resource.
    ///
    /// - Parameter resource: The resource whose dynamic objects are indexed.
    init(resource: Resource) async {
        var objects: [EUUID: DynamicEObject] = [:]
        for case let object as DynamicEObject in await resource.getAllObjects() {
            objects[object.id] = object
        }
        for case let root as DynamicEObject in await resource.getRootObjects() {
            roots.append(root.id)
            let rootName = root.string(.name).map { $0.isEmpty ? root.eClass.name : $0 } ?? root.eClass.name
            insert(root, parent: nil, feature: nil, path: "/" + rootName, objects: objects)
        }
    }

    /// Add an object and, recursively, its contents to the index.
    private mutating func insert(
        _ object: DynamicEObject,
        parent: EUUID?,
        feature: String?,
        path: String,
        objects: [EUUID: DynamicEObject]
    ) {
        guard nodes[object.id] == nil else { return }
        nodes[object.id] = Node(object: object, parent: parent, feature: feature, path: path)
        order.append(object.id)
        for reference in object.eClass.eAllContainments {
            let identifiers: [EUUID]
            switch object.eGet(reference) {
            case let identifier as EUUID:
                identifiers = [identifier]
            case let many as [EUUID]:
                identifiers = many
            default:
                identifiers = []
            }
            for (position, identifier) in identifiers.enumerated() {
                guard let child = objects[identifier] else {
                    missingChildren.append(MissingChild(owner: object.id, feature: reference.name))
                    continue
                }
                if nodes[child.id] == nil { children[object.id, default: []].append(child.id) }
                let segment: String
                if reference.isMany {
                    let label = child.isSet(.name) ? child.string(.name) ?? String(position) : String(position)
                    segment = "\(reference.name)[\(label)]"
                } else {
                    segment = reference.name
                }
                insert(child, parent: object.id, feature: reference.name, path: path + "/" + segment, objects: objects)
            }
        }
    }

    /// The object with an identifier, if it is part of the tree.
    ///
    /// - Parameter identifier: The identifier to look up.
    /// - Returns: The object, or `nil`.
    func object(_ identifier: EUUID?) -> DynamicEObject? {
        identifier.flatMap { nodes[$0]?.object }
    }

    /// The container of an object.
    ///
    /// - Parameter identifier: The identifier of the contained object.
    /// - Returns: The container, or `nil` for a root or an unknown object.
    func container(of identifier: EUUID) -> DynamicEObject? {
        object(nodes[identifier]?.parent)
    }

    /// The name of the containment reference that holds an object.
    ///
    /// - Parameter identifier: The identifier of the contained object.
    /// - Returns: The reference name, or `nil` for a root or an unknown object.
    func feature(of identifier: EUUID) -> String? {
        nodes[identifier]?.feature
    }

    /// The readable path of an object.
    ///
    /// - Parameter identifier: The identifier of the object.
    /// - Returns: The path, or an empty string for an unknown object.
    func path(of identifier: EUUID) -> String {
        nodes[identifier]?.path ?? ""
    }

    /// The objects held by a reference of an object, in order.
    ///
    /// - Parameters:
    ///   - object: The object that holds the reference.
    ///   - feature: The reference.
    /// - Returns: The referenced objects that are part of the tree.
    func objects(_ feature: LLFSMFeature, of object: DynamicEObject) -> [DynamicEObject] {
        objects(named: feature.rawValue, of: object)
    }

    /// The objects held by a reference given by name, in order.
    ///
    /// - Parameters:
    ///   - name: The name of the reference.
    ///   - object: The object that holds the reference.
    /// - Returns: The referenced objects that are part of the tree.
    func objects(named name: String, of object: DynamicEObject) -> [DynamicEObject] {
        object.identifiers(named: name).compactMap { nodes[$0]?.object }
    }

    /// The object held by a single-valued reference of an object.
    ///
    /// - Parameters:
    ///   - feature: The reference.
    ///   - object: The object that holds the reference.
    /// - Returns: The referenced object, or `nil` if it is unset or not part of the tree.
    func target(_ feature: LLFSMFeature, of object: DynamicEObject) -> DynamicEObject? {
        self.object(object.identifier(feature))
    }

    /// The nearest container of an object whose class satisfies a predicate.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the object to start from (excluded).
    ///   - predicate: The test that the container must pass.
    /// - Returns: The nearest such container, or `nil`.
    func ancestor(of identifier: EUUID, where predicate: (DynamicEObject) -> Bool) -> DynamicEObject? {
        var current = nodes[identifier]?.parent
        while let candidate = current, let node = nodes[candidate] {
            if predicate(node.object) { return node.object }
            current = node.parent
        }
        return nil
    }

    /// All objects of the subtree rooted at an object, depth first, including the object.
    ///
    /// - Parameter object: The root of the subtree.
    /// - Returns: The objects of the subtree.
    func subtree(of object: DynamicEObject) -> [DynamicEObject] {
        var result = [object]
        for child in children[object.id] ?? [] {
            if let node = nodes[child] { result.append(contentsOf: subtree(of: node.object)) }
        }
        return result
    }
}
