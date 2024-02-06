//
//  SwiftEntryKit.swift
//  SwiftEntryKit
//
//  Created by Daniel Huri on 4/29/18.
//

import UIKit

extension UIApplication {
    
    static var WindowProviderKey = UnsafeRawPointer(bitPattern: "windowProvider".hashValue)!
    
    var windowProvider: EKWindowProvider {
        if let a = objc_getAssociatedObject(self, UIApplication.WindowProviderKey) as? EKWindowProvider {
            return a
        }
        
        let ret = EKWindowProvider.shared
        objc_setAssociatedObject(self, UIApplication.WindowProviderKey, ret, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return ret
    }
    
    public var entryWindow: UIWindow? {
        return windowProvider.entryWindow
    }
    
    public func isCurrentlyDisplaying(sender: UIViewController) -> Bool {
        return SwiftEntryKit.isCurrentlyDisplaying()
    }
    
    public func isCurrentlyDisplaying(entryNamed name: String? = nil) -> Bool {
        return SwiftEntryKit.isCurrentlyDisplaying(entryNamed: name)
    }
    
    public func display(entry view: UIView, using attributes: EKAttributes) {
        SwiftEntryKit.display(entry: view, using: attributes)
    }
    
    public func display(entry viewController: UIViewController, using attributes: EKAttributes) {
        SwiftEntryKit.display(entry: viewController, using: attributes)
    }
    
    public func dismiss(_ descriptor: SwiftEntryKit.EntryDismissalDescriptor = .displayed, with completion: SwiftEntryKit.DismissCompletionHandler? = nil) {
        SwiftEntryKit.dismiss(descriptor, with: completion)
    }
    
    public func queueContains(entryNamed name: String? = nil) -> Bool {
        SwiftEntryKit.queueContains(entryNamed: name)
    }
    
}

extension UIViewController {
    
    static var ViewControllerProviderKey = UnsafeRawPointer(bitPattern: "viewControllerProvider".hashValue)!
    
    var viewControllerProvider: EKViewControllerProvider {
        if let a = objc_getAssociatedObject(self, UIViewController.ViewControllerProviderKey) as? EKViewControllerProvider {
            return a
        }
        
        let ret = EKViewControllerProvider(with: self)
        objc_setAssociatedObject(self, UIViewController.ViewControllerProviderKey, ret, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return ret
    }
    
    public var entryViewController: UIViewController? {
        return viewControllerProvider.entryViewController
    }
    
    public func isCurrentlyDisplaying(sender: UIViewController) -> Bool {
        return SwiftEntryKit.isCurrentlyDisplaying(sender: sender)
    }
    
    public func isCurrentlyDisplaying(entryNamed name: String? = nil, sender: UIViewController) -> Bool {
        return SwiftEntryKit.isCurrentlyDisplaying(entryNamed: name, sender: sender)
    }
    
    public func display(entry view: UIView, using attributes: EKAttributes) {
        SwiftEntryKit.display(entry: view, sender: self, using: attributes)
    }
    
    public func display(entry viewController: UIViewController, using attributes: EKAttributes) {
        SwiftEntryKit.display(entry: viewController, sender: self, using: attributes)
    }
    
    public func dismiss(_ descriptor: SwiftEntryKit.EntryDismissalDescriptor = .displayed, with completion: SwiftEntryKit.DismissCompletionHandler? = nil) {
        SwiftEntryKit.dismiss(descriptor, sender: self, with: completion)
    }
    
    public func queueContains(entryNamed name: String? = nil) -> Bool {
        SwiftEntryKit.queueContains(entryNamed: name, sender: self)
    }

}

/**
 A stateless, threadsafe (unless described otherwise) entry point that contains the display and the dismissal logic of entries.
 */
public final class SwiftEntryKit {
    
    /** Describes the a single or multiple entries for possible dismissal states */
    public enum EntryDismissalDescriptor {
        
        /** Describes specific entry / entries with name */
        case specific(entryName: String)
        
        /** Describes a group of entries with lower or equal display priority */
        case prioritizedLowerOrEqualTo(priority: EKAttributes.Precedence.Priority)
        
        /** Describes all the entries that are currently in the queue and pending presentation */
        case enqueued
        
        /** Describes all the entries */
        case all
        
        /** Describes the currently displayed entry */
        case displayed
    }
    
    /** Completion handler for the dismissal method */
    public typealias DismissCompletionHandler = () -> Void
    
    /** Cannot be instantiated, customized, inherited. */
    private init() {}

}

/// for view controller
extension SwiftEntryKit {
    
