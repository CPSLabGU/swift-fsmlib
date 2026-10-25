//
//  TemplateBinding.swift
//  FSMEcore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import FSM
import Foundation

/// An output language whose files come from the structural templates.
///
/// A `TemplateBinding` holds the files that the structural templates wrote for
/// one machine or one arrangement, keyed by their paths relative to the
/// bundle. Writing a machine or an arrangement with the binding places those
/// files into the bundle that `Machine.write(to:language:isSuspensible:)`
/// or `ArrangementWrapper` manage, so that the templates can stand in
/// for a language binding written in Swift:
///
/// ```swift
/// let binding = try await TemplateBinding.make(for: machine, named: "Counter", format: .c, isSuspensible: true)
/// try machine.write(to: url, language: binding, isSuspensible: true)
/// ```
///
/// The files are rendered when the binding is made, for the name and format
/// given there; write to a bundle of the same name. A machine is rendered in
/// both suspensibility variants, and writing places the variant that the
/// machine storage being written declares, as the Swift writers do; an
/// arrangement and its machines follow the suspensibility given when the
/// binding is made. Reading machines is delegated to the Swift language
/// binding of the format.
public struct TemplateBinding: OutputLanguage {
    /// The language name that the written bundles declare.
    public let name: String

    /// The output format that the files were rendered for.
    public let format: Format

    /// The machine or arrangement name that the files refer to.
    public let bundleName: String

    /// The rendered files, keyed by their path relative to the bundle.
    ///
    /// For an arrangement, the files of each machine are below the directory
    /// of the machine bundle, such as `Counter.machine/States`.
    public let files: [String: Data]

    /// Whether a machine is written as a single file rather than a bundle.
    public let isSingleFile: Bool

    /// The directories of the machine bundles of an arrangement, empty for a machine.
    public let machineDirectories: Set<String>

    /// The rendered files of a machine for each suspensibility, keyed by path relative to the bundle.
    ///
    /// This is empty for an arrangement, and for a machine rendered in one variant only.
    public let suspensibilityVariants: [Bool: [String: Data]]

    /// The language binding that reads machines in the format.
    let reader: any LanguageBinding

    /// The separator between the components of a relative file path.
    static let pathSeparator: Character = "/"

    /// Create a binding from rendered files.
    ///
    /// - Parameters:
    ///   - name: The language name that the written bundles declare.
    ///   - format: The output format that the files were rendered for.
    ///   - bundleName: The machine or arrangement name that the files refer to.
    ///   - files: The rendered files, keyed by their path relative to the bundle.
    ///   - isSingleFile: Whether a machine is written as a single file.
    ///   - machineDirectories: The directories of the machine bundles of an arrangement.
    ///   - suspensibilityVariants: The files of a machine for each suspensibility, if known.
    public init(
        name: String,
        format: Format,
        bundleName: String,
        files: [String: Data],
        isSingleFile: Bool = false,
        machineDirectories: Set<String> = [],
        suspensibilityVariants: [Bool: [String: Data]] = [:]
    ) {
        self.name = name
        self.format = format
        self.bundleName = bundleName
        self.files = files
        self.isSingleFile = isSingleFile
        self.machineDirectories = machineDirectories
        self.suspensibilityVariants = suspensibilityVariants
        self.reader = languageBinding(for: format.rawValue)
    }

    /// Render a machine through the structural templates.
    ///
    /// - Parameters:
    ///   - machine: The machine to render.
    ///   - name: The name of the machine, which is also the name of the bundle without extension.
    ///   - format: The output format.
    ///   - isSuspensible: The suspensibility of the variant that ``files`` holds.
    ///   - settings: The settings with which the templates run (default settings).
    /// - Returns: A binding holding the rendered files of both suspensibility variants.
    /// - Throws: ``StructuralTemplateGeneratorError/unsupportedFormat(_:)`` if no template set
    ///   writes the format, or an error if the templates fail.
    @MainActor
    public static func make(
        for machine: Machine,
        named name: String,
        format: Format,
        isSuspensible: Bool,
        settings: TemplateSettings = TemplateSettings()
    ) async throws -> TemplateBinding {
        let engine = try StructuralTemplateEngine(settings: settings)
        let (set, files) = try await engine.renderMachine(
            machine, named: name, format: format, isSuspensible: isSuspensible)
        var variants = [isSuspensible: files]
        if !set.isSingleFile {
            variants[!isSuspensible] = try await engine.renderMachine(
                machine, named: name, format: format, isSuspensible: !isSuspensible).files
        }
        return TemplateBinding(
            name: set.language,
            format: format,
            bundleName: name,
            files: files,
            isSingleFile: set.isSingleFile,
            suspensibilityVariants: variants
        )
    }

