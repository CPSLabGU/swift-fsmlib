//
//  StateLayout.swift
//
//  Created by Rene Hexel on 24/9/2016.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//

/// Abstract representation of a state layout.
///
/// This protocol defines the visual representation of a state node within
/// a finite state machine diagram. Each state node supports both an open
/// (expanded) and a closed (collapsed) layout, allowing the graphical
/// editor to toggle between a compact ellipse view and a detailed
/// rectangular view that reveals the state's activities.
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
            if isOpen { openLayout = newValue } else { closedLayout = newValue }
        }
    }
}

/// State layout structure.
///
/// This is the concrete implementation of `StateNodeLayout` that stores
/// graphical positioning data for a state node. In addition to the open
/// and closed layout frames, it records section heights for each of the
/// state's activities (such as OnEntry, OnExit, Internal, OnSuspend, and
/// OnResume), both at normal and zoomed scales. Any extra properties
/// from the layout property list are also preserved to maintain
/// compatibility with external tools.
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

    /// Extra properties from the property list (for MiCASE compatibility)
    ///
    /// This dictionary stores any additional properties from the layout plist
    /// that are not explicitly handled by this struct, such as `bgColour`
    /// and `strokeColour`. These properties are preserved during serialisation
    /// to maintain compatibility with external tools like MiCASE.
    public var extraProperties: [String: Any]

    /// Designated initialiser.
    ///
    /// - Parameters:
    ///   - isOpen: Whether the state layout is expanded.
    ///   - openLayout: The rectangle used for the expanded state.
    ///   - closedLayout: The ellipse used for the collapsed state.
    ///   - onEntryHeight: Height of the on-entry section.
    ///   - onExitHeight: Height of the on-exit section.
    ///   - onSuspendHeight: Height of the on-suspend section.
    ///   - onResumeHeight: Height of the on-resume section.
    ///   - internalHeight: Height of the internal section.
    ///   - zoomedOnEntryHeight: Zoomed height of the on-entry section.
    ///   - zoomedOnExitHeight: Zoomed height of the on-exit section.
    ///   - zoomedInternalHeight: Zoomed height of the internal section.
    ///   - zoomedOnSuspendHeight: Zoomed height of the on-suspend section.
    ///   - zoomedOnResumeHeight: Zoomed height of the on-resume section.
    ///   - extraProperties: Additional preserved layout properties.
    @inlinable
    public init(
        isOpen: Bool,
        openLayout: Rectangle,
        closedLayout: Ellipse,
        onEntryHeight: Double,
        onExitHeight: Double,
        onSuspendHeight: Double,
        onResumeHeight: Double,
        internalHeight: Double,
        zoomedOnEntryHeight: Double,
        zoomedOnExitHeight: Double,
        zoomedInternalHeight: Double,
        zoomedOnSuspendHeight: Double,
        zoomedOnResumeHeight: Double,
        extraProperties: [String: Any] = [:]
    ) {
        self.isOpen = isOpen
        self.openLayout = openLayout
        self.closedLayout = closedLayout
        self.onEntryHeight = onEntryHeight
        self.onExitHeight = onExitHeight
        self.onSuspendHeight = onSuspendHeight
        self.onResumeHeight = onResumeHeight
        self.internalHeight = internalHeight
        self.zoomedOnEntryHeight = zoomedOnEntryHeight
        self.zoomedOnExitHeight = zoomedOnExitHeight
        self.zoomedInternalHeight = zoomedInternalHeight
        self.zoomedOnSuspendHeight = zoomedOnSuspendHeight
        self.zoomedOnResumeHeight = zoomedOnResumeHeight
        self.extraProperties = extraProperties
    }
}
