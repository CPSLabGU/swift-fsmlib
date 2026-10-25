//
//  KernelFixtures.swift
//  FSMEcoreTests
//
//  Created by Rene Hexel on 23/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation
@testable import FSMEcore

/// The checked-in kernel and sectioned model fixtures and how they are built.
///
/// Each fixture is produced by ``KernelModelBuilder``; the XMI documents
/// under `Resources/Kernel/models` and `Resources/Sectioned/models` are the
/// serialisations of these builders.
enum KernelFixture: String, CaseIterable, Sendable {
    /// Two instances of one machine that pass a turn back and forth.
    case turnTakingRelay = "TurnTakingRelay"
    /// A crossing controller with a timed amber phase and recorded origins.
    case crossingController = "CrossingController"
    /// A door-and-motor interlock driven by an external sensor.
    case doorInterlock = "DoorInterlock"
    /// A worker pool whose members are gated by a scheduler instance.
    case schedulerPool = "SchedulerPool"
    /// A sampler that uses opaque host-language nodes (relaxed profile only).
    case opaqueSampler = "OpaqueSampler"
    /// A sectioned sampler that a supervisor suspends and resumes.
    case suspendResumeSampler = "SuspendResumeSampler"
    /// A sectioned crossing controller with a timed amber phase.
    case sectionedCrossing = "SectionedCrossing"

    /// Whether the fixture is a sectioned model.
    var isSectioned: Bool {
        self == .suspendResumeSampler || self == .sectionedCrossing
    }

    /// Whether the fixture satisfies the strict profile.
    var isStrict: Bool { self != .opaqueSampler }

    /// The resource subdirectory that holds the fixture.
    var subdirectory: String {
        isSectioned ? "Resources/Sectioned/models" : "Resources/Kernel/models"
    }

    /// The file extension of fixture documents.
    static let fileExtension = "xmi"

    /// The options with which fixtures are written.
    static let serialisationOptions = XMISerializationOptions.emf

    /// The environment variable that asks the fixture tests to rewrite the documents.
    static let regenerationVariable = "FSMECORE_REGENERATE_FIXTURES"

    /// The bundled URL of the fixture document, if it has been checked in.
    var bundledURL: URL? {
        TestResources.url(forResource: rawValue, withExtension: Self.fileExtension, subdirectory: subdirectory)
    }

    /// The location of the fixture document in the source tree.
    func sourceURL(testFile: String = #filePath) -> URL {
        URL(fileURLWithPath: testFile)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(subdirectory)
            .appendingPathComponent(rawValue)
            .appendingPathExtension(Self.fileExtension)
    }

    /// Build the fixture.
    func build(with builder: KernelModelBuilder) {
        switch self {
        case .turnTakingRelay: Self.buildTurnTakingRelay(builder)
        case .crossingController: Self.buildCrossingController(builder)
        case .doorInterlock: Self.buildDoorInterlock(builder)
        case .schedulerPool: Self.buildSchedulerPool(builder)
        case .opaqueSampler: Self.buildOpaqueSampler(builder)
        case .suspendResumeSampler: Self.buildSuspendResumeSampler(builder)
        case .sectionedCrossing: Self.buildSectionedCrossing(builder)
        }
    }

    // MARK: - Kernel Fixtures

    private static func buildTurnTakingRelay(_ b: KernelModelBuilder) {
        let system = b.arrangement("TurnTakingRelay")
        let side = b.enumerationType("Side", ["left", "right"], in: system)
        let count = b.integerType("Count", 0...9, in: system)
        let turn = b.variable("turn", side, in: system, initialValue: b.literal("left", of: side))
        let relay = b.machine("Relay", in: system)
        let me = b.variable("me", side, in: relay)
        let passes = b.variable("passes", count, in: relay)
        let waiting = b.state("Waiting", in: relay)
        let holding = b.state("Holding", in: relay)
        let passing = b.state("Passing", in: relay, passThrough: true)
        b.initial(waiting, of: relay)
        b.transition(from: waiting, to: holding, when: b.binary(.equal, b.ref(turn), b.ref(me)))
        b.action(holding, b.printLine("holding", [b.ref(me), b.ref(passes)]))
        b.transition(from: holding, to: passing, when: b.binary(.lessThan, b.ref(passes), b.int(9)))
        let other = b.conditional(
            b.binary(.equal, b.ref(me), b.literal("left", of: side)),
            b.literal("right", of: side),
            b.literal("left", of: side)
        )
        b.action(passing,
                 b.assign(b.ref(turn), other),
                 b.assign(b.ref(passes), b.binary(.addition, b.ref(passes), b.int(1))))
        b.transition(from: passing, to: waiting, when: b.bool(true))
        let leftHand = b.instance("leftHand", of: relay, in: system)
        b.binding(me, to: b.literal("left", of: side), for: leftHand)
        let rightHand = b.instance("rightHand", of: relay, in: system)
        b.binding(me, to: b.literal("right", of: side), for: rightHand)
    }

