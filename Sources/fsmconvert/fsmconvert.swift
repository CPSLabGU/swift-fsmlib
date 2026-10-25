import ArgumentParser
import ECore
import Foundation
import FSM
import FSMEcore
import ModellingCommandLine
import ModellingGenerators

/// Command-line tool for converting FSMs and arrangements.
///
/// This struct implements the main entry point for the `fsmconvert` tool, which
/// reads FSM machine files, arrangements or model documents, optionally combines
/// them, transforms them between the structural, sectioned and kernel levels,
/// and writes the output in the specified format or generates a kernel target.
///
/// - Note: Designed for use in automated build systems and scripting.
@main
struct FSMConvert: AsyncParsableCommand {
    /// The name, summary and discussion of the command.
    static let configuration = CommandConfiguration(
        commandName: "fsmconvert",
        abstract: "Convert, transform, validate and generate logic-labelled finite-state machines.",
        discussion: """
            fsmconvert reads .machine and .arrangement bundles, SCXML documents, and XMI or JSON \
            models at the structural, sectioned or kernel level, which it recognises by the \
            namespace of the root element. It transforms the model along the shortest chain of \
            levels to the one that --format needs, and writes a native format, a model document \
            or a kernel target.

            Native formats: \(OutputTargetNames.native). Model documents: \(OutputTargetNames.models). \
            Kernel targets: \(OutputTargetNames.kernel). With --\(OptionName.metamodel) \
            \(LLFSMLevel.kernel.rawValue), the names \(OutputTargetNames.kernelSynonyms) stand for \
            the kernel targets of those languages, and xmi and json write the level that \
            --\(OptionName.metamodel) names.
            """
    )

    /// Whether to create an arrangement of a single FSM.
    ///
    /// This option enables the creation of an arrangement of a single FSM.
    @Flag(name: .shortAndLong, help: "Create an arrangement of a single FSM.")
    var arrangement = false

    /// The output format or target.
    ///
    /// This option specifies the native machine format, model document or kernel
    /// target to write. It can be an empty string to use the default format of the
    /// machine, or of the output file extension.
    @Option(
        name: [.customShort(OptionName.formatShort), .customLong(OptionName.format)],
        help: ArgumentHelp(
            "The output machine format, model document or kernel target.",
            discussion: "One of \(OutputTargetNames.all).",
            valueName: OptionName.format),
        transform: { try FSMConvert.formatName(from: $0) })
    var format = ""

    /// Make the generated code introspectable.
    ///
    /// This option enables introspection, which allows the generated code to
    /// provide additional information about the machine.
    @Flag(name: .shortAndLong, help: "Make the generated code introspectable.")
    var introspectable = false

    /// Make the generated machine non-suspensible.
    ///
    /// This option disables suspensibility, which means the generated machine
    /// cannot be suspended.
    @Flag(name: .shortAndLong, help: "Make the generated machine non-suspensible.")
    var nonSuspensible = false

    /// The output machine/arrangement.
    ///
    /// This option specifies the output machine/arrangement. It can be a file
    /// or a directory; kernel targets are written into this directory.
    @Option(name: .shortAndLong, help: "The output machine, arrangement or document, or the directory of a kernel target.")
    var output = "fsm.out"

    /// Turn on verbose output.
    ///
    /// This option enables verbose output, which provides additional information
    /// about the conversion process.
    @Flag(name: .shortAndLong, help: "Turn on verbose output.")
    var verbose = false

    /// Turn on debug output.
    ///
    /// This option enables debug output, which provides detailed debugging
    /// information about the conversion process.
    @Flag(name: .long, help: "Turn on debug output.")
    var debug = false

    /// Suppress progress and warnings.
    ///
    /// Errors and validation diagnostics are still reported.
    @Flag(name: [.customShort(OptionName.quietShort), .customLong(OptionName.quiet)],
          help: "Show neither progress nor warnings.")
    var quiet = false

