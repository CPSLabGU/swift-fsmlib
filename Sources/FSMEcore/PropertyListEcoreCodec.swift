//
//  PropertyListEcoreCodec.swift
//  FSMEcore
//
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import ECore
import EMFBase
import Foundation

/// The kinds of value that a property list distinguishes.
///
/// Editors keep additional state layout properties, such as colours, as
/// property list values. The property list format distinguishes Boolean,
/// floating point and integral numbers, so the classification inspects the
/// stored representation of a number rather than its numeric value.
enum PropertyListValueKind {
    /// A Boolean value.
    case boolean(Bool)
    /// A floating point number.
    case real(Double)
    /// An integral number.
    case integer(Int64)
    /// A text value.
    case string(String)
    /// A binary value.
    case data(Data)
    /// A point in time.
    case date(Date)
    /// An ordered list of values.
    case array([Any])
    /// Keyed values.
    case dictionary([String: Any])
    /// A value that a property list cannot hold.
    case unsupported

    /// Classify a value read from, or destined for, a property list.
    ///
    /// - Parameter value: The value to classify.
    init(_ value: Any) {
        if let kind = Self.number(value) {
            self = kind
            return
        }
        switch value {
        case let string as String: self = .string(string)
        case let data as Data: self = .data(data)
        case let date as Date: self = .date(date)
        case let dictionary as [String: Any]: self = .dictionary(dictionary)
        case let array as [Any]: self = .array(array)
        default: self = .unsupported
        }
    }

    /// Classify a numeric or Boolean value.
    ///
    /// - Parameter value: The value to classify.
    /// - Returns: The kind of number, or `nil` if the value is not a number.
    private static func number(_ value: Any) -> PropertyListValueKind? {
#if canImport(Darwin)
        guard let number = value as? NSNumber else { return nil }
        if CFGetTypeID(number) == CFBooleanGetTypeID() { return .boolean(number.boolValue) }
        if CFNumberIsFloatType(number) { return .real(number.doubleValue) }
        return .integer(number.int64Value)
#else
        switch value {
        case let boolean as Bool where type(of: value) == Bool.self: return .boolean(boolean)
        case let real as Double where type(of: value) == Double.self: return .real(real)
        case let real as Float where type(of: value) == Float.self: return .real(Double(real))
        case let integer as Int where type(of: value) == Int.self: return .integer(Int64(integer))
        case let integer as Int64 where type(of: value) == Int64.self: return .integer(integer)
        case let integer as Int32 where type(of: value) == Int32.self: return .integer(Int64(integer))
        case let integer as UInt where type(of: value) == UInt.self: return .integer(Int64(truncatingIfNeeded: integer))
        case let number as NSNumber:
            switch String(cString: number.objCType) {
            case "f", "d": return .real(number.doubleValue)
            case "B": return .boolean(number.boolValue)
            default: return .integer(number.int64Value)
            }
        default:
            return nil
        }
#endif
    }
}

/// Converts additional layout properties to and from typed model objects.
///
/// Each property becomes a `PropertyListEntry` whose value is an instance of
/// one of the concrete `PropertyListValue` classes, so that the exact value
/// types of a property list survive the structural model and can be written
/// back unchanged.
struct PropertyListEcoreCodec {
    /// The metamodel that declares the property list classes.
    let metamodel: LLFSMMetamodel

    /// The feature names used by the property list classes.
    enum Feature {
        /// The key of an entry.
        static let key = "key"
        /// The value of an entry or of a scalar value object.
        static let value = "value"
        /// The items of an array value.
        static let items = "items"
        /// The entries of a dictionary value.
        static let entries = "entries"
    }