    private static func buildCrossingController(_ b: KernelModelBuilder) {
        let system = b.arrangement("CrossingController")
        let flag = b.booleanType(in: system)
        let time = b.integerType("Time", 0...10_000, in: system)
        let now = b.variable("now", time, in: system, external: true)
        let request = b.variable("request", flag, in: system, external: true)
        let crossing = b.machine("Crossing", in: system)
        let enteredAt = b.variable("enteredAt", time, in: crossing)
        let go = b.state("Go", in: crossing)
        let goExit = b.state("Go_x0", in: crossing, passThrough: true)
        let amber = b.state("Amber", in: crossing)
        let stop = b.state("Stop", in: crossing)
        b.initial(go, of: crossing)
        b.action(go, b.assign(b.ref(enteredAt), b.ref(now)), b.printLine("go"))
        let leave = b.transition(from: go, to: goExit, when: b.ref(request))
        b.action(goExit, b.printLine("clearing"))
        let toAmber = b.transition(from: goExit, to: amber, when: b.bool(true))
        b.action(amber, b.assign(b.ref(enteredAt), b.ref(now)), b.printLine("amber"))
        let elapsed = { b.binary(.subtraction, b.ref(now), b.ref(enteredAt)) }
        b.transition(from: amber, to: stop, when: b.binary(.greaterOrEqual, elapsed(), b.int(3)))
        b.action(stop, b.assign(b.ref(enteredAt), b.ref(now)), b.printLine("stop"))
        b.transition(from: stop, to: go, when: b.binary(.greaterOrEqual, elapsed(), b.int(5)))
        b.instance("main", of: crossing, in: system)
        b.origin(OriginRecord(state: "Go", role: .entry), on: go)
        b.origin(OriginRecord(state: "Go", role: .exit, transition: 0), on: goExit)
        b.origin(OriginRecord(state: "Go", role: .exit, transition: 0), on: leave)
        b.origin(OriginRecord(state: "Go", role: .exit, transition: 0), on: toAmber)
        b.origin(OriginRecord(state: "Amber", role: .entry), on: amber)
        b.origin(OriginRecord(state: "Stop", role: .entry), on: stop)
    }

    private static func buildDoorInterlock(_ b: KernelModelBuilder) {
        let system = b.arrangement("DoorInterlock")
        let flag = b.booleanType(in: system)
        let code = b.integerType("Code", 0...15, in: system)
        let doorClosed = b.variable("doorClosed", flag, in: system, external: true)
        let motorOn = b.variable("motorOn", flag, in: system, initialValue: b.bool(false))
        let isSafe = b.function("isSafe", in: system, pure: true, parameters: [("closed", flag)], result: flag)
        let logEvent = b.function("logEvent", in: system, parameters: [("event", code)])
        let interlock = b.machine("Interlock", in: system)
        let idle = b.state("Idle", in: interlock)
        let running = b.state("Running", in: interlock)
        let halting = b.state("Halting", in: interlock, passThrough: true)
        b.initial(idle, of: interlock)
        b.transition(from: idle, to: running, when: b.call(isSafe, [b.ref(doorClosed)]))
        b.action(running, b.assign(b.ref(motorOn), b.bool(true)), b.perform(b.call(logEvent, [b.int(1)])))
        b.transition(from: running, to: halting, when: b.unary(.negation, b.ref(doorClosed)))
        b.action(halting, b.assign(b.ref(motorOn), b.bool(false)), b.perform(b.call(logEvent, [b.int(2)])))
        b.transition(from: halting, to: idle, when: b.bool(true))
        let lock = b.instance("lock", of: interlock, in: system)
        let monitor = b.machine("Monitor", in: system)
        let quiet = b.state("Quiet", in: monitor)
        let alarm = b.state("Alarm", in: monitor)
        b.initial(quiet, of: monitor)
        let unsafe = b.binary(.conjunction, b.inState(lock, running), b.unary(.negation, b.ref(doorClosed)))
        b.transition(from: quiet, to: alarm, when: unsafe)
        b.action(alarm, b.printLine("alarm", [b.ref(motorOn)]))
        b.transition(from: alarm, to: quiet, when: b.inState(lock, idle))
        b.instance("watch", of: monitor, in: system)
    }

