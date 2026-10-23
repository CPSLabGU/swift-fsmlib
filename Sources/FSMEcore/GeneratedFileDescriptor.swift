//
//  GeneratedFileDescriptor.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//

/// A generated file: its path relative to an output directory and its text.
///
/// ``KernelTemplateGenerator`` returns the files that the kernel templates
/// generate as descriptors, so that callers can inspect or write them.
public struct GeneratedFileDescriptor: Sendable, Equatable {
    /// Relative output path for the rendered file.
    public let path: String

    /// Textual content to write to the output path.
    public let content: String

    /// Create a file descriptor.
    ///
    /// - Parameters:
    ///   - path: Relative output path.
    ///   - content: Textual file content.
    public init(path: String, content: String) {
        self.path = path
        self.content = content
    }
}
