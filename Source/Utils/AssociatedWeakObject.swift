//
//  AssociateWeak.swift
//  SwiftEntryKit
//
//  Created by David FU on 2024/2/29.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation

/// objc_getAssociatedObject's OBJC_ASSOCIATION_WEAK version
/// - Parameters:
///   - object: object
///   - key: key
/// - Returns: value
func objc_getAssociatedWeakObject(_ object: AnyObject, _ key: UnsafeRawPointer) -> AnyObject? {
    let block: (() -> AnyObject?)? = objc_getAssociatedObject(object, key) as? (() -> AnyObject?)
    return block != nil ? block?() : nil
}

/// objc_setAssociatedObject's OBJC_ASSOCIATION_WEAK version
/// - Parameters:
///   - object: object
///   - key: key
///   - value: value
func objc_setAssociatedWeakObject(_ object: AnyObject, _ key: UnsafeRawPointer, _ value: AnyObject?) {
    weak var weakValue = value
    let block: (() -> AnyObject?)? = {
        return weakValue
    }
    objc_setAssociatedObject(object, key, block, .OBJC_ASSOCIATION_COPY)
}
