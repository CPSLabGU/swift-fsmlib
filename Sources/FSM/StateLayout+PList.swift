//
//  StateLayout+PList.swift
//
//  Created by Rene Hexel on 29/9/16.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Reading a state layout from a property list
public extension StateLayout {
    /// Property list initialiser for a state layout
    init(_ propertyList: NSDictionary = [:], index i: Int = 0) {
        isOpen = propertyList.value(.expanded, default: false)
        let cw: Double = propertyList.value(.width,          default: 100)
        let ch: Double = propertyList.value(.height,         default: 50)
        let ow: Double = propertyList.value(.expandedWidth,  default: 200)
        let oh: Double = propertyList.value(.expandedHeight, default: 100)
        let cx: Double = propertyList.value(.positionX,      default: cw + ow * Double(i % 8))
        let cy: Double = propertyList.value(.positionY,      default: ch + oh * Double(i / 8))
        let cc = Coordinate2D(cx, cy)
        let sh = oh/3
        openLayout   = Rectangle(centre: cc, dimensions: Dimensions2D(ow, oh))
        closedLayout = Ellipse(centre: cc, dimensions: Dimensions2D(cw, ch))
        onEntryHeight  = propertyList.value(.onEntryHeight,  default: sh)
        onExitHeight   = propertyList.value(.onExitHeight,   default: sh)
        internalHeight = propertyList.value(.internalHeight, default: sh)
        zoomedOnEntryHeight  = propertyList.value(.zoomedOnEntryHeight,  default: sh)
        zoomedOnExitHeight   = propertyList.value(.zoomedOnExitHeight,   default: sh)
        zoomedInternalHeight = propertyList.value(.zoomedInternalHeight, default: sh)
    }
}
