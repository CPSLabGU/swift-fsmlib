//
//  Arrangement+Serialisation.swift
//  
//  Created by Rene Hexel on 10/2/2024.
//  Copyright © 2024, 2025 Rene Hexel. All rights reserved.
//

/// Extension providing serialisation-related filename constants.
///
/// This extension defines filename constants used for serialising and
/// deserialising arrangements of finite-state machines. These filenames are
/// used when reading or writing lists of machines to text files.
///
/// - Note: The `machines` constant specifies the name of the text file that
///         contains machine names, one per line, for arrangement serialisation.
extension Filename {
    /// Name of the text file containing machine names (one per line).
    @usableFromInline static let machines = "Machines"
}