    private static func buildSchedulerPool(_ b: KernelModelBuilder) {
        let system = b.arrangement("SchedulerPool")
        let flag = b.booleanType(in: system)
        let slot = b.integerType("Slot", 0...2, in: system)
        let flags = b.arrayType("Flags", of: flag, size: 3, in: system)
        let current = b.variable("current", slot, in: system)
        let done = b.variable("done", flags, in: system)
        let scheduler = b.machine("Scheduler", in: system)
        let dispatch = b.state("Dispatch", in: scheduler)
        let advance = b.state("Advance", in: scheduler, passThrough: true)
        b.initial(dispatch, of: scheduler)
        b.transition(from: dispatch, to: advance, when: b.ref(done, index: b.ref(current)))
        let next = b.binary(.modulo, b.binary(.addition, b.ref(current), b.int(1)), b.int(3))
        b.action(advance, b.assign(b.ref(current), next))
        b.transition(from: advance, to: dispatch, when: b.bool(true))
        let gate = b.instance("gate", of: scheduler, in: system)
        let worker = b.machine("Worker", in: system)
        let id = b.variable("id", slot, in: worker)
        let ready = b.state("Ready", in: worker)
        let working = b.state("Working", in: worker)
        b.initial(ready, of: worker)
        let myTurn = b.binary(.conjunction, b.inState(gate, dispatch), b.binary(.equal, b.ref(current), b.ref(id)))
        b.transition(from: ready, to: working, when: myTurn)
        b.action(working, b.assign(b.ref(done, index: b.ref(id)), b.bool(true)), b.printLine("work", [b.ref(id)]))
        b.transition(from: working, to: ready,
                     when: b.binary(.notEqual, b.ref(current), b.ref(id)))
        b.action(ready, b.assign(b.ref(done, index: b.ref(id)), b.bool(false)))
        for (name, value) in [("first", 0), ("second", 1), ("third", 2)] {
            let member = b.instance(name, of: worker, in: system)
            b.binding(id, to: b.int(value), for: member)
        }
    }

    private static func buildOpaqueSampler(_ b: KernelModelBuilder) {
        let system = b.arrangement("OpaqueSampler")
        b.set(system, .language, "c")
        let flag = b.booleanType(in: system)
        let reading = b.opaqueType("Reading", text: "struct reading", in: system)
        b.hostDeclarations(in: system, language: "c", includes: "#include <stdio.h>",
                           declarations: opaqueSamplerDeclarations)
        let latest = b.variable("latest", reading, in: system)
        let sampler = b.machine("Sampler", in: system)
        let wait = b.state("Wait", in: sampler)
        let sample = b.state("Sample", in: sampler)
        b.initial(wait, of: sampler)
        b.transition(from: wait, to: sample, when: b.opaqueExpression("sensor_ready()", type: flag))
        b.action(sample, b.opaqueStatement("read_sensor(&latest);"), b.printLine("sample", [b.ref(latest)]))
        b.transition(from: sample, to: wait, when: b.bool(true))
        b.instance("probe", of: sampler, in: system)
    }

    /// The C declarations that give OpaqueSampler a deterministic sensor.
    ///
    /// Every call of `sensor_ready()` counts one poll and holds on every
    /// second poll; `read_sensor` stores ten times the number of polls, and
    /// `print_Reading` is the printer of the opaque type `Reading`.
    private static let opaqueSamplerDeclarations = """
        struct reading {
            int value;
        };

        int sensor_polls = 0;

        bool sensor_ready(void)
        {
            sensor_polls++;
            return sensor_polls % 2 == 0;
        }

        void read_sensor(struct reading *out)
        {
            out->value = 10 * sensor_polls;
        }

        void print_Reading(struct reading value)
        {
            printf("%d", value.value);
        }
        """

    // MARK: - Sectioned Fixtures

