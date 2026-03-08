import ECore
import EMFBase
import FSM
import Foundation

/// XMI round-trip helper for executable LLFSM models.
///
/// `ExecutableXMIRoundTrip` wraps the executable codecs and `swift-ecore`
/// parser and serialiser behind file-oriented operations. It registers the
/// bundled executable metamodel before loading instance models so the legacy
/// LLFSM namespace resolves to the expected typed hierarchy.
public struct ExecutableXMIRoundTrip {
    /// Executable metamodel used for XMI conversion.
    public let metamodel: ExecutableLLFSMMetamodel

    /// Create the executable XMI round-trip helper.
    ///
    /// - Parameter metamodel: Loaded executable metamodel to use for
    ///   conversion.
    public init(metamodel: ExecutableLLFSMMetamodel) {
        self.metamodel = metamodel
    }

    /// Write a machine as executable XMI.
    ///
    /// - Parameters:
    ///   - machine: Machine value to serialise.
    ///   - name: Machine name to preserve in the executable model.
    ///   - arrangementName: Optional arrangement name. Defaults to `name`.
    ///   - url: Destination URL for the XMI document.
    /// - Throws: Throw an error if encoding or file output fails.
    public func write(machine: Machine, name: String, arrangementName: String? = nil, to url: URL) async throws {
        let resource = Resource(uri: url.absoluteString)
        let codec = ExecutableMachineCodec(metamodel: metamodel)
        _ = await codec.encode(machine, name: name, arrangementName: arrangementName, into: resource)
        let xmi = try await ExecutableXMIWriter(metamodel: metamodel).serialise(resource)
        try xmi.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Read a machine from executable XMI.
    ///
    /// - Parameter url: URL of the XMI document to read.
    /// - Returns: Decoded machine name and machine value.
    /// - Throws: Throw an error if parsing or decoding fails.
    public func readMachine(from url: URL) async throws -> (name: String, machine: Machine) {
        let resource = try await loadResource(from: url)
        guard let object = await findExecutableRoot(in: resource) else {
            throw ExecutableLLFSMMetamodelError.missingFeature("root executable object")
        }
        let codec = ExecutableMachineCodec(metamodel: metamodel)
        return try await codec.decode(object, from: resource)
    }

    /// Write an arrangement as executable XMI.
    ///
    /// - Parameters:
    ///   - arrangement: Arrangement value to serialise.
    ///   - name: Arrangement name to preserve in the executable model.
    ///   - url: Destination URL for the XMI document.
    /// - Throws: Throw an error if encoding or file output fails.
    public func write(arrangement: Arrangement, name: String, to url: URL) async throws {
        let resource = Resource(uri: url.absoluteString)
        let codec = ExecutableArrangementCodec(metamodel: metamodel)
        _ = await codec.encode(arrangement, name: name, into: resource)
        try await write(resource: resource, to: url)
    }

    /// Read an arrangement from executable XMI.
    ///
    /// - Parameter url: URL of the XMI document to read.
    /// - Returns: Decoded arrangement value.
    /// - Throws: Throw an error if parsing or decoding fails.
    public func readArrangement(from url: URL) async throws -> Arrangement {
        let resource = try await loadResource(from: url)
        guard let arrangementObject = await findArrangementRoot(in: resource) else {
            throw ExecutableLLFSMMetamodelError.missingFeature("Arrangement root")
        }
        let codec = ExecutableArrangementCodec(metamodel: metamodel)
        return try await codec.decode(arrangementObject, from: resource)
    }

    /// Write an executable model resource as XMI.
    ///
    /// - Parameters:
    ///   - resource: Executable resource to serialise.
    ///   - url: Destination URL for the XMI document.
    /// - Throws: Throw an error if serialisation or file output fails.
    public func write(resource: Resource, to url: URL) async throws {
        let xmi = try await ExecutableXMIWriter(metamodel: metamodel).serialise(resource)
        try xmi.write(to: url, atomically: true, encoding: .utf8)
    }

    /// Load an executable model resource from XMI.
    ///
    /// - Parameter url: URL of the XMI document to parse.
    /// - Returns: Parsed executable resource.
    /// - Throws: Throw an error if parsing fails.
    public func loadResource(from url: URL) async throws -> Resource {
        let resourceSet = ResourceSet()
        await resourceSet.registerMetamodel(metamodel.package, uri: metamodel.package.nsURI)
        let parser = XMIParser(resourceSet: resourceSet)
        return try await parser.parse(url)
    }

    private func findExecutableRoot(in resource: Resource) async -> DynamicEObject? {
        let roots = await resource.getRootObjects().compactMap { $0 as? DynamicEObject }
        if let arrangement = roots.first(where: { $0.eClass.name == metamodel.arrangementClass.name }) {
            return arrangement
        }
        if let machine = roots.first(where: { $0.eClass.name == metamodel.stateMachineClass.name }) {
            return machine
        }
        let objects = await resource.getAllObjects().compactMap { $0 as? DynamicEObject }
        return objects.first {
            $0.eClass.name == metamodel.arrangementClass.name || $0.eClass.name == metamodel.stateMachineClass.name
        }
    }

    private func findArrangementRoot(in resource: Resource) async -> DynamicEObject? {
        let roots = await resource.getRootObjects().compactMap { $0 as? DynamicEObject }
        if let arrangement = roots.first(where: { $0.eClass.name == metamodel.arrangementClass.name }) {
            return arrangement
        }
        let objects = await resource.getAllObjects().compactMap { $0 as? DynamicEObject }
        return objects.first(where: { $0.eClass.name == metamodel.arrangementClass.name })
    }
}

struct ExecutableXMIWriter {
    let metamodel: ExecutableLLFSMMetamodel