    /// Use metamodel-backed conversion at the selected level.
    ///
    /// This option selects the level of `xmi` and `json` output, and makes the
    /// language names `c`, `cpp`, `swift` and `java` stand for the kernel targets
    /// at the kernel level.
    @Option(
        name: .customLong(OptionName.metamodel),
        help: ArgumentHelp(
            "Use metamodel-backed conversion at the selected model level.",
            discussion: """
                The level of xmi and json output. At the \(LLFSMLevel.kernel.rawValue) level, \
                \(OutputTargetNames.kernelSynonyms) name the kernel targets of those languages. \
                '\(LLFSMLevel.deprecatedExecutableArgument)' is a deprecated name of \
                '\(LLFSMLevel.sectioned.rawValue)'.
                """))
    var metamodel: LLFSMLevel?

    /// The MTL template to apply after metamodel loading.
    ///
    /// This option selects one of the structural template transforms
    /// (`structural2machine`, `structural2scxml`, `structural2cmake`, or
    /// `structural2layout`), which run the bundled template sets, and
    /// requires `--metamodel structural`.
    @Option(name: .customLong(OptionName.transform), help: "Apply a bundled structural MTL template after metamodel loading.")
    var transform: String?

    /// The generator of native formats.
    @Option(
        name: .customLong(OptionName.generator),
        help: ArgumentHelp(
            "The generator of native formats: \(NativeGenerator.templates.rawValue) uses the "
                + "bundled templates, \(NativeGenerator.swift.rawValue) the Swift language bindings.",
            valueName: NativeGenerator.allCases.map(\.rawValue).joined(separator: "|")))
    var generator: NativeGenerator = .templates

    /// Validate only, without writing anything.
    @Flag(
        name: .customLong(OptionName.validate),
        help: "Transform the input to the kernel, validate it and print the diagnostics without writing anything.")
    var validatesOnly = false

    /// The validation profile.
    @Option(
        name: .customLong(OptionName.profile),
        help: ArgumentHelp(
            "The validation profile of --\(OptionName.validate) (default \(ValidationProfile.strict.rawValue)), "
                + "which kernel targets must also satisfy.",
            valueName: ValidationProfile.allCases.map(\.rawValue).joined(separator: "|")))
    var profile: ValidationProfile?

    /// The semantic options of the encoding into the kernel.
    @Option(
        name: .customLong(OptionName.semantics),
        help: ArgumentHelp(
            "A semantic option of the encoding into the kernel as \(SemanticsOption.family.usage) "
                + "(can be specified multiple times).",
            discussion: SemanticsOption.discussion,
            valueName: SemanticsOption.family.usage))
    var semantics: [String] = []

    /// When the verification targets run the action of a state.
    @Option(
        name: .customLong(OptionName.entry),
        help: ArgumentHelp(
            "When the verification targets run the action of a state: \(KernelEntryMode.ringlet.rawValue) "
                + "(the default) or \(KernelEntryMode.fused.rawValue).",
            valueName: KernelEntryMode.allCases.map(\.rawValue).joined(separator: "|")))
    var entry: KernelEntryMode?

    /// The bound of the round counter of the verification targets.
    @Option(
        name: .customLong(OptionName.maxRounds),
        help: ArgumentHelp("The bound of the round counter of the verification targets (default 0: no counter).", valueName: "N"))
    var maxRounds: Int?

    /// Whether the verification targets add sanity properties.
    @Flag(name: .customLong(OptionName.sanity), help: "Add sanity properties to the verification targets.")
    var sanity = false

    /// How the verification targets treat opaque nodes.
    @Option(
        name: .customLong(OptionName.opaque),
        help: ArgumentHelp(
            "How the verification targets treat opaque nodes: \(KernelOpaqueTreatment.reject.rawValue) "
                + "(the default) or \(KernelOpaqueTreatment.havoc.rawValue).",
            valueName: KernelOpaqueTreatment.allCases.map(\.rawValue).joined(separator: "|")))
    var opaque: KernelOpaqueTreatment?

