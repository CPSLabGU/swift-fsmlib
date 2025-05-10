//
//  StateLayout.swift
//
//  Created by Rene Hexel on 24/9/2016.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//

/// Abstract representation of a state layout
public protocol StateNodeLayout {
    /// Layout of the state when closed
    var closedLayout: Ellipse { get mutating set }
    /// Layout of the state when open
    var openLayout: Rectangle { get mutating set }
    /// Representation of whether the state uses an open or closed layout
    var isOpen: Bool { get mutating set }
}

/// Helper methods for laying out in the current mode (open or closed)
public extension StateNodeLayout {
    /// Current layout of the state
    var layout: Rectangle {
        get { return isOpen ? openLayout : closedLayout }
        mutating set {
            if isOpen { openLayout = newValue }
            else { closedLayout = newValue }
        }
    }
}

/// State layout structure
public struct StateLayout: StateNodeLayout {
    /// Representation of whether the state uses an open or closed layout
    public var isOpen: Bool

    /// Layout of the state when open
    public var openLayout: Rectangle

    /// Layout of the state when closed
    public var closedLayout: Ellipse

    /// Height of the onEntry section
    public var onEntryHeight: Double

    /// Height of the onExit section
    public var onExitHeight: Double

    /// Height of the onSuspend section
    public var onSuspendHeight: Double

    /// Height of the onResume section
    public var onResumeHeight: Double

    /// Height of the Internal section
    public var internalHeight: Double

    /// Height of the onEntry section when zoomed
    public var zoomedOnEntryHeight: Double

    /// Height of the onExit section when zoomed
    public var zoomedOnExitHeight: Double

    /// Height of the Internal section when zoomed
    public var zoomedInternalHeight: Double

    /// Height of the onSuspend section when zoomed
    public var zoomedOnSuspendHeight: Double

    /// Height of the onResume section when zoomed
    public var zoomedOnResumeHeight: Double
}
