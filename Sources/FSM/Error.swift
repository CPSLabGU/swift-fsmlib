//
//  Error.swift
//
//  Created by Rene Hexel on 12/8/2023.
//  Copyright © 2015, 2016, 2023 Rene Hexel. All rights reserved.
//

/// Known errors.
public enum FSMError: String, Error, RawRepresentable, Codable {
    /// Unsupported output format.
    case unsupportedOutputFormat = "Unsupported output format"
}