    /// The template parameters.
    @OptionGroup var templateParameters: TemplateParameterOptions

    /// The directories searched for imported template modules.
    @OptionGroup var templatePaths: TemplatePathOptions

    /// How written XMI spells references into itself.
    @OptionGroup var referenceStyle: ReferenceStyleOptions

    /// How transformations and templates read unset features.
    @OptionGroup var unsetFeatures: UnsetFeatureOptions

    /// The input machines to read.
    ///
    /// This argument specifies the input machines to read. It can be a directory
    /// containing machine files or arrangements, or a list of machine files.
    @Argument(help: "The input machines, arrangements or model documents to read.", completion: .directory)
    var inputMachines: [String]

    /// Check the option values that the parser cannot check on its own.
    ///
    /// - Throws: `ValidationError` for a value that no option accepts.
    func validate() throws {
        if !format.isEmpty, OutputTarget.named(format, level: metamodel) == nil {
            throw ValidationError(
                "The format '\(format)' requires --\(OptionName.metamodel) \(LLFSMLevel.kernel.rawValue)")
        }
        if let maxRounds, maxRounds < 0 {
            throw ValidationError("--\(OptionName.maxRounds) must not be negative, but is \(maxRounds)")
        }
        _ = try semanticOptions()
        _ = try parameterTexts()
        do {
            _ = try templatePaths.directories()
        } catch {
            throw ValidationError(String(describing: error))
        }
    }

    /// Run the command.
    ///
    /// This method implements the main logic of the `fsmconvert` tool, reading
    /// input machines, creating an arrangement if specified, and writing the
    /// output in the specified format.
    ///
    /// - Note: Designed for use in automated build systems and scripting.
    mutating func run() async throws {
        if validatesOnly {
            try await runValidation()
            return
        }
        if transform != nil {
            guard metamodel == .structural else {
                throw ValidationError("`--\(OptionName.transform)` requires `--\(OptionName.metamodel) \(LLFSMLevel.structural.rawValue)`")
            }
            try await runStructuralTemplate()
            return
        }
        if usesNativePath {
            try await runNative()
            return
        }
        try await runPipeline()
    }

    /// Whether the conversion runs on the native machines alone, as without metamodels.
    ///
    /// Without `--metamodel`, every native format, and `xmi`, keeps the meaning it
    /// has always had for native inputs; model documents and the other targets
    /// need the metamodels.
    var usesNativePath: Bool {
        guard metamodel == nil,
              !inputMachines.contains(where: { FSMPipeline.isModelDocument(URL(fileURLWithPath: $0)) })
        else { return false }
        guard !format.isEmpty, format != OutputTarget.xmi.rawValue else { return true }
        return OutputTarget.named(format, level: nil)?.isNative == true
    }

    /// Normalise the value of `--format`.
    ///
    /// - Parameter value: The value as given.
    /// - Returns: The value in lower case, or the empty string.
    /// - Throws: `ValidationError` if no target or synonym has the name.
    static func formatName(from value: String) throws -> String {
        if value.isEmpty { return value }
        let name = value.lowercased()
        guard OutputTarget.names(level: .kernel).contains(name) else {
            throw ValidationError("Unknown format '\(value)'; use one of \(OutputTargetNames.all)")
        }
        return name
    }
}

/// The names of the options of `fsmconvert`.
enum OptionName {
    /// The long name of the format option.
    static let format = "format"
    /// The short name of the format option.
    static let formatShort: Character = "f"
    /// The long name of the quiet option.
    static let quiet = "quiet"
    /// The short name of the quiet option.
    static let quietShort: Character = "q"
    /// The long name of the option that selects the level.
    static let metamodel = "metamodel"
    /// The long name of the option that runs a structural template.
    static let transform = "transform"
    /// The long name of the option that selects the native generator.
    static let generator = "generator"
    /// The long name of the option that validates without writing.
    static let validate = "validate"
    /// The long name of the option that selects the validation profile.
    static let profile = "profile"
    /// The long name of the option that sets semantic options of the kernel encoding.
    static let semantics = "semantics"
    /// The long name of the option that selects when actions run in verification targets.
    static let entry = "entry"
    /// The long name of the option that bounds the rounds of verification targets.
    static let maxRounds = "max-rounds"
    /// The long name of the option that adds sanity properties.
    static let sanity = "sanity"
    /// The long name of the option that selects how opaque nodes are treated.
    static let opaque = "opaque"
}

