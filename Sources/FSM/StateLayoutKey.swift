//
//  StateLayoutKey.swift
//
//  Created by Rene Hexel on 14/10/2016.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
/// Keys for state layout dictionary entries.
///
/// This enumeration defines the keys used in the dictionary representation
/// of state layouts for finite-state machines. Each key corresponds to a
/// layout property, such as position, size, or expanded state.
///
/// - Note: Used for serialisation and deserialisation of state layouts.
public enum StateLayoutKey: String, RawRepresentable, CaseIterable {
    /// Key for the x position
    case positionX = "x"
    /// Key for the y position
    case positionY = "y"
    /// Key for the width
    case width = "w"
    /// Key for the height
    case height = "h"
    /// Key for whether the state is displayed in expanded mode
    case expanded = "expanded"
    /// Key for the unexpanded height of onEntry section
    case onEntryHeight = "onEntryHeight"
    /// Key for the unexpanded height of onExit section
    case onExitHeight = "onExitHeight"
    /// Key for the unexpanded height of the internal section
    case internalHeight = "internalHeight"
    /// Key for the unexpanded height of the onSuspend section
    case onSuspendHeight = "onSuspendHeight"
    /// Key for the unexpanded height of the onResume section
    case onResumeHeight = "onResumeHeight"
    /// Key for the zoomed (full screen) height of the onEntry section
    case zoomedOnEntryHeight = "zoomedOnEntryHeight"
    /// Key for zoomed (full screen) height of the onExit section
    case zoomedOnExitHeight = "zoomedOnExitHeight"
    /// Key for zoomed height of internal section
    case zoomedInternalHeight = "zoomedInternalHeight"
    /// Key for the zoomed (full screen) height of the onSuspend section
    case zoomedOnSuspendHeight = "zoomedOnSuspendHeight"
    /// Key for zoomed (full screen) height of the onResume section
    case zoomedOnResumeHeight = "zoomedOnResumeHeight"
    /// Key for expanded width user defaults
    case expandedWidth = "expandedWidth"
    /// Key for expanded height user defaults
    case expandedHeight = "expandedHeight"
}