    private static func buildSuspendResumeSampler(_ b: KernelModelBuilder) {
        let system = b.sectionedArrangement("SuspendResumeSampler")
        let flag = b.booleanType(in: system)
        let count = b.integerType("Count", 0...100, in: system)
        let paused = b.variable("pauseRequested", flag, in: system, external: true)
        let samples = b.variable("samples", count, in: system)
        let sampler = b.sectionedMachine("Sampler", in: system)
        let idle = b.sectionedState("Idle", in: sampler)
        let sampling = b.sectionedState("Sampling", in: sampler)
        let suspended = b.sectionedState("Suspended", in: sampler)
        b.set(sampler, .initial, idle)
        b.set(sampler, .suspendState, suspended)
        b.section(.onEntry, of: idle, b.printLine("idle"))
        b.sectionedTransition(from: idle, to: sampling,
                              when: b.binary(.greaterThan, b.stateTime(.milliseconds), b.int(100)))
        b.section(.onEntry, of: sampling, b.assign(b.ref(samples), b.binary(.addition, b.ref(samples), b.int(1))))
        b.section(.internal, of: sampling, b.printLine("sampling", [b.ref(samples)]))
        b.section(.onExit, of: sampling, b.printLine("done"))
        b.section(.onSuspend, of: sampling, b.printLine("suspending"))
        b.section(.onResume, of: sampling, b.printLine("resuming"))
        b.sectionedTransition(from: sampling, to: idle,
                              when: b.binary(.greaterOrEqual, b.ref(samples), b.int(100)))
        b.section(.onEntry, of: suspended, b.printLine("suspended"))
        b.section(.onResume, of: suspended, b.printLine("leaving suspension"))
        let worker = b.sectionedInstance("worker", of: sampler, in: system)
        let supervisor = b.sectionedMachine("Supervisor", in: system)
        let watching = b.sectionedState("Watching", in: supervisor)
        let holding = b.sectionedState("Holding", in: supervisor)
        b.set(supervisor, .initial, watching)
        b.sectionedTransition(from: watching, to: holding, when: b.ref(paused))
        b.section(.onEntry, of: holding, b.control(.suspend, worker))
        b.section(.onExit, of: holding, b.control(.resume, worker))
        let resumeWhen = b.binary(.conjunction, b.unary(.negation, b.ref(paused)),
                                  b.sectionedInState(worker, suspended))
        b.sectionedTransition(from: holding, to: watching, when: resumeWhen)
        b.sectionedInstance("supervisor", of: supervisor, in: system)
    }

    private static func buildSectionedCrossing(_ b: KernelModelBuilder) {
        let system = b.sectionedArrangement("SectionedCrossing")
        let flag = b.booleanType(in: system)
        let request = b.variable("request", flag, in: system, external: true)
        let crossing = b.sectionedMachine("Crossing", in: system)
        let lit = b.variable("walkLit", flag, in: crossing)
        let go = b.sectionedState("Go", in: crossing)
        let amber = b.sectionedState("Amber", in: crossing)
        let stop = b.sectionedState("Stop", in: crossing)
        b.set(crossing, .initial, go)
        b.section(.onEntry, of: go, b.assign(b.ref(lit), b.bool(false)), b.printLine("go"))
        b.section(.onExit, of: go, b.printLine("clearing"))
        b.sectionedTransition(from: go, to: amber, when: b.ref(request))
        b.section(.onEntry, of: amber, b.printLine("amber"))
        b.sectionedTransition(from: amber, to: stop,
                              when: b.binary(.greaterOrEqual, b.stateTime(.seconds), b.int(3)))
        b.section(.onEntry, of: stop, b.assign(b.ref(lit), b.bool(true)), b.printLine("stop"))
        b.section(.internal, of: stop, b.printLine("walking", [b.ref(lit)]))
        b.sectionedTransition(from: stop, to: go,
                              when: b.binary(.greaterOrEqual, b.stateTime(.seconds), b.int(5)))
        b.sectionedInstance("main", of: crossing, in: system)
    }
}

extension KernelModelBuilder {
    /// Record an origin on a kernel state or transition.
    func origin(_ record: OriginRecord, on owner: EUUID) {
        var values: [(LLFSMFeature, any EcoreValue)] = [(.role, record.role.rawValue)]
        if let state = record.state { values.append((.state, state)) }
        if let transition = record.transition { values.append((.transition, transition)) }
        set(owner, .origin, make(kernel.originClass, values))
    }
}