    private var prefix: String {
        let candidate = metamodel.package.nsPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        return candidate.isEmpty ? "newGITmetamodelwithtypes" : candidate
    }

    private var namespaceURI: String {
        let candidate = metamodel.package.nsURI.trimmingCharacters(in: .whitespacesAndNewlines)
        return candidate.isEmpty ? "http://www.example.org/newGITmetamodelwithtypes" : candidate
    }

    func serialise(_ resource: Resource) async throws -> String {
        guard let root = await findRoot(in: resource) else {
            throw ExecutableLLFSMMetamodelError.missingFeature("root executable object")
        }
        var paths: [EUUID: String] = [:]
        await collectPaths(for: root, currentPath: "", in: resource, into: &paths)

        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += await serialiseElement(
            named: "\(prefix):\(root.eClass.name)",
            object: root,
            in: resource,
            paths: paths,
            indent: 0,
            includeNamespaceDeclarations: true,
            includeTypeAttribute: false
        )
        return xml
    }

    private func findRoot(in resource: Resource) async -> DynamicEObject? {
        let roots = await resource.getRootObjects().compactMap { $0 as? DynamicEObject }
        if let arrangement = roots.first(where: { $0.eClass.name == metamodel.arrangementClass.name }) {
            return arrangement
        }
        if let machine = roots.first(where: { $0.eClass.name == metamodel.stateMachineClass.name }) {
            return machine
        }
        let objects = await resource.getAllObjects().compactMap { $0 as? DynamicEObject }
        return objects.first {
            $0.eClass.name == metamodel.arrangementClass.name || $0.eClass.name == metamodel.stateMachineClass.name
        }
    }

    private func collectPaths(
        for object: DynamicEObject,
        currentPath: String,
        in resource: Resource,
        into paths: inout [EUUID: String]
    ) async {
        paths[object.id] = currentPath

        for reference in object.eClass.allReferences where reference.containment {
            let value = await resource.eGet(objectId: object.id, feature: reference.name)
            if reference.upperBound == 1 {
                guard let child = await resolveObject(from: value, in: resource) else {
                    continue
                }
                let childPath = path(for: reference.name, index: nil, parentPath: currentPath)
                await collectPaths(for: child, currentPath: childPath, in: resource, into: &paths)
                continue
            }

            for (index, child) in await resolveObjects(from: value, in: resource).enumerated() {
                let childPath = path(for: reference.name, index: index, parentPath: currentPath)
                await collectPaths(for: child, currentPath: childPath, in: resource, into: &paths)
            }
        }
    }

