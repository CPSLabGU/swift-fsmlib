//
//  Dictionary+Utiliities.swift
//  
//  Created by Rene Hexel on 7/8/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

extension NSDictionary {
    /// Non-optional value for the given key.
    ///
    /// This function returns a value for a given key,
    /// or a default value if the key is not present.
    ///
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - default: The default value to return if the key is not present.
    /// - Returns: The value for the given key, or the default value.
    @usableFromInline
    func value<T>(_ key: StateLayoutKey, default: T) -> T {
        guard let v = self[key] as? T else { return `default` }
        return v
    }
}
