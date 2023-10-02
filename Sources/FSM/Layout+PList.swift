//
//  Layout+PList.swift
//  
//  Created by Rene Hexel on 3/10/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

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
