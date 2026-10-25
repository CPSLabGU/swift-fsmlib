import XCTest
@testable import FSM
@testable import FSMEcore
import ECore

enum FSMEcoreTestSupport {
    static func trafficLightMachineURL(file: StaticString = #filePath, line: UInt = #line) throws -> URL {
        guard let url = TestResources.url(
            forResource: "TrafficLight",
            withExtension: "machine",
            subdirectory: "Resources"
        ) else {
            XCTFail("Missing TrafficLight.machine resource", file: file, line: line)
            throw NSError(domain: "FSMEcoreTests", code: 1)
        }
        return url
    }

    static func loadTrafficLightMachine() throws -> Machine {
        try Machine(from: try trafficLightMachineURL())
    }

    static func makeTemporaryDirectory(prefix: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "\(prefix)-\(UUID().uuidString)",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.standardizedFileURL.resolvingSymlinksInPath()
    }

    static func findObject(
        named className: String,
        in resource: Resource
    ) async -> DynamicEObject? {
        let roots = await resource.getRootObjects().compactMap { $0 as? DynamicEObject }
        if let rootMatch = roots.first(where: { $0.eClass.name == className }) {
            return rootMatch
        }
        let objects = await resource.getAllObjects().compactMap { $0 as? DynamicEObject }
        return objects.first(where: { $0.eClass.name == className })
    }

    static func assertDirectoryContentsEqual(
        _ lhs: URL,
        _ rhs: URL,
        restrictedTo allowedRelativePaths: Set<String>? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let lhsContents = try directoryContents(at: lhs, restrictedTo: allowedRelativePaths)
        let rhsContents = try directoryContents(at: rhs, restrictedTo: allowedRelativePaths)
        XCTAssertEqual(lhsContents, rhsContents, file: file, line: line)
    }

    static func assertPropertyListsEqual(
        _ lhs: URL,
        _ rhs: URL,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let lhsData = try Data(contentsOf: lhs)
        let rhsData = try Data(contentsOf: rhs)
        let lhsList = try PropertyListSerialization.propertyList(from: lhsData, format: nil)
        let rhsList = try PropertyListSerialization.propertyList(from: rhsData, format: nil)

        XCTAssertEqual(
            String(describing: lhsList as AnyObject),
            String(describing: rhsList as AnyObject),
            file: file,
            line: line
        )
    }

    static func assertMachinesEqual(
        _ lhs: Machine,
        _ rhs: Machine,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs.language.name, rhs.language.name, file: file, line: line)
        XCTAssertEqual(lhs.windowLayout, rhs.windowLayout, file: file, line: line)
        assertLLFSMStructureEqual(lhs.llfsm, rhs.llfsm, file: file, line: line)

        let lhsBoilerplate = normalisedSections(lhs.language.extractSections(from: lhs.boilerplate))
        let rhsBoilerplate = normalisedSections(rhs.language.extractSections(from: rhs.boilerplate))
        XCTAssertEqual(lhsBoilerplate, rhsBoilerplate, file: file, line: line)

        XCTAssertEqual(lhs.stateLayout.count, rhs.stateLayout.count, file: file, line: line)
        for stateID in lhs.llfsm.states {
            guard let stateName = lhs.llfsm.stateName(for: stateID) else {
                XCTFail("Missing source state name", file: file, line: line)
                continue
            }
            guard let rhsStateID = rhs.llfsm.states.first(where: { rhs.llfsm.stateName(for: $0) == stateName }) else {
                XCTFail("Missing state '\(stateName)' in decoded machine", file: file, line: line)
                continue
            }
            assertStateLayoutsEqual(lhs.stateLayout[stateID], rhs.stateLayout[rhsStateID], file: file, line: line)
            XCTAssertEqual(
                normalisedSections(lhs.stateActivities(for: stateID)),
                normalisedSections(rhs.stateActivities(for: rhsStateID)),
                file: file,
                line: line
            )
        }

