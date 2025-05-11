//
//  Instance.swift
//
//  Created by Rene Hexel on 19/08/2023.
//  Copyright © 2023, 2025 Rene Hexel. All rights reserved.
//
// swiftlint:disable:this type_contents_order
import Foundation

/// Representation of a finite-state machine (FSM) instance.
///
/// This struct encapsulates an instance of a finite-state machine, including
/// its unique name, type file, and a reference to the underlying machine.
/// Instances are used to represent specific occurrences of FSMs within an
/// arrangement, supporting unique identification and type association.
///
/// - Note: The `name` property must be unique within an arrangement, while
///         the `typeFile` does not have to be unique. This allows multiple
///         instances of the same FSM type to be instantiated with different
///         names.
public struct Instance: Equatable, Hashable {
    /// The name of the machine instance.
    ///
    /// This name needs to be unique within an arrangement.
    public let name: String
    /// The name of the machine.
    ///
    /// This represents the typename of the machine.
    /// It does not have to be unique within an arrangement.
    public let typeFile: Filename
    /// Reference to the machine implementing this instance.
    public var machine: Machine
    /// Designated initialiser for a machine instance.
    ///
    /// - Parameters:
    ///   - fileName: The unique name of the machine instance.
    ///   - typeFile: The file name of the machine (type).
    ///   - machine: The underlying finite-state machine.
    @inlinable
    public init(name: String, typeFile: String, machine: Machine) {
        self.name = name
        self.typeFile = typeFile
        self.machine = machine
    }
}

/// Extension providing convenience properties for accessing and mutating
/// instance properties.
public extension Instance {
    /// Return the type name of the machine.
    ///
    /// This computed property returns the type name of the machine instance,
    /// omitting any file extension. It is useful for display, serialisation,
    /// or code generation tasks where the type name is required without file
    /// suffixes.
    ///
    /// - Returns: The type name as a `Substring`, without file extension.
    @inlinable var typeName: Substring {
        typeFile.sansExtension
    }

    /// Compute the hash value for this instance.
    ///
    /// - Parameter hasher: The hasher to use for computing the hash value.
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(typeFile)
        hasher.combine(machine.language.name)
        hasher.combine(machine.llfsm)
    }

    /// Compare two instances for equality.
    /// - Parameters:
    ///   - lhs: The left-hand side instance to compare.
    ///   - rhs: The right-hand side instance to compare.
    /// - Returns: `true` if the two instances are equal, `false` otherwise.
    static func==(lhs: Instance, rhs: Instance) -> Bool {
        lhs.name == rhs.name &&
        lhs.typeFile == rhs.typeFile &&
        lhs.machine.language.name == rhs.machine.language.name &&
        lhs.machine.llfsm == rhs.machine.llfsm
    }
}
