//
//  Error.swift
//
//  Created by Rene Hexel on 12/8/2023.
//  Copyright © 2015, 2016, 2023 Rene Hexel. All rights reserved.
//

/// Known errors.
///
/// This enumeration defines the error conditions that can be thrown by the
/// FSM library, such as attempting to use an unsupported output format or
/// operating on a non-directory file wrapper.
public enum FSMError: String, Error, RawRepresentable, Codable {
    /// Unsupported output format.
    case unsupportedOutputFormat = "Unsupported output format"
    /// Not a directory
    case notADirectory = "Not a directory"
}
