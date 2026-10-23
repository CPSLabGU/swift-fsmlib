//
//  SectionedToKernelOptions.swift
//  FSMEcore
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation

/// The semantic options of the encoding of sectioned models into the kernel.
///
/// The defaults reproduce the traditional execution order of the reference
/// engines (see <doc:SectionedSemantics>). Each option has a name, which is
/// also the name of the parameter of the bundled transformation and of the
/// `key=value` pair accepted by ``init(keyValues:)``.
///
/// ```swift
/// let options = try SectionedToKernelOptions(keyValues: ["selfLoop=reentry", "time=clock"])
/// let result = try await transformations.sectionedToKernel(resource, options: options)
/// ```
public struct SectionedToKernelOptions: Codable, Sendable, Hashable {
    /// Whether a self transition re-enters its state.
    public enum SelfLoop: String, Codable, Sendable, CaseIterable {
        /// The state is not re-entered: the entry section does not run again
        /// and the state clock is not reset (the default).
        case traditional
        /// The state is re-entered: the entry section runs again and the
        /// state clock is reset.
        case reentry
    }

    /// Whether suspension is encoded.
    public enum Suspension: String, Codable, Sendable, CaseIterable {
        /// Suspend states, control statements and the suspend and resume
        /// sections are encoded (the default).
        case encode
        /// The suspend state designation, the control statements and the
        /// suspend and resume sections are dropped with a diagnostic.
        case omit
    }

    /// Where an instance resumes when no state was recorded.
    public enum ResumeFallback: String, Codable, Sendable, CaseIterable {
        /// The instance enters its initial state (the default).
        case initial
        /// The instance enters the most recently recorded state.
        case previous
    }

    /// The source of the clock read by state-time expressions.
    public enum Time: String, Codable, Sendable, CaseIterable {
        /// The environment supplies the current time (the default).
        case external
        /// A clock machine, placed first in the arrangement, advances the
        /// current time by one unit per round.
        case clock
    }

    /// How in-state observations map onto the kernel states.
    public enum InState: String, Codable, Sendable, CaseIterable {
        /// An observation holds in every kernel state that encodes the
        /// observed sectioned state (the default).
        case expand
        /// An observation holds only in the kernel state that runs the entry
        /// section of the observed sectioned state.
        case exact
    }

    /// The names of the options.
    ///
    /// The raw values are the option names used in `key=value` pairs and as
    /// parameters of the bundled transformation.
    public enum Key: String, Codable, CodingKey, Sendable, CaseIterable {
        /// The name of ``SectionedToKernelOptions/selfLoop``.
        case selfLoop
        /// The name of ``SectionedToKernelOptions/elideEmptySections``.
        case elideEmptySections
        /// The name of ``SectionedToKernelOptions/suspension``.
        case suspension
        /// The name of ``SectionedToKernelOptions/resumeFallback``.
        case resumeFallback
        /// The name of ``SectionedToKernelOptions/time``.
        case time
        /// The name of ``SectionedToKernelOptions/inState``.
        case inState

        /// The values the option accepts, the default first.
        public var values: [String] {
            switch self {
            case .selfLoop: return SelfLoop.allCases.map(\.rawValue)
            case .elideEmptySections: return [SectionedToKernelOptions.trueText, SectionedToKernelOptions.falseText]
            case .suspension: return Suspension.allCases.map(\.rawValue)
            case .resumeFallback: return ResumeFallback.allCases.map(\.rawValue)
            case .time: return Time.allCases.map(\.rawValue)
            case .inState: return InState.allCases.map(\.rawValue)
            }
        }
    }

    /// The separator between the name and the value of a `key=value` pair.
    public static let keyValueSeparator: Character = "="

    /// The text of the Boolean value `true`.
    public static let trueText = "true"

    /// The text of the Boolean value `false`.
    public static let falseText = "false"

    /// Whether a self transition re-enters its state (default ``SelfLoop/traditional``).
    public var selfLoop: SelfLoop

    /// Whether states with empty internal and exit sections are collapsed (default `true`).
    ///
    /// When on, a sectioned machine with only entry sections encodes to a
    /// kernel machine with the same number of states.
    public var elideEmptySections: Bool

    /// Whether suspension is encoded (default ``Suspension/encode``).
    public var suspension: Suspension

    /// Where an instance resumes when nothing was recorded (default ``ResumeFallback/initial``).
    public var resumeFallback: ResumeFallback

    /// The source of the clock (default ``Time/external``).
    public var time: Time

    /// How in-state observations are mapped (default ``InState/expand``).
    public var inState: InState

    /// Create options, by default those of the traditional execution order.
    ///
    /// - Parameters:
    ///   - selfLoop: Whether a self transition re-enters its state.
    ///   - elideEmptySections: Whether empty internal and exit sections are collapsed.
    ///   - suspension: Whether suspension is encoded.
    ///   - resumeFallback: Where an instance resumes when nothing was recorded.
    ///   - time: The source of the clock.
    ///   - inState: How in-state observations are mapped.
    public init(
        selfLoop: SelfLoop = .traditional,
        elideEmptySections: Bool = true,
        suspension: Suspension = .encode,
        resumeFallback: ResumeFallback = .initial,
        time: Time = .external,
        inState: InState = .expand
    ) {
        self.selfLoop = selfLoop
        self.elideEmptySections = elideEmptySections
        self.suspension = suspension
        self.resumeFallback = resumeFallback
        self.time = time
        self.inState = inState
    }

