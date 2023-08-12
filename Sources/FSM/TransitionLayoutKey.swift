//
//  TransitionLayoutKey.swift
//
//  Created by Rene Hexel on 14/10/2016.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
/// Keys for transition layout.
public enum TransitionLayoutKey: String, RawRepresentable, CaseIterable {
    /// Dictionary key for the array of transition layouts.
    case transitions = "Transitions"
    /// Full bezier path from source point to destination point
    case bezierPath = "bezierPath"
    /// Key for source point
    case srcPoint = "srcPoint"
    /// Key for source point x dimension.
    case srcPointX = "srcPointX"
    /// Key for source point y dimension.
    case srcPointY = "srcPointY"
    /// Key for destination point
    case dstPoint = "dstPoint"
    /// Key for destination point x dimension.
    case dstPointX = "dstPointX"
    /// Key for destination point y dimension.
    case dstPointY = "dstPointY"
    /// Key for control point 1
    case ctlPoint1 = "controlPoint1"
    /// Key for control point 1 x dimension.
    case ctlPoint1X = "controlPoint1X"
    /// Key for control point 1 y dimension.
    case ctlPoint1Y = "controlPoint1Y"
    /// Key for control point 2
    case ctlPoint2 = "controlPoint2"
    /// Key for control point 2 x dimension.
    case ctlPoint2X = "controlPoint2X"
    /// Key for control point 2 y dimension.
    case ctlPoint2Y = "controlPoint2Y"
}
