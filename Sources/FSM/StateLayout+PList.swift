//
//  StateLayout+PList.swift
//
//  Created by Rene Hexel on 29/9/16.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

#if canImport(Darwin)
public typealias LayoutDictionary = NSDictionary
@usableFromInline typealias MutableDictionary = NSMutableDictionary
/// Return the Layout Dictionary as a Property List dictionary
/// - Parameter dict: The layout dictionary to convert.
/// - Returns: The NSDictionary representing the property list.
@usableFromInline
func asPList(_ dict: LayoutDictionary) -> NSDictionary {
    dict
}
#else
public typealias LayoutDictionary = [AnyHashable : Any]
@usableFromInline typealias MutableDictionary = LayoutDictionary
/// Return the Layout Dictionary as a Property List dictionary
/// - Parameter dict: The layout dictionary to convert.
/// - Returns: The NSDictionary representing the property list.
@usableFromInline
func asPList(_ dict: LayoutDictionary) -> NSDictionary {
    NSDictionary(dictionary: dict, copyItems: false)
}
#endif

/// Reading a state layout from a property list
public extension StateLayout {
    /// Property list representation
    @inlinable var propertyList: NSDictionary { asPList(layoutDictionary) }

    /// Property list initialiser for a state layout
    /// - Parameters:
    ///   - propertyList: The property list to read from.
    ///   - i: The state index (for autolayout).
    init(_ propertyList: NSDictionary = [:], index i: Int = 0) {
        isOpen = propertyList.value(.expanded, default: false)
        let cw: Double = propertyList.value(.width,          default: 100)
        let ch: Double = propertyList.value(.height,         default: 50)
        let ow: Double = propertyList.value(.expandedWidth,  default: 200)
        let oh: Double = propertyList.value(.expandedHeight, default: 100)
        let cx: Double = propertyList.value(.positionX,      default: cw + ow * Double(i % 8))
        let cy: Double = propertyList.value(.positionY,      default: ch + oh * Double(i / 8))
        let cc = Coordinate2D(cx, cy)
        let sh = oh/6
        openLayout   = Rectangle(centre: cc, dimensions: Dimensions2D(ow, oh))
        closedLayout = Ellipse(centre: cc, dimensions: Dimensions2D(cw, ch))
        onEntryHeight   = propertyList.value(.onEntryHeight,  default: sh)
        onExitHeight    = propertyList.value(.onExitHeight,   default: sh)
        internalHeight  = propertyList.value(.internalHeight, default: sh)
        onSuspendHeight = propertyList.value(.onSuspendHeight, default: sh)
        onResumeHeight  = propertyList.value(.onResumeHeight,  default: sh)
        zoomedOnEntryHeight   = propertyList.value(.zoomedOnEntryHeight,  default: sh)
        zoomedOnExitHeight    = propertyList.value(.zoomedOnExitHeight,   default: sh)
        zoomedInternalHeight  = propertyList.value(.zoomedInternalHeight, default: sh)
        zoomedOnSuspendHeight = propertyList.value(.zoomedOnSuspendHeight, default: sh)
        zoomedOnResumeHeight  = propertyList.value(.zoomedOnResumeHeight,  default: sh)
    }
}

extension StateLayout {
    /// Layout dictionary representation
    @usableFromInline var layoutDictionary: LayoutDictionary {
#if canImport(Darwin)
        let propertyList = MutableDictionary()
#else
        var propertyList = MutableDictionary()
#endif
        propertyList.set(value: isOpen, for: .expanded)
        propertyList.set(value: closedLayout.dimensions.w, for: .width)
        propertyList.set(value: closedLayout.dimensions.h, for: .height)
        propertyList.set(value: openLayout.dimensions.w, for: .expandedWidth)
        propertyList.set(value: openLayout.dimensions.h, for: .expandedHeight)
        propertyList.set(value: closedLayout.x,          for: .positionX)
        propertyList.set(value: closedLayout.y,          for: .positionY)
        propertyList.set(value: onEntryHeight,           for: .onEntryHeight)
        propertyList.set(value: onExitHeight,            for: .onExitHeight)
        propertyList.set(value: internalHeight,          for: .internalHeight)
        propertyList.set(value: onSuspendHeight,         for: .onSuspendHeight)
        propertyList.set(value: onResumeHeight,          for: .onResumeHeight)
        propertyList.set(value: zoomedOnEntryHeight,     for: .zoomedOnEntryHeight)
        propertyList.set(value: zoomedOnExitHeight,      for: .zoomedOnExitHeight)
        propertyList.set(value: zoomedInternalHeight,    for: .zoomedInternalHeight)
        propertyList.set(value: zoomedOnSuspendHeight,   for: .zoomedOnSuspendHeight)
        propertyList.set(value: zoomedOnResumeHeight,    for: .zoomedOnResumeHeight)
        return propertyList
    }
}
