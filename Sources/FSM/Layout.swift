//
//  Layout.swift
//
//  Created by Rene Hexel on 24/9/2016.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

/// A simple, 2-dimensional vector
public protocol Vector2D {
    /// X coordinate
    var x: Double { get mutating set }
    /// Y coordinate
    var y: Double { get mutating set }
    /// Designated initialiser
    init(_ x: Double, _ y: Double)
}

/// Pi as a double
let π = Double.pi

/// Two times Pi
// swiftlint:disable identifier_name
let two_π = 2 * π

/// Half of Pi
// swiftlint:disable identifier_name
let half_π = π / 2


/// polar coordinate helper functions
public extension Vector2D {
    /// distance from (0,0)
    var polarDistance: Double { return sqrt(x*x + y*y) }
    
    /// angle in radians
    var polarAngle: Double {
        guard x != 0 else { return y > 0 ? half_π : (two_π - half_π) }
        let angle = atan(y/x) + x < 0 ? π : 0
        return angle
    }
    
    /// initialise from polar coordinates
    init(r: Double, θ: Double) { self.init(r * cos(θ), r * sin(θ)) }
}

/// distance helper properties
public extension Vector2D {
    /// Width
    var w: Double {
        get { return x }
        mutating set { x = newValue }
    }

    /// Height
    var h: Double {
        get { return y }
        mutating set { y = newValue }
    }
}


/// add two vectors
public func +<V: Vector2D>(lhs: V, rhs: V) -> V {
    return V(lhs.x + rhs.x, lhs.y + rhs.y)
}

/// subtract two vectors
public func -<V: Vector2D>(lhs: V, rhs: V) -> V {
    return V(lhs.x + rhs.x, lhs.y + rhs.y)
}

/// A 2-dimensional coordinate implementation
public struct Coordinate2D: Vector2D {
    /// X coordinate
    public var x: Double
    /// Y coordinate
    public var y: Double
    /// Designated initialiser
    public init(_ initialX: Double = 0, _ initialY: Double = 0) {
        x = initialX
        y = initialY
    }
}

/// A 2-dimensional point
public typealias Point2D = Coordinate2D

/// A 2-dimensional point
public typealias Dimensions2D = Coordinate2D


/// Abstract representation of a rectangle
public protocol Rectangle2D {
    /// Coordinates of the top left corner
    var topLeft: Coordinate2D { get mutating set }
    /// Rectangle dimensions (width and height)
    var dimensions: Dimensions2D { get mutating set }
}


public extension Rectangle2D {
    /// Width
    var w: Double {
        get { return dimensions.w }
        mutating set { dimensions.w = newValue }
    }
    /// Height
    var h: Double {
        get { return dimensions.h }
        mutating set { dimensions.h = newValue }
    }
    /// Centre point X coordinate
    var x: Double {
        get { return topLeft.x + w/2 }
        mutating set { topLeft.x = newValue - w/2 }
    }
    /// Centre point Y coordinate
    var y: Double {
        get { return topLeft.y + h/2 }
        mutating set { topLeft.y = newValue - h/2 }
    }
    /// Top left point X coordinate
    var leftX: Double {
        get { return topLeft.x }
        mutating set { topLeft.x = newValue }
    }
    /// Top left point Y coordinate
    var topY: Double {
        get { return topLeft.y }
        mutating set { topLeft.y = newValue }
    }
    /// Bottom right point X coordinate
    var rightX: Double {
        get { return topLeft.x + w - 1 }
        mutating set { topLeft.x = newValue - w + 1 }
    }
    /// Bottom right point Y coordinate
    var bottomY: Double {
        get { return topLeft.y + h - 1 }
        mutating set { topLeft.y = newValue - h + 1 }
    }
    /// Bottom right position
    var bottomRight: Coordinate2D {
        get { return Coordinate2D(rightX, bottomY) }
        mutating set { rightX = newValue.x ; bottomY = newValue.y }
    }
    /// Top right position
    var topRight: Coordinate2D {
        get { return Coordinate2D(rightX, topY) }
        mutating set { rightX = newValue.x ; topY = newValue.y }
    }
    /// Bottom left position
    var bottomLeft: Coordinate2D {
        get { return Coordinate2D(leftX, bottomY) }
        mutating set { leftX = newValue.x ; bottomY = newValue.y }
    }
}


/// Rectangle implementation
public struct Rectangle: Rectangle2D {
    /// Coordinates of the top left corner
    public var topLeft: Coordinate2D
    /// Rectangle dimensions (width and height)
    public var dimensions: Dimensions2D

    /// Designated initialiser.
    ///
    /// Initialise a rectangle with the given» top left corner and dimensions.
    ///
    /// - Parameters:
    ///   - topLeft: The top left corner coordinates.
    ///   - dimensions: The dimensions of the rectangle.
    @inlinable
    public init(topLeft: Coordinate2D, dimensions: Dimensions2D) {
        self.topLeft = topLeft
        self.dimensions = dimensions
    }
}

public extension Rectangle {
    /// Initialise a rectangle from a centre position and dimensions.
    ///
    /// This initialiser takes a centre position and dimensions and computes the
    /// top left corner position for the rectangle.
    ///
    /// - Parameters:
    ///   - centre: The centre coordinates of the rectangle.
    ///   - dimensions: The dimensions of the rectangle.
    @inlinable
    init(centre: Coordinate2D, dimensions: Dimensions2D) {
        self = Rectangle(topLeft: Coordinate2D(centre.x - dimensions.w / 2, centre.y - dimensions.h / 2), dimensions: dimensions)
    }
}

/// An ellipse that fits into a given rectangle
public typealias Ellipse = Rectangle