    /// Render an arrangement and its machines through the structural templates.
    ///
    /// - Parameters:
    ///   - arrangement: The arrangement to render.
    ///   - name: The name of the arrangement, which is also the name of the bundle without extension.
    ///   - format: The output format.
    ///   - isSuspensible: Whether to render the suspensible variant of the files.
    ///   - settings: The settings with which the templates run (default settings).
    /// - Returns: A binding holding the rendered files of the arrangement and its machines.
    /// - Throws: ``StructuralTemplateGeneratorError/unsupportedFormat(_:)`` if no template set
    ///   writes arrangements in the format, or an error if the templates fail.
    @MainActor
    public static func make(
        for arrangement: Arrangement,
        named name: String,
        format: Format,
        isSuspensible: Bool,
        settings: TemplateSettings = TemplateSettings()
    ) async throws -> TemplateBinding {
        let engine = try StructuralTemplateEngine(settings: settings)
        let (set, files) = try await engine.renderArrangement(
            arrangement, named: name, format: format, isSuspensible: isSuspensible)
        let suffix = MachineDirectoryWrapper.dottedSuffix
        let directories = Set(arrangement.namedInstances.map {
            $0.typeFile.hasSuffix(suffix) ? $0.typeFile : $0.typeFile + suffix
        })
        return TemplateBinding(
            name: set.language,
            format: format,
            bundleName: name,
            files: files,
            isSingleFile: set.isSingleFile,
            machineDirectories: directories
        )
    }

    /// Tell whether the bundled templates write a format.
    ///
    /// - Parameters:
    ///   - format: The output format.
    ///   - arrangements: Whether the templates must also write arrangements in the format.
    /// - Returns: `true` if a bundled template set writes the format, and arrangements if asked for.
    @MainActor
    public static func supports(_ format: Format, arrangements: Bool = false) -> Bool {
        guard let root = StructuralTemplateEngine.bundledRoot else { return false }
        return StructuralTemplateEngine(root: root).writes(format, arrangements: arrangements)
    }

    /// The content of the single file that a single-file binding writes.
    public var singleFileContents: Data? {
        guard isSingleFile, files.count == 1 else { return nil }
        return files.values.first
    }

    /// The rendered files that belong directly to the arrangement or machine bundle.
    ///
    /// For an arrangement, the files below the machine bundles are excluded.
    public var bundleFiles: [String: Data] {
        files.filter { path, _ in
            guard let first = path.split(separator: Self.pathSeparator).first else { return false }
            return !machineDirectories.contains(String(first)) || !path.contains(Self.pathSeparator)
        }
    }

    /// The rendered files of one machine bundle of an arrangement.
    ///
    /// - Parameter directory: The directory of the machine bundle, such as `Counter.machine`.
    /// - Returns: The files of the machine, keyed by their path relative to the machine bundle.
    public func machineFiles(in directory: String) -> [String: Data] {
        let prefix = directory + String(Self.pathSeparator)
        return files.reduce(into: [:]) { result, entry in
            guard entry.key.hasPrefix(prefix) else { return }
            result[String(entry.key.dropFirst(prefix.count))] = entry.value
        }
    }

    // MARK: - Reading

    /// Count the transitions of a state in stored machine files.
    ///
    /// - Parameters:
    ///   - storage: The machine storage to read.
    ///   - stateName: The name of the state.
    /// - Returns: The number of transitions that leave the state.
    public func numberOfTransitions(for storage: any MachineStorage, stateName: StateName) -> Int {
        reader.numberOfTransitions(for: storage, stateName: stateName)
    }

    /// Read the expression of a transition from stored machine files.
    ///
    /// - Parameters:
    ///   - transitionNumber: The number of the transition, counted from zero.
    ///   - storage: The machine storage to read.
    ///   - stateName: The name of the source state.
    /// - Returns: The transition expression.
    public func expression(of transitionNumber: Int, for storage: any MachineStorage, stateName: StateName) -> String {
        reader.expression(of: transitionNumber, for: storage, stateName: stateName)
    }

    /// Read the target state of a transition from stored machine files.
    ///
    /// - Parameters:
    ///   - transitionNumber: The number of the transition, counted from zero.
    ///   - storage: The machine storage to read.
    ///   - stateName: The name of the source state.
    ///   - states: The states of the machine.
    /// - Returns: The identifier of the target state, or `nil` if it cannot be determined.
    public func target(
        of transitionNumber: Int, for storage: any MachineStorage, stateName: StateName, with states: [State]
    ) -> StateID? {
        reader.target(of: transitionNumber, for: storage, stateName: stateName, with: states)
    }

