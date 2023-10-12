//
//  ArrangementWrapper.swift
//
//  Created by Rene Hexel on 9/10/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//

import Foundation

/// Directory file wrapper wrapping an arrangement of Machines
open class ArrangementWrapper: DirectoryWrapper {
    /// The arrangement wrapped by this class.
    public var arrangement: Arrangement
    /// The language the arrangement is written in.
    public var language: LanguageBinding
    /// Whether or onot the arrangement supports suspension
    public var isSuspensible = true

    /// Create a file wrapper for a directory with the given children.
    /// - Parameters:
    ///   - childrenByPreferredName: Child file wrappers by preferred name.
    ///   - machine: The arrangement to wrap.
    ///   - name: The preferred file name for the arrangement to wrap.
    ///   - language: The language the arrangement is written in.
    @inlinable
    public init(directoryWithFileWrappers childrenByPreferredName: [String : FileWrapper] = [:], for arrangement: Arrangement, named name: String? = nil, language: LanguageBinding? = nil) {
        self.arrangement = arrangement
        self.language = language ?? arrangement.machines.first?.language ?? CBinding()
        super.init(directoryWithFileWrappers: childrenByPreferredName)
        if let name { self.preferredFilename = name }
    }

    /// Initialise from a decoder.
    /// - Note: this is not implemented.
    /// - Parameter inCoder: The coder to initialise from.
    required public init?(coder inCoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Write the content of the arrangement to the specified location.
    ///
    /// Recursively writes the entire arrangement to the specified location.
    ///
    /// - Note: This requires that the `language` is a valid output language.
    /// - Parameters:
    ///   - url: The URL of the location to write to.
    ///   - options: The writing options to use.
    ///   - originalContentsURL: The original URL of the file wrapper.
    override open func write(to url: URL, options: FileWrapper.WritingOptions = [], originalContentsURL: URL? = nil) throws {
        guard let destination = language as? OutputLanguage else {
            throw FSMError.unsupportedOutputFormat
        }
        preferredFilename = url.lastPathComponent
        let wrapperNames = fileWrappers?.keys as? [String] ?? []
        let wrappersAndNames: [(MachineWrapper, Filename)] = wrapperNames.compactMap {
            guard let wrapper = fileWrappers?[$0] as? MachineWrapper else { return nil }
            return (wrapper, $0)
        }
        let names = wrappersAndNames.map { $0.1 }
        let fsmNames: [String] = try arrangement.add(to: self, language: destination, machineNames: names, isSuspensible: isSuspensible)
        let wrappers = wrappersAndNames.map { $0.0 }
        try zip(wrappers, fsmNames).forEach {
            let machineWrapper = $0.0
            let machineName = $0.1
            machineWrapper.preferredFilename = machineName
            try machineWrapper.machine.add(to: machineWrapper, language: destination, isSuspensible: isSuspensible)
        }
        try destination.finalise(self, writingTo: url)
        filename = url.lastPathComponent
    }
}
