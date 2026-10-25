//
//  SectionedToKernelOptionsTests.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import EMFBase
import Foundation
import Testing
@testable import FSMEcore

/// Tests the options of the sectioned to kernel transformation.
///
/// The tests cover the defaults, the option names and values, the
/// key-value form, error reporting, coding and the transformation parameters.
@Suite("Sectioned to kernel options")
struct SectionedToKernelOptionsTests {
    /// Checks that the defaults are the traditional execution order.
    @Test("the defaults are the traditional execution order")
    func defaults() {
        let options = SectionedToKernelOptions()
        #expect(options.selfLoop == .traditional)
        #expect(options.elideEmptySections)
        #expect(options.suspension == .encode)
        #expect(options.resumeFallback == .initial)
        #expect(options.time == .external)
        #expect(options.inState == .expand)
        #expect(options.keyValues == [
            "selfLoop=traditional", "elideEmptySections=true", "suspension=encode",
            "resumeFallback=initial", "time=external", "inState=expand",
        ])
    }

    /// Checks that the option names and values are those of the sectioned semantics.
    @Test("the option names and values are those of the sectioned semantics")
    func names() {
        #expect(SectionedToKernelOptions.Key.allCases.map(\.rawValue)
                == ["selfLoop", "elideEmptySections", "suspension", "resumeFallback", "time", "inState"])
        #expect(SectionedToKernelOptions.Key.selfLoop.values == ["traditional", "reentry"])
        #expect(SectionedToKernelOptions.Key.elideEmptySections.values == ["true", "false"])
        #expect(SectionedToKernelOptions.Key.suspension.values == ["encode", "omit"])
        #expect(SectionedToKernelOptions.Key.resumeFallback.values == ["initial", "previous"])
        #expect(SectionedToKernelOptions.Key.time.values == ["external", "clock"])
        #expect(SectionedToKernelOptions.Key.inState.values == ["expand", "exact"])
    }

    /// Checks that key-value pairs set the named options and keep the others.
    ///
    /// - Throws: Any error raised by the transformations.
    @Test("key-value pairs set the named options and keep the others")
    func keyValues() throws {
        let options = try SectionedToKernelOptions(keyValues: [
            "selfLoop=reentry", " elideEmptySections = false", "suspension=omit",
            "resumeFallback=previous", "time=clock", "inState=exact",
        ])
        let expected = SectionedToKernelOptions(
            selfLoop: .reentry,
            elideEmptySections: false,
            suspension: .omit,
            resumeFallback: .previous,
            time: .clock,
            inState: .exact)
        #expect(options == expected)
        #expect(try SectionedToKernelOptions(keyValues: options.keyValues) == options)
        #expect(try SectionedToKernelOptions(keyValues: ["time=clock"]) == SectionedToKernelOptions(time: .clock))
        #expect(try SectionedToKernelOptions(keyValues: [String]()) == SectionedToKernelOptions())
    }

    /// Checks that malformed, unknown, repeated and invalid pairs are rejected.
    @Test("malformed, unknown, repeated and invalid pairs are rejected")
    func invalidPairs() {
        #expect(throws: SectionedToKernelOptionsError.malformedPair("selfLoop")) {
            try SectionedToKernelOptions(keyValues: ["selfLoop"])
        }
        #expect(throws: SectionedToKernelOptionsError.unknownOption("loop")) {
            try SectionedToKernelOptions(keyValues: ["loop=reentry"])
        }
        #expect(throws: SectionedToKernelOptionsError.duplicateOption("time")) {
            try SectionedToKernelOptions(keyValues: ["time=clock", "time=external"])
        }
        #expect(throws: SectionedToKernelOptionsError.invalidValue(option: "elideEmptySections", value: "yes")) {
            try SectionedToKernelOptions(keyValues: ["elideEmptySections=yes"])
        }
        for key in SectionedToKernelOptions.Key.allCases {
            #expect(throws: SectionedToKernelOptionsError.invalidValue(option: key.rawValue, value: "")) {
                try SectionedToKernelOptions(keyValues: ["\(key.rawValue)="])
            }
        }
    }

    /// Checks that errors describe the accepted names and values.
    @Test("errors describe the accepted names and values")
    func errorDescriptions() {
        #expect(SectionedToKernelOptionsError.invalidValue(option: "time", value: "now").description
                == "The option 'time' does not accept 'now'; its values are external, clock")
        #expect(SectionedToKernelOptionsError.unknownOption("loop").description.contains("selfLoop, elideEmptySections"))
        #expect(SectionedToKernelOptionsError.malformedPair("x").description.contains("option=value"))
        #expect(SectionedToKernelOptionsError.duplicateOption("time").description.contains("more than once"))
    }

    /// Checks that options encode and decode, and that missing keys take their defaults.
    ///
    /// - Throws: Any error raised by the transformations.
    @Test("options encode and decode, and missing keys take their defaults")
    func coding() throws {
        let options = SectionedToKernelOptions(selfLoop: .reentry, time: .clock)
        let data = try JSONEncoder().encode(options)
        #expect(try JSONDecoder().decode(SectionedToKernelOptions.self, from: data) == options)
        let partial = Data(#"{"inState":"exact"}"#.utf8)
        #expect(try JSONDecoder().decode(SectionedToKernelOptions.self, from: partial)
                == SectionedToKernelOptions(inState: .exact))
    }

    /// Checks that the transformation parameters carry every option, with Booleans as Booleans.
    @Test("the transformation parameters carry every option, Booleans as Booleans")
    func parameters() {
        let parameters = SectionedToKernelOptions(elideEmptySections: false).parameters
        #expect(Set(parameters.keys) == Set(SectionedToKernelOptions.Key.allCases.map(\.rawValue)))
        #expect(parameters["elideEmptySections"] as? Bool == false)
        #expect(parameters["selfLoop"] as? String == "traditional")
    }
}