        XCTAssertEqual(lhs.transitionLayout.count, rhs.transitionLayout.count, file: file, line: line)
        for transitionID in lhs.llfsm.transitions {
            guard let transition = lhs.llfsm.transition(for: transitionID) else {
                XCTFail("Missing source transition", file: file, line: line)
                continue
            }
            let sourceName = lhs.llfsm.stateName(for: transition.source)
            let targetName = lhs.llfsm.stateName(for: transition.target)
            guard let rhsTransitionID = rhs.llfsm.transitions.first(where: {
                guard let rhsTransition = rhs.llfsm.transition(for: $0) else { return false }
                return rhsTransition.label == transition.label
                    && rhs.llfsm.stateName(for: rhsTransition.source) == sourceName
                    && rhs.llfsm.stateName(for: rhsTransition.target) == targetName
            }) else {
                XCTFail("Missing transition '\(transition.label)'", file: file, line: line)
                continue
            }
            assertTransitionLayoutsEqual(
                lhs.transitionLayout[transitionID],
                rhs.transitionLayout[rhsTransitionID],
                file: file,
                line: line
            )
        }
    }

    private static func assertStateLayoutsEqual(
        _ lhs: StateLayout?,
        _ rhs: StateLayout?,
        file: StaticString,
        line: UInt
    ) {
        XCTAssertEqual(lhs?.isOpen, rhs?.isOpen, file: file, line: line)
        XCTAssertEqual(lhs?.closedLayout.x ?? 0, rhs?.closedLayout.x ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.closedLayout.y ?? 0, rhs?.closedLayout.y ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.closedLayout.w ?? 0, rhs?.closedLayout.w ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.closedLayout.h ?? 0, rhs?.closedLayout.h ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.openLayout.x ?? 0, rhs?.openLayout.x ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.openLayout.y ?? 0, rhs?.openLayout.y ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.openLayout.w ?? 0, rhs?.openLayout.w ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.openLayout.h ?? 0, rhs?.openLayout.h ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.onEntryHeight ?? 0, rhs?.onEntryHeight ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.onExitHeight ?? 0, rhs?.onExitHeight ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.internalHeight ?? 0, rhs?.internalHeight ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.onSuspendHeight ?? 0, rhs?.onSuspendHeight ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.onResumeHeight ?? 0, rhs?.onResumeHeight ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.zoomedOnEntryHeight ?? 0, rhs?.zoomedOnEntryHeight ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.zoomedOnExitHeight ?? 0, rhs?.zoomedOnExitHeight ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.zoomedInternalHeight ?? 0, rhs?.zoomedInternalHeight ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.zoomedOnSuspendHeight ?? 0, rhs?.zoomedOnSuspendHeight ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.zoomedOnResumeHeight ?? 0, rhs?.zoomedOnResumeHeight ?? 0, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(lhs?.extraProperties.count ?? 0, rhs?.extraProperties.count ?? 0, file: file, line: line)
    }

    private static func assertTransitionLayoutsEqual(
        _ lhs: TransitionLayout?,
        _ rhs: TransitionLayout?,
        file: StaticString,
        line: UInt
    ) {
        XCTAssertEqual(lhs?.path.points.count, rhs?.path.points.count, file: file, line: line)
        for (left, right) in zip(lhs?.path.points ?? [], rhs?.path.points ?? []) {
            XCTAssertEqual(left.x, right.x, accuracy: 0.001, file: file, line: line)
            XCTAssertEqual(left.y, right.y, accuracy: 0.001, file: file, line: line)
        }
    }

    private static func assertLLFSMStructureEqual(
        _ lhs: LLFSM,
        _ rhs: LLFSM,
        file: StaticString,
        line: UInt
    ) {
        XCTAssertEqual(lhs.states.count, rhs.states.count, file: file, line: line)
        XCTAssertEqual(lhs.stateNames, rhs.stateNames, file: file, line: line)

        let lhsSuspend = lhs.suspendState.flatMap { lhs.stateName(for: $0) }
        let rhsSuspend = rhs.suspendState.flatMap { rhs.stateName(for: $0) }
        XCTAssertEqual(lhsSuspend, rhsSuspend, file: file, line: line)

        let lhsTransitions = lhs.transitions.compactMap { transitionID -> String? in
            guard let transition = lhs.transition(for: transitionID) else { return nil }
            let source = lhs.stateName(for: transition.source) ?? ""
            let target = lhs.stateName(for: transition.target) ?? ""
            return "\(source)|\(transition.label)|\(target)"
        }
        let rhsTransitions = rhs.transitions.compactMap { transitionID -> String? in
            guard let transition = rhs.transition(for: transitionID) else { return nil }
            let source = rhs.stateName(for: transition.source) ?? ""
            let target = rhs.stateName(for: transition.target) ?? ""
            return "\(source)|\(transition.label)|\(target)"
        }
        XCTAssertEqual(lhsTransitions, rhsTransitions, file: file, line: line)
    }

    private static func normalisedSections(
        _ sections: [StandardBoilerplateSection: String]
    ) -> [StandardBoilerplateSection: String] {
        Dictionary(uniqueKeysWithValues: StandardBoilerplateSection.allCases.map { key in
            (key, sections[key] ?? "")
        })
    }

    private static func directoryContents(
        at url: URL,
        restrictedTo allowedRelativePaths: Set<String>?
    ) throws -> [String: String] {
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey]
        let baseURL = url.standardizedFileURL.resolvingSymlinksInPath()
        let enumerator = fileManager.enumerator(at: baseURL, includingPropertiesForKeys: keys)
        var contents: [String: String] = [:]

        while let fileURL = enumerator?.nextObject() as? URL {
            let values = try fileURL.resourceValues(forKeys: Set(keys))
            guard values.isDirectory != true else { continue }

            let normalisedFileURL = fileURL.standardizedFileURL.resolvingSymlinksInPath()
            let relativePath = normalisedGeneratedPath(
                normalisedFileURL.path.replacingOccurrences(of: baseURL.path + "/", with: "")
            )
            if let allowedRelativePaths, !allowedRelativePaths.contains(relativePath) {
                continue
            }
            contents[relativePath] = try String(contentsOf: normalisedFileURL, encoding: .utf8)
        }

        return contents
    }

    private static func normalisedGeneratedPath(_ rawPath: String) -> String {
        if rawPath.hasPrefix("/private") {
            return String(rawPath.dropFirst("/private".count))
        }
        if rawPath.hasPrefix("private") {
            return String(rawPath.dropFirst("private".count))
        }
        if rawPath.hasPrefix("/") {
            return String(rawPath.dropFirst())
        }
        return rawPath
    }
}
