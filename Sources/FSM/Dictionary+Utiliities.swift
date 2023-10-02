//
//  Dictionary+Utiliities.swift
//  
//  Created by Rene Hexel on 7/8/2023.
//  Copyright © 2016, 2023 Rene Hexel. All rights reserved.
//
import Foundation

extension NSDictionary {
    /// Non-optional value for the given state layout key.
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
        guard let v = self[key.rawValue] as? T else { return `default` }
        return v
    }

    /// Non-optional value for the given transition layout key.
    ///
    /// This function returns a value for a given transition layout key,
    /// or a default value if the key is not present.
    ///
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - default: The default value to return if the key is not present.
    /// - Returns: The value for the given key, or the default value.
    @usableFromInline
    func transitionValue<T>(_ key: TransitionLayoutKey, default: T) -> T {
        transitionValue(key) ?? `default`
    }

    /// Typed, optional value for the given transition layout key.
    ///
    /// This function returns a value for a given transition layout key,
    /// or `nil` if the key is not present.
    ///
    /// - Parameters:
    ///   - key: The key to look up.
    /// - Returns: The value for the given key, or `nil`.
    @usableFromInline
    func transitionValue<T>(_ key: TransitionLayoutKey) -> T? {
        self[key.rawValue] as? T
    }
#if canImport(Darwin)
    /// Set the value for the given state layout key.
    ///
    /// This function uses the strongly typed
    /// `StateLayoutKey` to set a dictionary value.
    ///
    /// - Parameters:
    ///   - value: The value to set.
    ///   - key: The layout key to use.
    @usableFromInline
    func set<T>(value: T, for key: StateLayoutKey) {
        setValue(value, forKey: key.rawValue)
    }

    /// Set the value for the given transition layout key.
    ///
    /// This function uses the strongly typed
    /// `TransitionLayoutKey` to set a dictionary value.
    ///
    /// - Parameters:
    ///   - value: The value to set.
    ///   - key: The layout key to use.
    @usableFromInline
    func set<T>(value: T, forTransition key: TransitionLayoutKey) {
        setValue(value, forKey: key.rawValue)
    }

    /// Set the value for the given string key.
    ///
    /// - Parameters:
    ///   - value: The value to set.
    ///   - key: The layout key to use.
    @usableFromInline
    func set<T>(value: T, forString key: String) {
        setValue(value, forKey: key)
    }
#endif
}

extension Dictionary where Key == AnyHashable, Value: Any {
    /// Non-optional value for the given state layout key.
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
        guard let v = self[key.rawValue] as? T else { return `default` }
        return v
    }

    /// Non-optional value for the given transition layout key.
    ///
    /// This function returns a value for a given transition layout key,
    /// or a default value if the key is not present.
    ///
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - default: The default value to return if the key is not present.
    /// - Returns: The value for the given key, or the default value.
    @usableFromInline
    func transitionValue<T>(_ key: TransitionLayoutKey, default: T) -> T {
        transitionValue(key) ?? `default`
    }

    /// Typed, optional value for the given transition layout key.
    ///
    /// This function returns a value for a given transition layout key,
    /// or `nil` if the key is not present.
    ///
    /// - Parameters:
    ///   - key: The key to look up.
    /// - Returns: The value for the given key, or `nil`.
    @usableFromInline
    func transitionValue<T>(_ key: TransitionLayoutKey) -> T? {
        self[key.rawValue] as? T
    }

    /// Set the value for the given state layout key.
    ///
    /// This function uses the strongly typed
    /// `StateLayoutKey` to set a dictionary value.
    ///
    /// - Parameters:
    ///   - value: The value to set.
    ///   - key: The layout key to use.
    @usableFromInline
    mutating func set<T>(value: T, for key: StateLayoutKey) {
        self[AnyHashable(key.rawValue)] = value as? Value
    }

    /// Set the value for the given transition layout key.
    ///
    /// This function uses the strongly typed
    /// `TransitionLayoutKey` to set a dictionary value.
    ///
    /// - Parameters:
    ///   - value: The value to set.
    ///   - key: The layout key to use.
    @usableFromInline
    mutating func set<T>(value: T, forTransition key: TransitionLayoutKey) {
        self[AnyHashable(key.rawValue)] = value as? Value
    }

    /// Set the value for the given string key.
    ///
    /// - Parameters:
    ///   - value: The value to set.
    ///   - key: The layout key to use.
    @usableFromInline
    mutating func set<T>(value: T, forString key: String) {
        self[AnyHashable(key)] = value as? Value
    }
}