/// The names of the output targets, as lists for the help.
enum OutputTargetNames {
    /// The separator of the names in a list.
    static let separator = ", "

    /// The names of the native formats.
    static var native: String { names { $0.isNative } }

    /// The names of the model documents.
    static var models: String { names { $0.modelFormat != nil } }

    /// The names of the kernel targets.
    static var kernel: String { names { $0.kernelTarget != nil } }

    /// The language names that stand for kernel targets at the kernel level.
    static var kernelSynonyms: String {
        OutputTarget.kernelLanguageSynonyms.keys.sorted().joined(separator: separator)
    }

    /// The names that `--format` accepts.
    static var all: String { OutputTarget.names(level: .kernel).joined(separator: separator) }

    /// The names of the targets that satisfy a condition.
    ///
    /// - Parameter isIncluded: The condition.
    /// - Returns: The names separated by commas.
    private static func names(where isIncluded: (OutputTarget) -> Bool) -> String {
        OutputTarget.allCases.filter(isIncluded).map(\.rawValue).joined(separator: separator)
    }
}

/// The semantic options of the kernel encoding as a family of `name=value` options.
enum SemanticsOption {
    /// The family of `--semantics` values, checked against ``SectionedToKernelOptions``.
    static let family = KeyValueOption<String>(
        noun: "semantic option",
        keyPlaceholder: "option",
        allowedKeys: SectionedToKernelOptions.Key.allCases.map(\.rawValue)
    ) { key, text in
        guard let option = SectionedToKernelOptions.Key(rawValue: key) else { return text }
        var options = SectionedToKernelOptions()
        try options.set(option, to: text)
        return text
    }

    /// The options and their values, the default first, for the help.
    static var discussion: String {
        SectionedToKernelOptions.Key.allCases.map {
            $0.rawValue + String(KeyValueOptionSyntax.separator) + $0.values.joined(separator: "|")
        }.joined(separator: OutputTargetNames.separator)
    }
}

/// Command-line parsing of the metamodel level.
extension LLFSMLevel: ExpressibleByArgument {
    /// The deprecated command-line spelling that now maps to ``sectioned``.
    static let deprecatedExecutableArgument = "executable"

    /// Parse a metamodel level from a command-line argument.
    ///
    /// The deprecated value `executable` is accepted for compatibility and
    /// mapped to ``sectioned`` after printing a deprecation warning to the
    /// standard error stream.
    ///
    /// - Parameter argument: The command-line value to parse.
    public init?(argument: String) {
        let value = argument.lowercased()
        if value == Self.deprecatedExecutableArgument {
            FileHandle.standardError.write(Data(
                "warning: '--\(OptionName.metamodel) \(Self.deprecatedExecutableArgument)' is deprecated; use '--\(OptionName.metamodel) \(Self.sectioned.rawValue)' instead\n".utf8
            ))
            self = .sectioned
            return
        }
        guard let level = LLFSMLevel(rawValue: value) else { return nil }
        self = level
    }
}

/// Command-line parsing of the native generator, by its raw value.
extension NativeGenerator: ExpressibleByArgument {}

/// Command-line parsing of the validation profile, by its raw value.
extension ValidationProfile: ExpressibleByArgument {}

/// Command-line parsing of the kernel entry mode, by its raw value.
extension KernelEntryMode: ExpressibleByArgument {}

/// Command-line parsing of the treatment of opaque sections, by its raw value.
extension KernelOpaqueTreatment: ExpressibleByArgument {}
