//
//  StateLayout+PList.swift
//
//  Created by Rene Hexel on 29/9/16.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//
// swiftlint:disable comma
import Foundation

#if canImport(Darwin)
/// A layout dictionary.
///
/// On Darwin platforms, layout dictionaries
/// are NSDictionary instances.
///
/// - Note: By contrast, on non-Darwin platforms,
/// layout dictionaries are Swift dictionaries.
public typealias LayoutDictionary = NSDictionary
/// Mutable dictionary typealias for layout construction on Darwin platforms.
@usableFromInline typealias MutableDictionary = NSMutableDictionary
/// Return the Layout Dictionary as a Property List dictionary.
///
/// This function performs a simple type conversion that returns the layout
/// dictionary as an NSDictionary, suitable for property list use.
///
/// - Parameter dict: The layout dictionary to convert.
/// - Returns: The NSDictionary representing the property list.
@usableFromInline
func asPList(_ dict: LayoutDictionary) -> NSDictionary {
    dict
}
#else
/// A layout dictionary.
///
/// Typealias for a layout dictionary on non-Darwin platforms,
/// using a Swift dictionary.
///
/// - Note: By contrast, on Darwin platforms,
/// layout dictionaries can be represented as NSDictionary instances.
public typealias LayoutDictionary = [AnyHashable: Any]
/// Mutable dictionary typealias for layout construction on non-Darwin platforms.
@usableFromInline typealias MutableDictionary = LayoutDictionary
/// Return the Layout Dictionary as a Property List dictionary.
///
/// This function performs a type conversion that returns the layout
/// dictionary as an NSDictionary, suitable for property list use.
///
/// - Parameter dict: The layout dictionary to convert.
/// - Returns: The NSDictionary representing the property list.
@usableFromInline
func asPList(_ dict: LayoutDictionary) -> NSDictionary {
    NSDictionary(dictionary: dict, copyItems: false)
}
#endif

/// Extension for reading and writing StateLayout as a property list.
public extension StateLayout {
    /// Property list representation of the state layout.
    ///
    /// This computed property returns the state layout as an NSDictionary,
    /// suitable for serialisation to a property list.
    @inlinable var propertyList: NSDictionary { asPList(layoutDictionary) }

    /// Property list initialiser for a state layout.
    ///
    /// This initialiser constructs a StateLayout from a property list
    /// dictionary, using sensible defaults for missing values. The state
    /// index is used for autolayout positioning if coordinates are not
    /// specified.
    ///
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

/// Extension providing the layout dictionary representation for StateLayout.
extension StateLayout {
    /// Layout dictionary representation of the state layout.
    ///
    /// This computed property returns a dictionary containing all layout
    /// parameters for the state, suitable for serialisation or further
    /// processing.
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
