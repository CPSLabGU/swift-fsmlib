//
//  PropertyList.swift
//
//  Created by Rene Hexel on 13/10/2018.
//  Copyright © 2018, 2019, 2023 Rene Hexel. All rights reserved.
//
import Foundation

/// Abstract type that is suitable for property list serialisation
public protocol PropertyList {}

extension NSArray: PropertyList {}
extension NSDictionary: PropertyList {}
extension NSString: PropertyList {}
extension NSNumber: PropertyList {}
extension NSData: PropertyList {}
extension NSDate: PropertyList {}
