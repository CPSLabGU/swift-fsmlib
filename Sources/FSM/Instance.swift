//
//  Instance.swift
//
//  Created by Rene Hexel on 19/08/2023.
//  Copyright © 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Instance of an FSM.
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

public extension Instance {
    /// Return the type name of the machine.
    ///
    /// This returns the name of the type
    /// without the trailing file extension.
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
