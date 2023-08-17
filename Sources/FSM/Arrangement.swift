//
//  Arrangement.swift
//
//  Created by Rene Hexel on 17/08/2023.
//  Copyright © 2015, 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Arrangement of multiple FSMs.
public struct Arrangement {
    /// The FSMs in this arrangement.
    public var machines: [Machine]

    /// Designated initialiser.
    /// - Parameter machines: The machines in this arrangement.
    @inlinable
    public init(machines: [Machine]) {
        self.machines = machines
    }

    /// Write the arrangement to the given URL.
    ///
    /// This method creates a file wrapper for an arrangement
    /// of FSMs and writes it to the given URL.
    ///
    /// - Parameters:
    ///   - url: The output URL for the arrangement.
    ///   - inputURLs: The original URLs associated with the FSMs.
    ///   - format: The format of the output URL.
    ///   - isSuspensible: Whether the output FSMs should be suspensible.
    /// - Returns: The URLs for writing the output FSMs.
    @inlinable
    public func write(to url: URL, inputURLs: [URL], format: Format? = nil, isSuspensible: Bool = true) throws -> [URL] {
        try write(to: url, inputURLs: inputURLs, language: format.flatMap { formatToLanguageBinding[$0] }, isSuspensible: isSuspensible)
    }

    /// Write the arrangement to the given URL.
    ///
    /// This method creates a file wrapper for an arrangement
    /// of FSMs and writes it to the given URL.
    ///
    /// - Parameters:
    ///   - url: The output URL for the arrangement.
    ///   - inputURLs: The original URLs associated with the FSMs.
    ///   - language: The language to use (defaults to the original language of the first machine).
    ///   - isSuspensible: Whether the output FSMs should be suspensible.
    /// - Returns: The URLs for writing the output FSMs.
    @inlinable
    public func write(to url: URL, inputURLs: [URL], language: LanguageBinding? = nil, isSuspensible: Bool = true) throws -> [URL] {
        guard let destination = (language ?? machines.first?.language) as? OutputLanguage else {
            throw FSMError.unsupportedOutputFormat
        }
        var fsms = [ String : Machine ]()
        let machineNames = zip(machines, inputURLs).enumerated().map {
            let i = $0.0
            let machine = $0.1.0
            let url = $0.1.1
            let name = url.deletingPathExtension().lastPathComponent
            let uniqueName = fsms[name] == nil ? name : "\(name)_\(i)"
            fsms[uniqueName] = machine
            return uniqueName
        }
        let machineFiles = inputURLs.map(\.lastPathComponent)
        try destination.createArrangement(at: url)
        try destination.writeLanguage(to: url)
        defer { try? destination.finalise(url) }
        return zip(machines, machineFiles).map { url.appending(path: $0.1) }
    }
}
