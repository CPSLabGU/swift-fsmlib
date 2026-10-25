//
//  TestResources.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 25/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import Foundation

/// Locates the resources of these tests on every platform.
///
/// The lookup uses the resource bundle of the test target where it is
/// available, and the resource directory beside the test executable
/// otherwise, as on WASI.
enum TestResources {
    /// The name of the resource directory of this test target.
    static let bundleName = ResourceBundleName(package: "FSM", target: "FSMEcoreTests")

    /// Finds a file or directory among the resources of these tests.
    ///
    /// - Parameters:
    ///   - name: The resource name without its extension.
    ///   - ext: The extension, or `nil` for a directory or extensionless file.
    ///   - subdirectory: The directory within the resources, if any.
    /// - Returns: The location of the resource, marked as a directory if it is
    ///   one, or `nil` if it does not exist.
    static func url(forResource name: String, withExtension ext: String?, subdirectory: String? = nil) -> URL? {
        BundledResources.url(
            forResource: name, withExtension: ext, subdirectory: subdirectory, in: .module, bundleName: bundleName
        ).map { URL(fileURLWithPath: $0.path) }
    }
}
