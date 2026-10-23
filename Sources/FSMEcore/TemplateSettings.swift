//
//  TemplateSettings.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// The settings with which the bundled templates run.
///
/// The settings apply to the structural templates of ``TemplateBinding`` and
/// to the kernel templates of ``KernelTemplateGenerator``. By default, the
/// templates run with no extra search paths and no parameters, and read unset
/// features as the Eclipse Modeling Framework reports them.
///
/// ```swift
/// var settings = TemplateSettings()
/// settings.parameters["maxRounds"] = "20"
/// settings.searchPaths = [URL(fileURLWithPath: "MyModules")]
/// ```
public struct TemplateSettings: Sendable, Equatable {
    /// Directories searched for imported modules before the bundled template directory.
    ///
    /// A module in one of these directories replaces a bundled module of the
    /// same qualified name; earlier directories take precedence.
    public var searchPaths: [URL]

    /// The template parameters by name, as text.
    ///
    /// Templates read a parameter as the variable `[name/]` or with the service
    /// `parameter('name')`. A text of `true` or `false` is read as a Boolean
    /// and a whole number as an integer.
    public var parameters: [String: String]

    /// How the templates read features that a model does not set.
    public var unsetFeatureReads: UnsetFeatureReads

    /// Create template settings.
    ///
    /// - Parameters:
    ///   - searchPaths: Directories searched for imported modules first (default: none).
    ///   - parameters: The template parameters by name (default: none).
    ///   - unsetFeatureReads: How unset features read (default ``ECore/UnsetFeatureReads/defaults``).
    public init(
        searchPaths: [URL] = [],
        parameters: [String: String] = [:],
        unsetFeatureReads: UnsetFeatureReads = .defaults
    ) {
        self.searchPaths = searchPaths
        self.parameters = parameters
        self.unsetFeatureReads = unsetFeatureReads
    }
}
