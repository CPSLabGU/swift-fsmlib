//
//  Instance.swift
//
//  Created by Rene Hexel on 19/08/2023.
//
import Foundation

/// Instance of an FSM.
public struct Instance: Equatable, Hashable {
    /// The name of the machine instance.
    public let name: String
    /// The URL the machine can be read from.
    public let url: URL
    /// The finite-state machine.
    public let fsm: LLFSM
    /// Designated initialiser for a machine instance.
    ///
    /// - Parameters:
    ///   - name: The unique name of the machine instance.
    ///   - url: The URL the machine can be read from.
    ///   - fsm: The underlying finite-state machine.
    @inlinable
    public init(name: String, url: URL, fsm: LLFSM) {
        self.name = name
        self.url = url
        self.fsm = fsm
    }
}
