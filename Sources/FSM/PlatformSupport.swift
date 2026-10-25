//
//  PlatformSupport.swift
//
//  Created by Rene Hexel on 25/10/2026.
//  Copyright © 2026 Rene Hexel. All rights reserved.
//
import Foundation

/// File system facilities whose availability depends on the runtime.
///
/// Native platforms replace files atomically and read and write property
/// lists through Foundation.  WebAssembly (WASI) hosts have no temporary
/// files for an atomic replace, `NSDictionary` has no URL initialiser
/// there, and `PropertyListSerialization` cannot write nested arrays.
/// This type keeps those differences in one place, so that every other
/// platform retains its native behaviour.
@usableFromInline
enum PlatformSupport {
    /// Whether files are replaced atomically on this runtime.
    ///
    /// This is `true` on every native platform and `false` on WASI,
    /// where files are written directly.
    @usableFromInline static var writesAtomically: Bool {
        #if os(WASI)
        false
        #else
        true
        #endif
    }

    /// The data writing options that replace a file atomically where supported.
    ///
    /// On native platforms this is `.atomic`; on WASI it is empty.
    @usableFromInline static var atomicWritingOptions: Data.WritingOptions {
        #if os(WASI)
        []
        #else
        .atomic
        #endif
    }

    /// Reads a property list dictionary from a file.
    ///
    /// - Parameter url: The location of the property list file.
    /// - Returns: The dictionary stored in the file, or `nil` if the file
    ///   cannot be read or does not contain a dictionary.
    @usableFromInline
    static func dictionary(contentsOf url: URL) -> NSDictionary? {
        #if os(WASI)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? NSDictionary
        #else
        NSDictionary(contentsOf: url)
        #endif
    }

    /// Creates the XML document of a property list.
    ///
    /// - Parameter propertyList: The property list to write.
    /// - Returns: The UTF-8 encoded XML document.
    /// - Throws: An error if the value is not a valid property list.
    @usableFromInline
    static func xmlPropertyListData(from propertyList: Any) throws -> Data {
        #if os(WASI)
        try XMLPropertyListWriter.data(from: propertyList)
        #else
        try PropertyListSerialization.data(fromPropertyList: propertyList, format: .xml, options: 0)
        #endif
    }
}
