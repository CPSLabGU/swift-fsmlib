//
//  TransitionLayout.swift
//
//  Created by Rene Hexel on 24/9/2016.
//  Copyright © 2015, 2016, 2023 Rene Hexel. All rights reserved.
//

/// Abstract representation of a transition layout
public protocol TransitionVertexLayout: BezierPath {
    /// Transition bezier path
    var path: Path { get mutating set }
}

/// Convenience methods to access bezier points
public extension TransitionVertexLayout {
    /// Start, control points, and end point
    @inlinable var points: [Point2D] {
        get { return path.points }
        mutating set { path.points = newValue }
    }
}

/// Layout of a transition
public struct TransitionLayout: TransitionVertexLayout {
    /// Transition bezier path
    public var path: Path
}

/// Bezier point convenience extension
public extension TransitionLayout {
    /// Convenience constructor.
    ///
    /// This initialiser creates a transition layout from a list of points.
    /// The first point is the start point, the last point is the end point,
    /// and all other points are control points.
    ///
    /// - Parameter pointsArray: Array of points representing the transition layout.
    @inlinable
    init(_ pointsArray: [Point2D]) {
        path = Path(pointsArray)
    }
}