    /// Create options from `key=value` pairs.
    ///
    /// Options that are not named keep their defaults.
    ///
    /// - Parameter keyValues: Pairs such as `selfLoop=reentry`, one option each.
    /// - Throws: ``SectionedToKernelOptionsError`` if a pair is malformed,
    ///   names an unknown option, gives a value the option does not accept,
    ///   or names an option more than once.
    public init<Pairs: Sequence>(keyValues: Pairs) throws where Pairs.Element: StringProtocol {
        self.init()
        var seen = Set<Key>()
        for pair in keyValues {
            let text = String(pair)
            guard let separator = text.firstIndex(of: Self.keyValueSeparator) else {
                throw SectionedToKernelOptionsError.malformedPair(text)
            }
            let name = text[..<separator].trimmingCharacters(in: .whitespaces)
            let value = text[text.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            guard let key = Key(rawValue: name) else {
                throw SectionedToKernelOptionsError.unknownOption(name)
            }
            guard seen.insert(key).inserted else {
                throw SectionedToKernelOptionsError.duplicateOption(name)
            }
            try set(key, to: value)
        }
    }

    /// The options as `key=value` pairs, in the order of ``Key``.
    public var keyValues: [String] {
        Key.allCases.map { $0.rawValue + String(Self.keyValueSeparator) + value(of: $0) }
    }

    /// The text of the value of an option.
    ///
    /// - Parameter key: The option.
    /// - Returns: The value as it appears in a `key=value` pair.
    public func value(of key: Key) -> String {
        switch key {
        case .selfLoop: return selfLoop.rawValue
        case .elideEmptySections: return elideEmptySections ? Self.trueText : Self.falseText
        case .suspension: return suspension.rawValue
        case .resumeFallback: return resumeFallback.rawValue
        case .time: return time.rawValue
        case .inState: return inState.rawValue
        }
    }

    /// Set an option from the text of its value.
    ///
    /// - Parameters:
    ///   - key: The option to set.
    ///   - value: The text of the value.
    /// - Throws: ``SectionedToKernelOptionsError/invalidValue(option:value:)``
    ///   if the option does not accept the value.
    public mutating func set(_ key: Key, to value: String) throws {
        let invalid = SectionedToKernelOptionsError.invalidValue(option: key.rawValue, value: value)
        switch key {
        case .selfLoop:
            guard let parsed = SelfLoop(rawValue: value) else { throw invalid }
            selfLoop = parsed
        case .elideEmptySections:
            switch value {
            case Self.trueText: elideEmptySections = true
            case Self.falseText: elideEmptySections = false
            default: throw invalid
            }
        case .suspension:
            guard let parsed = Suspension(rawValue: value) else { throw invalid }
            suspension = parsed
        case .resumeFallback:
            guard let parsed = ResumeFallback(rawValue: value) else { throw invalid }
            resumeFallback = parsed
        case .time:
            guard let parsed = Time(rawValue: value) else { throw invalid }
            time = parsed
        case .inState:
            guard let parsed = InState(rawValue: value) else { throw invalid }
            inState = parsed
        }
    }

    /// Decode options, giving every option that the data leaves out its default.
    ///
    /// - Parameter decoder: The decoder to read from.
    /// - Throws: An error if a present option holds a value it does not accept.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let defaults = SectionedToKernelOptions()
        selfLoop = try container.decodeIfPresent(SelfLoop.self, forKey: .selfLoop) ?? defaults.selfLoop
        elideEmptySections = try container.decodeIfPresent(Bool.self, forKey: .elideEmptySections)
            ?? defaults.elideEmptySections
        suspension = try container.decodeIfPresent(Suspension.self, forKey: .suspension) ?? defaults.suspension
        resumeFallback = try container.decodeIfPresent(ResumeFallback.self, forKey: .resumeFallback)
            ?? defaults.resumeFallback
        time = try container.decodeIfPresent(Time.self, forKey: .time) ?? defaults.time
        inState = try container.decodeIfPresent(InState.self, forKey: .inState) ?? defaults.inState
    }

    /// Encode every option under its name.
    ///
    /// - Parameter encoder: The encoder to write to.
    /// - Throws: An error if the encoder fails.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(selfLoop, forKey: .selfLoop)
        try container.encode(elideEmptySections, forKey: .elideEmptySections)
        try container.encode(suspension, forKey: .suspension)
        try container.encode(resumeFallback, forKey: .resumeFallback)
        try container.encode(time, forKey: .time)
        try container.encode(inState, forKey: .inState)
    }

    /// The values of the transformation parameters, by option name.
    var parameters: [String: any EcoreValue] {
        var parameters: [String: any EcoreValue] = [:]
        for key in Key.allCases {
            switch key {
            case .elideEmptySections: parameters[key.rawValue] = elideEmptySections
            default: parameters[key.rawValue] = value(of: key)
            }
        }
        return parameters
    }
}

/// Errors raised while sectioned-to-kernel options are read from text.
public enum SectionedToKernelOptionsError: Error, Sendable, Equatable, CustomStringConvertible {
    /// A pair lacks the separator between name and value.
    case malformedPair(String)
    /// A pair names an option that does not exist.
    case unknownOption(String)
    /// A pair names an option that an earlier pair already set.
    case duplicateOption(String)
    /// An option does not accept a value.
    case invalidValue(option: String, value: String)

    /// A sentence that describes the error.
    public var description: String {
        switch self {
        case .malformedPair(let pair):
            return "'\(pair)' is not of the form option\(SectionedToKernelOptions.keyValueSeparator)value"
        case .unknownOption(let name):
            let names = SectionedToKernelOptions.Key.allCases.map(\.rawValue).joined(separator: ", ")
            return "Unknown option '\(name)'; the options are \(names)"
        case .duplicateOption(let name):
            return "The option '\(name)' is given more than once"
        case .invalidValue(let option, let value):
            let values = SectionedToKernelOptions.Key(rawValue: option)?.values.joined(separator: ", ") ?? ""
            return "The option '\(option)' does not accept '\(value)'; its values are \(values)"
        }
    }
}