    /**
     Returns true if **any** entry is currently displayed.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - Convenience computed variable. Using it is the same as invoking **isCurrentlyDisplaying() -> Bool** (witohut the name of the entry).
     */
    public class func isCurrentlyDisplaying(sender: UIViewController) -> Bool {
        return isCurrentlyDisplaying(entryNamed: nil, sender: sender)
    }
    
    /**
     Returns true if an entry with a given name is currently displayed.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - If invoked with *name* = *nil* or without the parameter value, it will return *true* if **any** entry is currently displayed.
     - Returns a *false* value for currently enqueued entries.
     - parameter name: The name of the entry. Its default value is *nil*.
     */
    public class func isCurrentlyDisplaying(entryNamed name: String? = nil, sender: UIViewController) -> Bool {
        return sender.viewControllerProvider.isCurrentlyDisplaying(entryNamed: name)
    }
    
    /**
     Returns true if **any** entry is currently enqueued and waiting to be displayed.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - Convenience computed variable. Using it is the same as invoking **~queueContains() -> Bool** (witohut the name of the entry)
     */
    public class func isQueueEmpty(sender: UIViewController) -> Bool {
        return !sender.viewControllerProvider.queueContains()
    }
    
    /**
     Returns true if an entry with a given name is currently enqueued and waiting to be displayed.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - If invoked with *name* = *nil* or without the parameter value, it will return *true* if **any** entry is currently displayed, meaning, the queue is not currently empty.
     - parameter name: The name of the entry. Its default value is *nil*.
     */
    public class func queueContains(entryNamed name: String? = nil, sender: UIViewController) -> Bool {
        return sender.viewControllerProvider.queueContains(entryNamed: name)
    }
    
    /**
     Displays a given entry view using an attributes struct.
     - A thread-safe method - Can be invokes from any thread
     - A class method - Should be called on the class
     - parameter view: Custom view that is to be displayed
     - parameter attributes: Display properties
     - parameter presentInsideKeyWindow: Indicates whether the entry window should become the key window.
     - parameter rollbackWindow: After the entry has been dismissed, SwiftEntryKit rolls back to the given window. By default it is *.main* which is the app main window
     */
    public class func display(entry view: UIView, sender: UIViewController, using attributes: EKAttributes) {
        DispatchQueue.main.async {
            sender.viewControllerProvider.display(view: view, using: attributes)
        }
    }
    
    /**
     Displays a given entry view controller using an attributes struct.
     - A thread-safe method - Can be invokes from any thread
     - A class method - Should be called on the class
     - parameter view: Custom view that is to be displayed
     - parameter attributes: Display properties
     - parameter presentInsideKeyWindow: Indicates whether the entry window should become the key window.
     - parameter rollbackWindow: After the entry has been dismissed, SwiftEntryKit rolls back to the given window. By default it is *.main* - which is the app main window
     */
    public class func display(entry viewController: UIViewController, sender: UIViewController, using attributes: EKAttributes) {
        DispatchQueue.main.async {
            sender.viewControllerProvider.display(viewController: viewController, using: attributes)
        }
    }
    
    /**
     Dismisses the currently presented entry and removes the presented window instance after the exit animation is concluded.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     - parameter descriptor: A descriptor for the entries that are to be dismissed. The default value is *.displayed*.
     - parameter completion: A completion handler that is to be called right after the entry is dismissed (After the animation is concluded).
     */
    public class func dismiss(_ descriptor: EntryDismissalDescriptor = .displayed, sender: UIViewController, with completion: SwiftEntryKit.DismissCompletionHandler? = nil) {
        DispatchQueue.main.async {
            sender.viewControllerProvider.dismiss(descriptor, with: completion)
        }
    }
    
    /**
     Layout the view hierarchy that is rooted in the window.
     - In case you use complex animations, you can call it to refresh the AutoLayout mechanism on the entire view hierarchy.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     */
    public class func layoutIfNeeded(sender: UIViewController) {
        if Thread.isMainThread {
            sender.viewControllerProvider.layoutIfNeeded()
        } else {
            DispatchQueue.main.async {
                sender.viewControllerProvider.layoutIfNeeded()
            }
        }
    }
    
}

/// for window
extension SwiftEntryKit {
    
    /** The window to rollback to after dismissal */
    public enum RollbackWindow {
        
        /** The main window */
        case main
        
        /** A given custom window */
        case custom(window: UIWindow)
    }
    
    /**
     Returns true if **any** entry is currently displayed.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - Convenience computed variable. Using it is the same as invoking **isCurrentlyDisplaying() -> Bool** (witohut the name of the entry).
     */
    public class func isCurrentlyDisplaying() -> Bool {
        return isCurrentlyDisplaying(entryNamed: nil)
    }
    