    /// Encode keyed properties as entries registered with a resource.
    ///
    /// Entries are created in key order, so that equal properties always
    /// produce the same model.
    ///
    /// - Parameters:
    ///   - properties: The keyed properties to encode.
    ///   - resource: The resource that owns the created objects.
    /// - Returns: The identifiers of the created entries, in key order.
    func encodeEntries(_ properties: [String: Any], into resource: Resource) async -> [EUUID] {
        var identifiers = [EUUID]()
        for key in properties.keys.sorted() {
            guard let value = properties[key],
                  let valueObject = await encodeValue(value, into: resource) else { continue }
            var entry = DynamicEObject(eClass: metamodel.propertyListEntryClass)
            entry.eSet(Feature.key, value: key)
            entry.eSet(Feature.value, value: valueObject.id)
            await resource.register(entry)
            identifiers.append(entry.id)
        }
        return identifiers
    }

    /// Encode one value as a typed value object registered with a resource.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - resource: The resource that owns the created objects.
    /// - Returns: The created value object, or `nil` if a property list cannot hold the value.
    func encodeValue(_ value: Any, into resource: Resource) async -> DynamicEObject? {
        var object: DynamicEObject
        switch PropertyListValueKind(value) {
        case .boolean(let boolean):
            object = DynamicEObject(eClass: metamodel.propertyListBooleanClass)
            object.eSet(Feature.value, value: boolean)
        case .real(let real):
            object = DynamicEObject(eClass: metamodel.propertyListRealClass)
            object.eSet(Feature.value, value: real)
        case .integer(let integer):
            object = DynamicEObject(eClass: metamodel.propertyListIntegerClass)
            object.eSet(Feature.value, value: Int(truncatingIfNeeded: integer))
        case .string(let string):
            object = DynamicEObject(eClass: metamodel.propertyListStringClass)
            object.eSet(Feature.value, value: string)
        case .data(let data):
            object = DynamicEObject(eClass: metamodel.propertyListDataClass)
            object.eSet(Feature.value, value: data.base64EncodedString())
        case .date(let date):
            object = DynamicEObject(eClass: metamodel.propertyListDateClass)
            object.eSet(Feature.value, value: Self.dateFormatter().string(from: date))
        case .array(let array):
            var items = [EUUID]()
            for item in array {
                guard let itemObject = await encodeValue(item, into: resource) else { continue }
                items.append(itemObject.id)
            }
            object = DynamicEObject(eClass: metamodel.propertyListArrayClass)
            object.eSet(Feature.items, value: items)
        case .dictionary(let dictionary):
            let entries = await encodeEntries(dictionary, into: resource)
            object = DynamicEObject(eClass: metamodel.propertyListDictionaryClass)
            object.eSet(Feature.entries, value: entries)
        case .unsupported:
            return nil
        }
        await resource.register(object)
        return object
    }

    /// Decode entries back into keyed properties.
    ///
    /// - Parameters:
    ///   - identifiers: The identifiers of the entries to decode.
    ///   - resource: The resource that holds the entries.
    /// - Returns: The decoded properties by key.
    func decodeEntries(_ identifiers: [EUUID], from resource: Resource) async -> [String: Any] {
        var properties = [String: Any]()
        for identifier in identifiers {
            guard let key = await resource.eGet(objectId: identifier, feature: Feature.key) as? String,
                  let valueID = ModelReferences.identifier(
                      from: await resource.eGet(objectId: identifier, feature: Feature.value)),
                  let value = await decodeValue(valueID, from: resource) else { continue }
            properties[key] = value
        }
        return properties
    }

