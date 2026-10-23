//
//  ModelDump.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
@testable import FSMEcore

/// A canonical text form of a model for comparing models built in different resources.
///
/// Every object reachable from the roots through containment is written on
/// one line, depth first, with its class, its attributes (unset attributes
/// as their defaults) and its cross references as the paths of their
/// targets. Two models with the same dump have the same content, regardless
/// of object identifiers and of whether a default value was set explicitly.
enum ModelDump {
    /// The dump of the model held by a resource.
    ///
    /// - Parameter resource: The resource whose model is dumped.
    /// - Returns: One line per object.
    static func text(of resource: Resource) async -> String {
        let index = await KernelModelIndex(resource: resource)
        var lines: [String] = []
        for identifier in index.order {
            guard let object = index.object(identifier) else { continue }
            var fields: [String] = []
            for attribute in object.eClass.eAllAttributes {
                fields.append("\(attribute.name)=\(describe(object.eGetWithDefault(attribute)))")
            }
            for reference in object.eClass.eAllReferences where !reference.containment {
                let targets = object.identifiers(named: reference.name).map { index.path(of: $0) }
                guard !targets.isEmpty else { continue }
                fields.append("\(reference.name)->\(targets.joined(separator: ","))")
            }
            lines.append("\(index.path(of: identifier)) \(object.eClass.name) \(fields.joined(separator: " "))")
        }
        return lines.joined(separator: "\n")
    }

    /// The text of an attribute value.
    private static func describe(_ value: (any EcoreValue)?) -> String {
        switch value {
        case nil: return "-"
        case let string as String: return "'\(string)'"
        case let strings as [String]: return "[" + strings.map { "'\($0)'" }.joined(separator: ",") + "]"
        case let value?: return String(describing: value)
        }
    }
}