    /**
     Returns true if an entry with a given name is currently displayed.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - If invoked with *name* = *nil* or without the parameter value, it will return *true* if **any** entry is currently displayed.
     - Returns a *false* value for currently enqueued entries.
     - parameter name: The name of the entry. Its default value is *nil*.
     */
    public class func isCurrentlyDisplaying(entryNamed name: String? = nil) -> Bool {
        return EKWindowProvider.shared.isCurrentlyDisplaying(entryNamed: name)
    }
    
    /**
     Returns true if **any** entry is currently enqueued and waiting to be displayed.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - Convenience computed variable. Using it is the same as invoking **~queueContains() -> Bool** (witohut the name of the entry)
     */
    public class func isQueueEmpty() -> Bool {
        return !queueContains()
    }
    
    /**
     Returns true if an entry with a given name is currently enqueued and waiting to be displayed.
     - Not thread safe - should be called from the main queue only in order to receive a reliable result.
     - If invoked with *name* = *nil* or without the parameter value, it will return *true* if **any** entry is currently displayed, meaning, the queue is not currently empty.
     - parameter name: The name of the entry. Its default value is *nil*.
     */
    public class func queueContains(entryNamed name: String? = nil) -> Bool {
        return EKWindowProvider.shared.queueContains(entryNamed: name)
    }
    
    /**
     Displays a given entry view using an attributes struct.
     - A thread-safe method - Can be invokes from any thread
     - A class method - Should be called on the class
     - parameter view: Custom view that is to be displayed
     - parameter attributes: Display properties
     - parameter presentInsideKeyWindow: Indicates whether the entry window should become the key window.
     - parameter rollbackWindow: After the entry has been dismissed, SwiftEntryKit rolls back to the given window. By default it is *.main* which is the app main window
     */
    public class func display(entry view: UIView, using attributes: EKAttributes, presentInsideKeyWindow: Bool = false, rollbackWindow: RollbackWindow = .main) {
        DispatchQueue.main.async {
            EKWindowProvider.shared.display(view: view, using: attributes, presentInsideKeyWindow: presentInsideKeyWindow, rollbackWindow: rollbackWindow)
        }
    }
    
    /**
     Displays a given entry view controller using an attributes struct.
     - A thread-safe method - Can be invokes from any thread
     - A class method - Should be called on the class
     - parameter view: Custom view that is to be displayed
     - parameter attributes: Display properties
     - parameter presentInsideKeyWindow: Indicates whether the entry window should become the key window.
     - parameter rollbackWindow: After the entry has been dismissed, SwiftEntryKit rolls back to the given window. By default it is *.main* - which is the app main window
     */
    public class func display(entry viewController: UIViewController, using attributes: EKAttributes, presentInsideKeyWindow: Bool = false, rollbackWindow: RollbackWindow = .main) {
        DispatchQueue.main.async {
            EKWindowProvider.shared.display(viewController: viewController, using: attributes, presentInsideKeyWindow: presentInsideKeyWindow, rollbackWindow: rollbackWindow)
        }
    }
    
    /**
     ALPHA FEATURE: Transform the previous entry to the current one using the previous attributes struct.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     - This feature hasn't been fully tested. Use with caution.
     - parameter view: Custom view that is to be displayed instead of the currently displayed entry
     */
    public class func transform(to view: UIView) {
        DispatchQueue.main.async {
            EKWindowProvider.shared.transform(to: view)
        }
    }
    
    /**
     Dismisses the currently presented entry and removes the presented window instance after the exit animation is concluded.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     - parameter descriptor: A descriptor for the entries that are to be dismissed. The default value is *.displayed*.
     - parameter completion: A completion handler that is to be called right after the entry is dismissed (After the animation is concluded).
     */
    public class func dismiss(_ descriptor: EntryDismissalDescriptor = .displayed, with completion: DismissCompletionHandler? = nil) {
        DispatchQueue.main.async {
            EKWindowProvider.shared.dismiss(descriptor, with: completion)
        }
    }
    
    /**
     Layout the view hierarchy that is rooted in the window.
     - In case you use complex animations, you can call it to refresh the AutoLayout mechanism on the entire view hierarchy.
     - A thread-safe method - Can be invoked from any thread.
     - A class method - Should be called on the class.
     */
    public class func layoutIfNeeded() {
        if Thread.isMainThread {
            EKWindowProvider.shared.layoutIfNeeded()
        } else {
            DispatchQueue.main.async {
                EKWindowProvider.shared.layoutIfNeeded()
            }
        }
    }
}
