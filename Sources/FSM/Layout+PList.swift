//
//  Layout+PList.swift
//  
//  Created by Rene Hexel on 3/10/2023.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Extension providing property list serialisation for Vector2D types.
///
/// This extension enables conversion of 2D vector types to property list
/// representations, facilitating serialisation and deserialisation for
/// persistent storage or data interchange. The property list representation
/// is an NSArray containing the x and y components of the vector.
public extension Vector2D {
    /// Property list representation
    @inlinable var propertyList: NSArray { [x, y] }
}

/// Return the vector as a Property List array.
/// - Parameter vector: The vector to convert to a property list.
/// - Returns: The NSArray representing the property list.
@usableFromInline
func asPList<V: Vector2D>(_ vector: V) -> NSArray {
    [ vector.x, vector.y ]
}
