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
    var propertyList: NSDictionary {
        let propertyList = NSDictionary()
        let points = path.points
        let n = points.count
        guard n > 0 else { return propertyList }
        propertyList.set(value: points,        forTransition: .bezierPath)
        guard n > 1 else { return propertyList }
        propertyList.set(value: points.first,  forTransition: .srcPoint)
        propertyList.set(value: points.last,   forTransition: .dstPoint)
        guard n > 2 else { return propertyList }
        propertyList.set(value: points[1],     forTransition: .ctlPoint1)
        propertyList.set(value: points[2],     forTransition: .ctlPoint2)
        guard n > 3 else { return propertyList }
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

    /// Property list initialiser for a state layout
    init(_ propertyList: NSDictionary = [:], index i: Int = 0) {
        if let points = propertyList[TransitionLayoutKey.bezierPath] as? [Point2D] {
            path = Path(points)
            return
        }
        let src = (propertyList[TransitionLayoutKey.srcPoint] as? Point2D) ??
            (propertyList[TransitionLayoutKey.srcPointX] as? Double).flatMap { x in
                (propertyList[TransitionLayoutKey.srcPointY] as? Double).flatMap { y in
                Point2D(x, y)
            }
        }
        let dst = (propertyList[TransitionLayoutKey.dstPoint] as? Point2D) ??
            (propertyList[TransitionLayoutKey.dstPointX] as? Double).flatMap { x in
                (propertyList[TransitionLayoutKey.dstPointY] as? Double).flatMap { y in
                Point2D(x, y)
            }
        }
        let ctl1 = (propertyList[TransitionLayoutKey.ctlPoint1] as? Point2D) ??
            (propertyList[TransitionLayoutKey.ctlPoint1X] as? Double).flatMap { x in
                (propertyList[TransitionLayoutKey.ctlPoint1Y] as? Double).flatMap { y in
                Point2D(x, y)
            }
        }
        let ctl2 = (propertyList[TransitionLayoutKey.ctlPoint2] as? Point2D) ??
            (propertyList[TransitionLayoutKey.ctlPoint2X] as? Double).flatMap { x in
                (propertyList[TransitionLayoutKey.ctlPoint2Y] as? Double).flatMap { y in
                Point2D(x, y)
            }
        }
        path = Path([src, ctl1, ctl2, dst].compactMap { $0 })
    }
}
