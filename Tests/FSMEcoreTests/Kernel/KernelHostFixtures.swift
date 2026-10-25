//
//  KernelHostFixtures.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
@testable import FSMEcore

/// The relaxed HostTally models, one for each code target language.
///
/// Every model has the same machine and the same canonical trace; only the
/// host-language text differs. Each exercises opaque statements, an opaque
/// label, an opaque type with an opaque initial value, a pure function in a
/// label, a function called for its effect and two methods of the opaque
/// type, one of them printed, all supplied through host declarations.
enum KernelHostFixture: String, CaseIterable, Sendable {
    /// The C model.
    case c
    /// The C++ model.
    case cpp
    /// The Swift model.
    case swift
    /// The Java model.
    case java

    /// The name of the arrangement and of the fixture document.
    static let arrangementName = "HostTally"

    /// The language identifier that the model declares.
    var language: String { rawValue }

    /// The resource subdirectory that holds the fixture.
    var subdirectory: String { "Resources/Kernel/models/" + rawValue }

    /// The bundled URL of the fixture document, if it has been checked in.
    var bundledURL: URL? {
        TestResources.url(
            forResource: Self.arrangementName,
            withExtension: KernelFixture.fileExtension,
            subdirectory: subdirectory
        )
    }

    /// The location of the fixture document in the source tree.
    func sourceURL(testFile: String = #filePath) -> URL {
        URL(fileURLWithPath: testFile)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(subdirectory)
            .appendingPathComponent(Self.arrangementName)
            .appendingPathExtension(KernelFixture.fileExtension)
    }

    /// The host-language text of one model.
    struct HostText {
        /// The include or import directives.
        let includes: String
        /// The type definitions and functions that implement the host side.
        let declarations: String
        /// The host type behind the opaque type `Tally`.
        let tallyType: String
        /// The expression that creates the initial tally.
        let tallyInitialValue: String
        /// The statement that prints `start`.
        let startStatement: String
        /// The statement that prints `done`.
        let doneStatement: String
    }

    /// The opaque label that ends the count, valid in every language.
    static let fullLabel = "tally.sum() >= 6"

    /// The host-language text of this model.
    var text: HostText {
        switch self {
        case .c:
            return HostText(
                includes: "#include <stdio.h>",
                declarations: """
                    struct tally {
                        void (*bump)(Count by);
                        Count (*sum)(void);
                    };

                    Count tally_total = 0;

                    void tally_bump(Count by)
                    {
                        tally_total += by;
                    }

                    Count tally_sum(void)
                    {
                        return tally_total;
                    }

                    Flag isEven(Count n)
                    {
                        return n % 2 == 0;
                    }

                    void note(Count n)
                    {
                        printf("note %d\\n", n);
                    }
                    """,
                tallyType: "struct tally",
                tallyInitialValue: "(struct tally){ tally_bump, tally_sum }",
                startStatement: "printf(\"start\\n\");",
                doneStatement: "printf(\"done\\n\");")
        case .cpp:
            return HostText(
                includes: "#include <iostream>",
                declarations: """
                    class TallyCounter {
                    public:
                        void bump(Count by)
                        {
                            total += by;
                        }

                        Count sum() const
                        {
                            return total;
                        }

                    private:
                        Count total = 0;
                    };

                    Flag isEven(Count n)
                    {
                        return n % 2 == 0;
                    }

                    void note(Count n)
                    {
                        std::cout << "note " << n << '\\n';
                    }
                    """,
                tallyType: "TallyCounter",
                tallyInitialValue: "TallyCounter{}",
                startStatement: "std::cout << \"start\\n\";",
                doneStatement: "std::cout << \"done\\n\";")
        case .swift:
            return HostText(
                includes: "",
                declarations: """
                    final class TallyCounter {
                        private var total: Count = 0

                        func bump(_ by: Count) {
                            total += by
                        }

                        func sum() -> Count {
                            total
                        }
                    }

                    func isEven(_ n: Count) -> Flag {
                        n % 2 == 0
                    }

                    func note(_ n: Count) {
                        print("note \\(n)")
                    }
                    """,
                tallyType: "TallyCounter",
                tallyInitialValue: "TallyCounter()",
                startStatement: "print(\"start\")",
                doneStatement: "print(\"done\")")
        case .java:
            return HostText(
                includes: "",
                declarations: """
                    final class TallyCounter {
                        private int total;

                        void bump(int by) {
                            total += by;
                        }

                        int sum() {
                            return total;
                        }
                    }

                    final class HostTallyHost {
                        private HostTallyHost() {
                        }

                        static boolean isEven(int n) {
                            return n % 2 == 0;
                        }

                        static void note(int n) {
                            System.out.print("note " + n + "\\n");
                        }
                    }
                    """,
                tallyType: "TallyCounter",
                tallyInitialValue: "new TallyCounter()",
                startStatement: "System.out.print(\"start\\n\");",
                doneStatement: "System.out.print(\"done\\n\");")
        }
    }

    /// Build the fixture.
    func build(with b: KernelModelBuilder) {
        let text = self.text
        let system = b.arrangement(Self.arrangementName)
        b.set(system, .language, language)
        let flag = b.booleanType("Flag", in: system)
        let count = b.integerType("Count", 0...9, in: system)
        let tallyType = b.opaqueType("Tally", text: text.tallyType, in: system)
        b.hostDeclarations(
            in: system,
            language: language,
            includes: text.includes,
            declarations: text.declarations
        )
        let tallyStart = b.opaqueExpression(text.tallyInitialValue, type: tallyType)
        let tally = b.variable("tally", tallyType, in: system, initialValue: tallyStart)
        let isEven = b.function("isEven", in: system, pure: true, parameters: [("n", count)], result: flag)
        let note = b.function("note", in: system, parameters: [("n", count)])
        let bump = b.function("bump", in: system, parameters: [("by", count)], receiverType: tallyType)
        let sum = b.function("sum", in: system, pure: true, result: count, receiverType: tallyType)
        let counter = b.machine("Counter", in: system)
        let n = b.variable("n", count, in: counter)
        let start = b.state("Start", in: counter)
        let work = b.state("Work", in: counter)
        let pause = b.state("Pause", in: counter, passThrough: true)
        let done = b.state("Done", in: counter)
        b.initial(start, of: counter)
        b.action(start, b.opaqueStatement(text.startStatement))
        b.transition(from: start, to: work, when: b.bool(true))
        b.action(work,
                 b.perform(b.call(bump, [b.ref(n)], receiver: b.ref(tally))),
                 b.perform(b.call(note, [b.ref(n)])),
                 b.assign(b.ref(n), b.binary(.addition, b.ref(n), b.int(1))),
                 b.printLine("sum", [b.call(sum, receiver: b.ref(tally))]))
        b.transition(from: work, to: done, when: b.opaqueExpression(Self.fullLabel, type: flag))
        b.transition(from: work, to: pause, when: b.call(isEven, [b.ref(n)]))
        b.transition(from: work, to: work, when: b.bool(true))
        b.action(pause, b.printLine("pause", [b.ref(n)]))
        b.transition(from: pause, to: work, when: b.bool(true))
        b.action(done, b.opaqueStatement(text.doneStatement))
        b.instance("counter", of: counter, in: system)
    }
}
