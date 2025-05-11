//
//  PropertyList.swift
//
//  Created by Rene Hexel on 13/10/2018.
//  Copyright © 2018, 2019, 2023, 2025 Rene Hexel. All rights reserved.
//
import Foundation

/// Abstract type that is suitable for property list serialisation.
///
/// This protocol is used as a marker for types that can be
/// safely serialised to and from property lists (plist files)
/// in Foundation. Types conforming to this protocol are compatible
/// with property list serialisation and deserialisation,
/// enabling their use in persistent storage, configuration files,
/// and data interchange.
///
/// - Note: Common Foundation types such as `NSArray`,
/// `NSDictionary`, `NSString`, `NSNumber`, `NSData`, and `NSDate`
/// make up property lists, and conform to this protocol by default.
public protocol PropertyList {}

/// Extension to make NSArray conform to PropertyList for serialisation.
///
/// This extension allows NSArray instances to be used as property lists,
/// enabling their serialisation and deserialisation using Foundation's
/// property list mechanisms. This is essential for storing collections
/// of objects in a format compatible with property lists.
extension NSArray: PropertyList {}
/// Extension to make NSDictionary conform to PropertyList for serialisation.
///
/// This extension allows NSDictionary instances to be used as property lists,
/// enabling their serialisation and deserialisation using Foundation's
/// property list mechanisms. This is essential for storing key-value
/// collections in a format compatible with property lists.
extension NSDictionary: PropertyList {}
/// Extension to make NSString conform to PropertyList for serialisation.
///
/// This extension allows NSString instances to be used as property lists,
/// enabling their serialisation and deserialisation using Foundation's
/// property list mechanisms. This is essential for storing string values
/// in a format compatible with property lists.
extension NSString: PropertyList {}
/// Extension to make NSNumber conform to PropertyList for serialisation.
///
/// This extension allows NSNumber instances to be used as property lists,
/// enabling their serialisation and deserialisation using Foundation's
/// property list mechanisms. This is essential for storing numeric values
/// in a format compatible with property lists.
extension NSNumber: PropertyList {}
/// Extension to make NSData conform to PropertyList for serialisation.
///
/// This extension allows NSData instances to be used as property lists,
/// enabling their serialisation and deserialisation using Foundation's
/// property list mechanisms. This is essential for storing binary data
/// in a format compatible with property lists.
extension NSData: PropertyList {}
/// Extension to make NSDate conform to PropertyList for serialisation.
///
/// This extension allows NSDate instances to be used as property lists,
/// enabling their serialisation and deserialisation using Foundation's
/// property list mechanisms. This is essential for storing date and time
/// values in a format compatible with property lists.
extension NSDate: PropertyList {}
