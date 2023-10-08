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
    /// The finite-state machine.
    public let fsm: LLFSM
    /// Designated initialiser for a machine instance.
    ///
    /// - Parameters:
    ///   - fileName: The unique name of the machine instance.
    ///   - typeFile: The file name of the machine (type).
    ///   - fsm: The underlying finite-state machine.
    @inlinable
    public init(name: String, typeFile: String, fsm: LLFSM) {
        self.name = name
        self.typeFile = typeFile
        self.fsm = fsm
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
}
