//
//  Path.swift
//
//  Created by Rene Hexel on 24/9/2016.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
// swiftlint:disable:this type_contents_order

/// Abstract representation of a bezier path
public protocol BezierPath {
    /// Start, control points, and end point
    var points: [Point2D] { get mutating set }
    /// Designated initialiser
    init(_ pointsList: [Point2D])
}

/// Convenience methods
public extension BezierPath {
    /// Convenience constructor.
    ///
    /// This initialiser creates a bezier path from a list of points.
    ///
    /// - Parameter points: List of points representing the bezier path.
    @inlinable
    init(_ points: Point2D...) {
        self.init(points)
    }
    /// Starting point
    @inlinable var beg: Point2D {
        // swiftlint:disable:next force_unwrapping
        get { return points.first! }
        mutating set { points[0] = newValue }
    }
    /// Control point one
    var cp1: Point2D {
        get { return points[1] }
        mutating set { points[1] = newValue }
    }
    /// Control point two
    var cp2: Point2D {
        get { return points[2] }
        mutating set { points[2] = newValue }
    }
    /// End point
    var end: Point2D {
        // swiftlint:disable:next force_unwrapping
        get { return points.last! }
        mutating set { points[points.count-1] = newValue }
    }
    /// All x coordinates
    var xs: [Double] {
        get { return points.map { $0.x } }
        mutating set { points = zip(newValue, ys).map { Point2D($0, $1) } }
    }
    /// All y coordinates
    var ys: [Double] {
        get { return points.map { $0.y } }
        mutating set { points = zip(xs, newValue).map { Point2D($0, $1) } }
    }
    /// Starting point X coordinate
    var x0: Double {
        get { return beg.x }
        mutating set { beg = Point2D(newValue, beg.y) }
    }
    /// Starting point Y coordinate
    var y0: Double {
        get { return beg.y }
        mutating set { beg = Point2D(beg.x, newValue) }
    }
    /// Control point one X coordinate
    var x1: Double {
        get { return cp1.x }
        mutating set { cp1 = Point2D(newValue, cp1.y) }
    }
    /// Control point one Y coordinate
    var y1: Double {
        get { return cp1.y }
        mutating set { cp1 = Point2D(cp1.x, newValue) }
    }
    /// Control point two X coordinate
    var x2: Double {
        get { return cp2.x }
        mutating set { cp2 = Point2D(newValue, cp2.y) }
    }
    /// Control point two Y coordinate
    var y2: Double {
        get { return cp2.y }
        mutating set { cp2 = Point2D(cp2.x, newValue) }
    }
    /// End point X coordinate
    var xn: Double {
        get { return end.x }
        mutating set { end = Point2D(newValue, end.y) }
    }
    /// End point Y coordinate
    var yn: Double {
        get { return end.y }
        mutating set { end = Point2D(end.x, newValue) }
    }
}

/// Bezier path implementation structure
public struct Path: BezierPath {
    /// Start, control points, and end point.
    public var points: [Point2D]

    /// Designated initialiser
    ///
    /// This initialiser creates a bezier path from an array of points.
    /// The first point is the start point, the last point is the end point,
    /// and all other points are control points.
    ///
    /// - Parameter pointsList: List of points representing the bezier path.
    @inlinable
    public init(_ pointsList: [Point2D]) {
        points = pointsList
    }
}