    private func serialiseElement(
        named elementName: String,
        object: DynamicEObject,
        in resource: Resource,
        paths: [EUUID: String],
        indent: Int,
        includeNamespaceDeclarations: Bool,
        includeTypeAttribute: Bool
    ) async -> String {
        let indentation = String(repeating: "    ", count: indent)
        var attributes: [String] = []
        if includeNamespaceDeclarations {
            attributes.append("xmi:version=\"2.0\"")
            attributes.append("xmlns:xmi=\"http://www.omg.org/XMI\"")
            attributes.append("xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"")
            attributes.append("xmlns:\(prefix)=\"\(escapeXML(namespaceURI))\"")
        }
        if includeTypeAttribute {
            attributes.append("xsi:type=\"\(prefix):\(object.eClass.name)\"")
        }

        for feature in object.eClass.allStructuralFeatures {
            guard !(feature is EReference),
                  let value = await resource.eGet(objectId: object.id, feature: feature.name) else {
                continue
            }
            attributes.append("\(feature.name)=\"\(escapeXML(stringValue(for: value)))\"")
        }

        let children = await serialiseReferenceChildren(
            of: object,
            in: resource,
            paths: paths,
            indent: indent + 1
        )

        let attributeString = attributes.isEmpty ? "" : " " + attributes.joined(separator: " ")
        guard !children.isEmpty else {
            return "\(indentation)<\(elementName)\(attributeString)/>\n"
        }

        return "\(indentation)<\(elementName)\(attributeString)>\n\(children)\(indentation)</\(elementName)>\n"
    }

    private func serialiseReferenceChildren(
        of object: DynamicEObject,
        in resource: Resource,
        paths: [EUUID: String],
        indent: Int
    ) async -> String {
        var children = ""
        let indentation = String(repeating: "    ", count: indent)

        for reference in object.eClass.allReferences {
            let value = await resource.eGet(objectId: object.id, feature: reference.name)
            guard let value else {
                continue
            }

            if reference.containment {
                if reference.upperBound == 1 {
                    guard let child = await resolveObject(from: value, in: resource) else {
                        continue
                    }
                    children += await serialiseElement(
                        named: reference.name,
                        object: child,
                        in: resource,
                        paths: paths,
                        indent: indent,
                        includeNamespaceDeclarations: false,
                        includeTypeAttribute: true
                    )
                } else {
                    for child in await resolveObjects(from: value, in: resource) {
                        children += await serialiseElement(
                            named: reference.name,
                            object: child,
                            in: resource,
                            paths: paths,
                            indent: indent,
                            includeNamespaceDeclarations: false,
                            includeTypeAttribute: true
                        )
                    }
                }
                continue
            }

            if reference.upperBound == 1 {
                guard let child = await resolveObject(from: value, in: resource),
                      let path = paths[child.id] else {
                    continue
                }
                children += "\(indentation)<\(reference.name) href=\"#\(escapeXML(path))\"/>\n"
            } else {
                for child in await resolveObjects(from: value, in: resource) {
                    guard let path = paths[child.id] else {
                        continue
                    }
                    children += "\(indentation)<\(reference.name) href=\"#\(escapeXML(path))\"/>\n"
                }
            }
        }

        return children
    }

    private func resolveObject(from value: Any?, in resource: Resource) async -> DynamicEObject? {
        guard let value else {
            return nil
        }
        if let object = value as? DynamicEObject {
            return object
        }
        if let objectID = value as? EUUID {
            return await resource.resolve(objectID) as? DynamicEObject
        }
        return nil
    }

    private func resolveObjects(from value: Any?, in resource: Resource) async -> [DynamicEObject] {
        guard let value else {
            return []
        }
        if let objects = value as? [DynamicEObject] {
            return objects
        }
        if let objectIDs = value as? [EUUID] {
            var objects: [DynamicEObject] = []
            for objectID in objectIDs {
                if let object = await resource.resolve(objectID) as? DynamicEObject {
                    objects.append(object)
                }
            }
            return objects
        }
        if let object = await resolveObject(from: value, in: resource) {
            return [object]
        }
        return []
    }

    private func path(for featureName: String, index: Int?, parentPath: String) -> String {
        let suffix = index.map { "@\(featureName).\($0)" } ?? "@\(featureName)"
        return parentPath.isEmpty ? "//\(suffix)" : "\(parentPath)/\(suffix)"
    }

    private func stringValue(for value: Any) -> String {
        switch value {
        case let string as String:
            return string
        case let bool as Bool:
            return bool ? "true" : "false"
        case let int as Int:
            return String(int)
        case let double as Double:
            return String(double)
        case let uuid as EUUID:
            return uuid.uuidString
        default:
            return String(describing: value)
        }
    }

    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
