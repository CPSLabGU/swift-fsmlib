//
//  TransitionLayout+PList.swift
//
//  Created by Rene Hexel on 13/8/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Reading a state layout from a property list
public extension TransitionLayout {
    /// Property list representation
    @inlinable var propertyList: NSDictionary { asPList(layoutDictionary) }

    /// Property list initialiser for a state layout
    /// - Parameter propertyList: The property list to initialise from.
    init(_ propertyList: NSDictionary = [:]) {
        if let points: [Point2D] = propertyList.transitionValue(.bezierPath) {
            path = Path(points)
            return
        }
        let src = (propertyList.transitionValue(.srcPoint) as Point2D?) ??
            (propertyList.transitionValue(.srcPointX) as Double?).flatMap { x in
                (propertyList.transitionValue(.srcPointY) as Double?).flatMap { y in
                Point2D(x, y)
            }
        }
        let dst = (propertyList.transitionValue(.dstPoint) as Point2D?) ??
            (propertyList.transitionValue(.dstPointX) as Double?).flatMap { x in
                (propertyList.transitionValue(.dstPointY) as Double?).flatMap { y in
                Point2D(x, y)
            }
        }
        let ctl1 = (propertyList.transitionValue(.ctlPoint1) as Point2D?) ??
            (propertyList.transitionValue(.ctlPoint1X) as Double?).flatMap { x in
                (propertyList.transitionValue(.ctlPoint1Y) as Double?).flatMap { y in
                Point2D(x, y)
            }
        }
        let ctl2 = (propertyList.transitionValue(.ctlPoint2) as Point2D?) ??
            (propertyList.transitionValue(.ctlPoint2X) as Double?).flatMap { x in
                (propertyList.transitionValue(.ctlPoint2Y) as Double?).flatMap { y in
                Point2D(x, y)
            }
        }
        path = Path([src, ctl1, ctl2, dst].compactMap { $0 })
    }
}

extension TransitionLayout {
    /// Layout dictionary representation
    @usableFromInline var layoutDictionary: LayoutDictionary {
#if canImport(Darwin)
        let propertyList = MutableDictionary()
#else
        var propertyList = MutableDictionary()
#endif
        let points = path.points
        let n = points.count
        guard n > 0 else {
            return propertyList
        }
        propertyList.set(value: points.map(asPList), forTransition: .bezierPath)
        guard n > 1 else {
            return propertyList
        }
        propertyList.set(value: asPList(points[0]),   forTransition: .srcPoint)
        propertyList.set(value: asPList(points[n-1]), forTransition: .dstPoint)
        guard n > 2 else {
            return propertyList
        }
        propertyList.set(value: asPList(points[1]),   forTransition: .ctlPoint1)
        propertyList.set(value: asPList(points[n-2]), forTransition: .ctlPoint2)
        guard n > 3 else {
            return propertyList
        }
        propertyList.set(value: points[0].x,   forTransition: .srcPointX)
        propertyList.set(value: points[0].y,   forTransition: .srcPointY)
        propertyList.set(value: points[n-1].x, forTransition: .dstPointX)
        propertyList.set(value: points[n-1].y, forTransition: .dstPointY)
        propertyList.set(value: points[1].x,   forTransition: .ctlPoint1X)
        propertyList.set(value: points[1].y,   forTransition: .ctlPoint1Y)
        propertyList.set(value: points[n-2].x, forTransition: .ctlPoint2X)
        propertyList.set(value: points[n-2].y, forTransition: .ctlPoint2Y)
        return propertyList
    }
}