    /// Read the suspend state from stored machine files.
    ///
    /// - Parameters:
    ///   - storage: The machine storage to read.
    ///   - states: The states of the machine.
    /// - Returns: The identifier of the suspend state, or `nil` if there is none.
    public func suspendState(for storage: any MachineStorage, states: [State]) -> StateID? {
        reader.suspendState(for: storage, states: states)
    }

    /// Read the machine boilerplate from stored machine files.
    ///
    /// - Parameter storage: The machine storage to read.
    /// - Returns: The machine boilerplate.
    public func boilerplate(for storage: any MachineStorage) -> any Boilerplate {
        reader.boilerplate(for: storage)
    }

    /// Read the boilerplate of a state from stored machine files.
    ///
    /// - Parameters:
    ///   - storage: The machine storage to read.
    ///   - stateName: The name of the state.
    /// - Returns: The state boilerplate.
    public func stateBoilerplate(for storage: any MachineStorage, stateName: StateName) -> any Boilerplate {
        reader.stateBoilerplate(for: storage, stateName: stateName)
    }

    /// Return the sections of a machine boilerplate.
    ///
    /// - Parameter boilerplate: The boilerplate to inspect.
    /// - Returns: The boilerplate sections.
    public func extractSections(from boilerplate: any Boilerplate) -> [StandardBoilerplateSection: String] {
        reader.extractSections(from: boilerplate)
    }

    /// Return the sections of a state boilerplate.
    ///
    /// - Parameters:
    ///   - boilerplate: The boilerplate to inspect.
    ///   - stateName: The name of the state.
    /// - Returns: The boilerplate sections.
    public func extractStateSections(
        from boilerplate: any Boilerplate, stateName: StateName
    ) -> [StandardBoilerplateSection: String] {
        reader.extractStateSections(from: boilerplate, stateName: stateName)
    }

    /// Create a machine boilerplate from sections.
    ///
    /// - Parameter sections: The boilerplate sections.
    /// - Returns: The boilerplate.
    public func createBoilerplate(from sections: [StandardBoilerplateSection: String]) -> any Boilerplate {
        reader.createBoilerplate(from: sections)
    }

    /// Create a state boilerplate from sections.
    ///
    /// - Parameters:
    ///   - sections: The boilerplate sections.
    ///   - stateName: The name of the state.
    /// - Returns: The boilerplate.
    public func createStateBoilerplate(
        from sections: [StandardBoilerplateSection: String], stateName: StateName
    ) -> any Boilerplate {
        reader.createStateBoilerplate(from: sections, stateName: stateName)
    }

    // MARK: - Writing

    /// Create the storage that a machine is written to.
    ///
    /// - Parameters:
    ///   - url: The location to write the machine to.
    ///   - machine: The machine to write.
    /// - Returns: A directory bundle, or a single file for a single-file binding.
    public func createWrapper(at url: URL, for machine: Machine?) throws -> any MachineStorage {
        let machine = machine ?? Machine()
        if isSingleFile {
            let storage = TemplateFileStorage(machine: machine, named: url.lastPathComponent)
            storage.language = self
            return storage
        }
        return MachineDirectoryWrapper(directoryWithFileWrappers: [:], for: machine, named: url.lastPathComponent)
    }

    /// Create the bundle that an arrangement is written to.
    ///
    /// - Parameter url: The location to write the arrangement to.
    /// - Returns: An empty arrangement bundle.
    /// - Throws: ``TemplateBindingError/arrangementsUnsupported`` for a single-file binding.
    public func createArrangementWrapper(at url: URL) throws -> ArrangementWrapper {
        guard !isSingleFile else { throw TemplateBindingError.arrangementsUnsupported }
        let wrapper = ArrangementWrapper(directoryWithFileWrappers: [:], for: Arrangement(namedInstances: []))
        wrapper.preferredFilename = url.lastPathComponent
        return wrapper
    }

