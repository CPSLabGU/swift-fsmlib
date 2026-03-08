//
//  StateLayout.swift
//
//  Created by Rene Hexel on 24/9/2016.
//  Copyright © 2016, 2023, 2025 Rene Hexel. All rights reserved.
//

/// State node layout protocol.
///
/// `StateNodeLayout` defines the geometry required to render a state in both
/// collapsed and expanded form. Conforming types expose the two shapes and the
/// flag that selects which one is active.
public protocol StateNodeLayout {
    /// Closed-state geometry.
    ///
    /// This shape is used when the state is shown in its compact form.
    var closedLayout: Ellipse { get mutating set }
    /// Open-state geometry.
    ///
    /// This shape is used when the state is shown with its activity sections.
    var openLayout: Rectangle { get mutating set }
    /// Open-state flag.
    ///
    /// This flag selects whether the state currently uses its open or closed
    /// geometry.
    var isOpen: Bool { get mutating set }
}

/// Helper methods for state node layouts.
///
/// These helpers derive the currently active geometry from the open and closed
/// layout values exposed by `StateNodeLayout`.
public extension StateNodeLayout {
    /// Active geometry for the current state mode.
    ///
    /// Reading this property returns the open or closed geometry depending on
    /// `isOpen`. Writing through it updates the matching stored geometry.
    var layout: Rectangle {
        get { return isOpen ? openLayout : closedLayout }
        mutating set {
            if isOpen { openLayout = newValue } else { closedLayout = newValue }
        }
    }
}

/// State layout value.
///
/// `StateLayout` stores the rendered geometry for a state together with the
/// heights of each visible activity section. It preserves additional plist
/// properties so imported layouts can round-trip without discarding editor
/// metadata.
public struct StateLayout: StateNodeLayout {
    /// Open-state flag.
    ///
    /// This flag selects whether the state currently uses the expanded
    /// geometry.
    public var isOpen: Bool

    /// Open-state geometry.
    ///
    /// This rectangle is used when the state is expanded.
    public var openLayout: Rectangle

    /// Closed-state geometry.
    ///
    /// This ellipse is used when the state is collapsed.
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

    /// Create a state layout value.
    ///
    /// Use this initialiser when constructing a layout explicitly from decoded
    /// geometry or test data, rather than from the property-list convenience
    /// initialiser in `StateLayout+PList.swift`.
    ///
    /// - Parameters:
    ///   - isOpen: Whether the layout should use the expanded geometry.
    ///   - openLayout: Rectangle used for the expanded state.
    ///   - closedLayout: Ellipse used for the collapsed state.
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
