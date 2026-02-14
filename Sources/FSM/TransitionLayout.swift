//
//  TransitionLayout.swift
//
//  Created by Rene Hexel on 24/9/2016.
//  Copyright © 2015, 2016, 2023 Rene Hexel. All rights reserved.
//

/// Abstract representation of a transition layout.
///
/// This protocol defines the visual representation of a transition
/// between states using a bezier path. Conforming types provide a
/// ``Path`` that describes the curve drawn from one state to another,
/// including its control points for smooth rendering.
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

/// Layout of a transition.
///
/// This is the concrete implementation of `TransitionVertexLayout` that
/// stores the graphical path information for drawing a transition between
/// states. It wraps a ``Path`` instance whose points define the bezier
/// curve connecting a source state to a target state, with intermediate
/// control points that determine the curvature of the drawn line.
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