    /// Place the rendered files into a bundle.
    ///
    /// Writing a machine or an arrangement adds the language first, so this is
    /// where the binding places every rendered file of the bundle; the other
    /// writing steps have nothing left to add. A machine bundle written on its
    /// own receives the variant for the suspensibility that it declares.
    ///
    /// - Parameter wrapper: The machine or arrangement bundle.
    /// - Throws: ``TemplateBindingError/unknownBundle(_:)`` if the binding holds no files for
    ///   the bundle, and ``TemplateBindingError/nameMismatch(expected:found:)`` if a machine
    ///   bundle has a different name from the one the files were rendered for.
    public func addLanguage(to wrapper: FileWrapper) throws {
        guard !isSingleFile, wrapper.isDirectory else { return }
        if wrapper is ArrangementWrapper {
            try place(bundleFiles, into: wrapper)
        } else if machineDirectories.isEmpty {
            let storage = wrapper as? any MachineStorage
            if let storage, storage.name != bundleName {
                throw TemplateBindingError.nameMismatch(expected: bundleName, found: storage.name)
            }
            try place(storage.flatMap { suspensibilityVariants[$0.isSuspensible] } ?? files, into: wrapper)
        } else {
            let directory = wrapper.preferredFilename ?? wrapper.filename ?? ""
            guard machineDirectories.contains(directory) else {
                throw TemplateBindingError.unknownBundle(directory)
            }
            try place(machineFiles(in: directory), into: wrapper)
        }
    }

    /// Place files into a directory wrapper, creating subdirectories as needed.
    ///
    /// - Parameters:
    ///   - files: The files keyed by their path relative to the wrapper.
    ///   - wrapper: The directory wrapper to place the files into.
    /// - Throws: ``TemplateBindingError/invalidPath(_:)`` if a path is empty.
    func place(_ files: [String: Data], into wrapper: FileWrapper) throws {
        var nested: [String: [String: Data]] = [:]
        for (path, data) in files {
            let components = path.split(
                separator: Self.pathSeparator, maxSplits: 1, omittingEmptySubsequences: false
            ).map(String.init)
            guard let first = components.first, !first.isEmpty else { throw TemplateBindingError.invalidPath(path) }
            if components.count == 1 {
                let file = FileWrapper(regularFileWithContents: data)
                file.preferredFilename = first
                replace(file, named: first, in: wrapper)
            } else {
                nested[first, default: [:]][components[1]] = data
            }
        }
        for (directoryName, contents) in nested {
            let directory: FileWrapper
            if let existing = wrapper.fileWrappers?[directoryName], existing.isDirectory {
                directory = existing
            } else {
                directory = FileWrapper(directoryWithFileWrappers: [:])
                directory.preferredFilename = directoryName
                replace(directory, named: directoryName, in: wrapper)
            }
            try place(contents, into: directory)
        }
    }

    /// Replace the child of a directory wrapper that has a given name.
    ///
    /// - Parameters:
    ///   - child: The new child.
    ///   - name: The name of the child.
    ///   - wrapper: The directory wrapper.
    private func replace(_ child: FileWrapper, named name: String, in wrapper: FileWrapper) {
        if let existing = wrapper.fileWrappers?[name] {
            wrapper.removeFileWrapper(existing)
        }
        _ = wrapper.addFileWrapper(child)
    }

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - layout: The state and transition layouts.
    ///   - storage: The machine storage.
    public func add(layout: StateNameLayouts, to storage: any MachineStorage) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - windowLayout: The window layout.
    ///   - storage: The machine storage.
    public func add(windowLayout: Data?, to storage: any MachineStorage) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - stateNames: The names of the states.
    ///   - storage: The machine storage.
    public func add(stateNames: StateNames, to storage: any MachineStorage) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - boilerplate: The machine boilerplate.
    ///   - storage: The machine storage.
    public func add(boilerplate: any Boilerplate, to storage: any MachineStorage) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - stateBoilerplate: The state boilerplate.
    ///   - storage: The machine storage.
    ///   - stateName: The name of the state.
    public func add(stateBoilerplate: any Boilerplate, to storage: any MachineStorage, for stateName: String) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine.
    ///   - storage: The machine storage.
    ///   - isSuspensible: Whether the machine is suspensible.
    public func addInterface(for llfsm: LLFSM, to storage: any MachineStorage, isSuspensible: Bool) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - fsm: The finite-state machine.
    ///   - storage: The machine storage.
    ///   - isSuspensible: Whether the machine is suspensible.
    public func addStateInterface(for fsm: LLFSM, to storage: any MachineStorage, isSuspensible: Bool) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - instances: The instances of the arrangement.
    ///   - wrapper: The arrangement bundle.
    ///   - isSuspensible: Whether the machines are suspensible.
    public func addArrangementInterface(
        for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool
    ) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - llfsm: The finite-state machine.
    ///   - storage: The machine storage.
    ///   - isSuspensible: Whether the machine is suspensible.
    public func addCode(for llfsm: LLFSM, to storage: any MachineStorage, isSuspensible: Bool) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - fsm: The finite-state machine.
    ///   - storage: The machine storage.
    ///   - isSuspensible: Whether the machine is suspensible.
    public func addStateCode(for fsm: LLFSM, to storage: any MachineStorage, isSuspensible: Bool) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - fsm: The finite-state machine.
    ///   - storage: The machine storage.
    ///   - isSuspensible: Whether the machine is suspensible.
    public func addTransitionCode(for fsm: LLFSM, to storage: any MachineStorage, isSuspensible: Bool) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - instances: The instances of the arrangement.
    ///   - wrapper: The arrangement bundle.
    ///   - isSuspensible: Whether the machines are suspensible.
    public func addArrangementCode(
        for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool
    ) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - fsm: The finite-state machine.
    ///   - boilerplate: The machine boilerplate.
    ///   - storage: The machine storage.
    ///   - isSuspensible: Whether the machine is suspensible.
    public func addCMakeFile(
        for fsm: LLFSM, boilerplate: any Boilerplate, to storage: any MachineStorage, isSuspensible: Bool
    ) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - instances: The instances of the arrangement.
    ///   - wrapper: The arrangement bundle.
    ///   - isSuspensible: Whether the machines are suspensible.
    public func addArrangementCMakeFile(
        for instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool
    ) throws {}