    /// Decode one typed value object.
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the value object.
    ///   - resource: The resource that holds the object.
    /// - Returns: The decoded value, or `nil` if the object is not a property list value.
    func decodeValue(_ identifier: EUUID, from resource: Resource) async -> Any? {
        guard let object = await resource.resolve(identifier) as? DynamicEObject else { return nil }
        let stored = await resource.eGet(objectId: identifier, feature: Feature.value)
        switch object.eClass.name {
        case metamodel.propertyListBooleanClass.name:
            return Self.boolean(from: stored)
        case metamodel.propertyListRealClass.name:
            return Self.real(from: stored)
        case metamodel.propertyListIntegerClass.name:
            return Self.integer(from: stored)
        case metamodel.propertyListStringClass.name:
            return stored as? String ?? ""
        case metamodel.propertyListDataClass.name:
            return (stored as? String).flatMap { Data(base64Encoded: $0) } ?? Data()
        case metamodel.propertyListDateClass.name:
            return (stored as? String).flatMap { Self.dateFormatter().date(from: $0) }
        case metamodel.propertyListArrayClass.name:
            var items = [Any]()
            let itemIDs = ModelReferences.identifiers(
                from: await resource.eGet(objectId: identifier, feature: Feature.items))
            for itemID in itemIDs {
                if let item = await decodeValue(itemID, from: resource) { items.append(item) }
            }
            return items
        case metamodel.propertyListDictionaryClass.name:
            let entryIDs = ModelReferences.identifiers(
                from: await resource.eGet(objectId: identifier, feature: Feature.entries))
            return await decodeEntries(entryIDs, from: resource)
        default:
            return nil
        }
    }

    /// Create the formatter for the timestamps of date values.
    ///
    /// - Returns: A formatter for ISO 8601 timestamps in UTC with whole seconds.
    static func dateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }

    /// Read a Boolean from a stored attribute value.
    ///
    /// - Parameter stored: The stored value.
    /// - Returns: The Boolean, `false` if the value is absent or not Boolean.
    static func boolean(from stored: Any?) -> Bool {
        switch stored {
        case let boolean as Bool: return boolean
        case let text as String: return text == "true"
        default: return false
        }
    }

    /// Read a floating point number from a stored attribute value.
    ///
    /// - Parameter stored: The stored value.
    /// - Returns: The number, zero if the value is absent or not numeric.
    static func real(from stored: Any?) -> Double {
        switch stored {
        case let real as Double: return real
        case let real as Float: return Double(real)
        case let integer as Int: return Double(integer)
        case let text as String: return Double(text) ?? 0
        default: return 0
        }
    }

    /// Read an integral number from a stored attribute value.
    ///
    /// - Parameter stored: The stored value.
    /// - Returns: The number, zero if the value is absent or not integral.
    static func integer(from stored: Any?) -> Int {
        switch stored {
        case let integer as Int: return integer
        case let integer as Int64: return Int(truncatingIfNeeded: integer)
        case let integer as Int32: return Int(integer)
        case let real as Double: return Int(real)
        case let text as String: return Int(text) ?? 0
        default: return 0
        }
    }
}

/// Normalisation of stored references into object identifiers.
///
/// Structural resources keep references either as identifiers or as
/// objects, and many-valued references either as arrays or as single values.
enum ModelReferences {
    /// Normalise a single reference value into an object identifier.
    ///
    /// - Parameter value: The stored reference value.
    /// - Returns: The identifier of the referenced object, or `nil` if there is none.
    static func identifier(from value: Any?) -> EUUID? {
        switch value {
        case let id as EUUID:
            return id
        case let object as DynamicEObject:
            return object.id
        case let objects as [DynamicEObject]:
            return objects.first?.id
        case let ids as [EUUID]:
            return ids.first
        case let values as [Any]:
            return values.lazy.compactMap { identifier(from: $0) }.first
        default:
            return nil
        }
    }

    /// Normalise a many-valued reference into object identifiers.
    ///
    /// - Parameter value: The stored reference value.
    /// - Returns: The identifiers of the referenced objects, in order.
    static func identifiers(from value: Any?) -> [EUUID] {
        switch value {
        case let ids as [EUUID]:
            return ids
        case let id as EUUID:
            return [id]
        case let objects as [DynamicEObject]:
            return objects.map(\.id)
        case let object as DynamicEObject:
            return [object.id]
        case let values as [Any]:
            return values.compactMap { identifier(from: $0) }
        default:
            return []
        }
    }
}