    /// Nothing further to add: the rendered files are placed when the language is added.
    ///
    /// - Parameters:
    ///   - instances: The instances of the arrangement.
    ///   - wrapper: The arrangement bundle.
    ///   - isSuspensible: Whether the machines are suspensible.
    public func addArrangementMachine(
        instances: [Instance], to wrapper: ArrangementWrapper, isSuspensible: Bool
    ) throws {}
}

/// The problems found when writing with a ``TemplateBinding``.
public enum TemplateBindingError: Error, LocalizedError, Equatable, Sendable {
    /// The binding writes single files and therefore no arrangements.
    case arrangementsUnsupported

    /// The binding holds no files for the named machine bundle.
    case unknownBundle(String)

    /// A machine bundle has a different name from the one its files were rendered for.
    case nameMismatch(expected: String, found: String)

    /// A rendered file has an empty path.
    case invalidPath(String)

    /// Storage written by the binding cannot be read back through it.
    case readingUnsupported

    /// The binding holds no single file to write.
    case missingFile

    /// A description of the problem.
    public var errorDescription: String? {
        switch self {
        case .arrangementsUnsupported:
            return "The template set writes single files and cannot write arrangements"
        case .unknownBundle(let name):
            return "No rendered files for the machine bundle '\(name)'"
        case .nameMismatch(let expected, let found):
            return "The files were rendered for '\(expected)' but the bundle is named '\(found)'"
        case .invalidPath(let path):
            return "Invalid rendered file path '\(path)'"
        case .readingUnsupported:
            return "Files written through templates are read with the language binding of their format"
        case .missingFile:
            return "The template set did not render exactly one file"
        }
    }
}

/// Storage that writes the single file rendered by a ``TemplateBinding``.
///
/// Single-file formats keep a whole machine in one file. This storage takes
/// the file that the templates rendered and writes it to the requested
/// location in one atomic step.
public final class TemplateFileStorage: MachineStorage {
    /// The machine being written.
    public var machine: Machine

    /// The language the machine is written in.
    public var language: any LanguageBinding

    /// Whether the machine is written as suspensible.
    public var isSuspensible: Bool = true

    /// The regular file wrapper that names the written file.
    public let fileWrapper: FileWrapper

    /// Reading is not supported; read the file with the language binding of its format.
    ///
    /// - Parameter url: The location of the file.
    /// - Throws: ``TemplateBindingError/readingUnsupported`` always.
    public required init(url: URL) throws {
        throw TemplateBindingError.readingUnsupported
    }

    /// Create storage for writing a machine.
    ///
    /// - Parameters:
    ///   - machine: The machine to write.
    ///   - name: The preferred file name.
    public required init(machine: Machine, named name: String) {
        self.machine = machine
        self.language = machine.language
        let wrapper = FileWrapper(regularFileWithContents: Data())
        wrapper.preferredFilename = name
        self.fileWrapper = wrapper
    }

    /// Write the rendered file.
    ///
    /// - Parameters:
    ///   - url: The location to write to.
    ///   - options: Writing options, which a single atomic file write does not need.
    /// - Throws: ``TemplateBindingError/missingFile`` if the language is not a single-file
    ///   ``TemplateBinding`` with exactly one rendered file, or an error if writing fails.
    public func write(to url: URL, options: FileWrapper.WritingOptions) throws {
        guard let binding = language as? TemplateBinding, let data = binding.singleFileContents else {
            throw TemplateBindingError.missingFile
        }
        try data.write(to: url, options: FileWritingSupport.atomicWritingOptions)
    }
}
