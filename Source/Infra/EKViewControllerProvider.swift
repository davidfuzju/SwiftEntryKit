//
//  EKViewControllerProvider.swift
//  SwiftEntryKit
//
//  Created by Daniel Huri on 4/19/18.
//  Copyright (c) 2018 huri000@gmail.com. All rights reserved.
//

import UIKit

final class EKViewControllerProvider: EntryPresenterDelegate, EKProvider {
    
    /** The artificial safe area insets */
    var safeAreaInsets: UIEdgeInsets {
        return self.entryViewController?.view?.safeAreaInsets ?? UIApplication.shared.keyWindow?.rootViewController?.view.safeAreaInsets ?? .zero
    }
    
    weak var sender: UIViewController?
    
    /** Current entry view controller */
    var entryViewController: EKViewController?
    
    /** Returns the root view controller if it is instantiated */
    var rootVC: EKRootViewController? {
        return entryViewController?.children.filter { $0 is EKRootViewController }.first as? EKRootViewController
    }

    /** Entry queueing heuristic  */
    private let entryQueue = EKAttributes.Precedence.QueueingHeuristic.value.heuristic
    
    private weak var entryView: EKEntryView!

    /** Cannot be instantiated, customized, inherited */
    init(with sender: UIViewController) {
        self.sender = sender
    }
    
    var isResponsiveToTouches: Bool {
        set {
            entryViewController?.isAbleToReceiveTouches = newValue
        }
        get {
            return entryViewController?.isAbleToReceiveTouches ?? false
        }
    }
    
    // MARK: - Setup and Teardown methods
    
    // Prepare the window and the host view controller
    private func prepare(for attributes: EKAttributes) -> EKRootViewController? {
        let entryVC = setupViewControllerAndRootVC()
        guard entryVC.canDisplay(attributes: attributes) || attributes.precedence.isEnqueue else {
            return nil
        }
        
        if let sender = sender, let entryViewController = entryViewController  {
            sender.addChild(entryViewController)
            sender.view.addSubview(entryViewController.view)
            entryViewController.didMove(toParent: sender)
            entryViewController.view.fillSuperview()
        }
        
        entryVC.setStatusBarStyle(for: attributes)
        return entryVC
    }
    
    /** Boilerplate generic setup for entry-viewcontroller and root-view-controller  */
    private func setupViewControllerAndRootVC() -> EKRootViewController {
        let entryVC: EKRootViewController
        if entryViewController == nil {
            entryVC = EKRootViewController(with: self)
            entryViewController = EKViewController(with: entryVC, provider: self)
        } else {
            entryVC = rootVC!
        }
        return entryVC
    }
    
    /**
     Privately used to display an entry
     */
    private func display(entryView: EKEntryView, using attributes: EKAttributes) {
        switch entryView.attributes.precedence {
        case .override(priority: _, dropEnqueuedEntries: let dropEnqueuedEntries):
            if dropEnqueuedEntries {
                entryQueue.removeAll()
            }
            show(entryView: entryView)
        case .enqueue where isCurrentlyDisplaying():
            entryQueue.enqueue(entry: .init(view: entryView, presentInsideKeyWindow: nil, rollbackWindow: nil))
        case .enqueue:
            show(entryView: entryView)
        }
    }
    
    // MARK: - Exposed Actions
    
    func queueContains(entryNamed name: String? = nil) -> Bool {
        if name == nil && !entryQueue.isEmpty {
            return true
        }
        if let name = name {
            return entryQueue.contains(entryNamed: name)
        } else {
            return false
        }
    }
    
    /**
     Returns *true* if the currently displayed entry has the given name.
     In case *name* has the value of *nil*, the result is *true* if any entry is currently displayed.
     */
    func isCurrentlyDisplaying(entryNamed name: String? = nil) -> Bool {
        guard let entryView = entryView else {
            return false
        }
        if let name = name { // Test for names equality
            return entryView.content.attributes.name == name
        } else { // Return true by default if the name is *nil*
            return true
        }
    }
    
    /** Display a view using attributes */
    
    func display(view: UIView, using attributes: EKAttributes) {
        let entryView = EKEntryView(newEntry: .init(provider: self, view: view, attributes: attributes))
        display(entryView: entryView, using: attributes)
    }

    /** Display a view controller using attributes */
    func display(viewController: UIViewController, using attributes: EKAttributes) {
        let entryView = EKEntryView(newEntry: .init(provider: self, viewController: viewController, attributes: attributes))
        display(entryView: entryView, using: attributes)
    }
    
    /** Clear all entries immediately and display to the rollback window */
    func displayRollbackWindow() {
        if let entryViewController = entryViewController, let _ = entryViewController.parent {
            entryViewController.willMove(toParent: nil)
            entryViewController.removeFromParent()
            entryViewController.view.removeFromSuperview()
        }
            
        entryViewController = nil
        entryView = nil
    }
    
    /** Display a pending entry if there is any inside the queue */
    func displayPendingEntryOrRollbackWindow(dismissCompletionHandler: SwiftEntryKit.DismissCompletionHandler?) {
        if let next = entryQueue.dequeue() {
            
            // Execute dismiss handler if needed before dequeuing (potentially) another entry
            dismissCompletionHandler?()
            
            // Show the next entry in queue
            show(entryView: next.view)
        } else {
            
            // Display the rollback window
            displayRollbackWindow()
            
            // As a last step, invoke the dismissal method
            dismissCompletionHandler?()
        }
    }
    
    /** Dismiss entries according to a given descriptor */
    func dismiss(_ descriptor: SwiftEntryKit.EntryDismissalDescriptor, with completion: SwiftEntryKit.DismissCompletionHandler? = nil) {
        guard let rootVC = rootVC else {
            return
        }
        
        switch descriptor {
        case .displayed:
            rootVC.animateOutLastEntry(completionHandler: completion)
        case .specific(entryName: let name):
            entryQueue.removeEntries(by: name)
            if entryView?.attributes.name == name {
                rootVC.animateOutLastEntry(completionHandler: completion)
            }
        case .prioritizedLowerOrEqualTo(priority: let priorityThreshold):
            entryQueue.removeEntries(withPriorityLowerOrEqualTo: priorityThreshold)
            if let currentPriority = entryView?.attributes.precedence.priority, currentPriority <= priorityThreshold {
                rootVC.animateOutLastEntry(completionHandler: completion)
            }
        case .enqueued:
            entryQueue.removeAll()
        case .all:
            entryQueue.removeAll()
            rootVC.animateOutLastEntry(completionHandler: completion)
        }
    }
    
    /** Layout the view-hierarchy rooted in the window */
    func layoutIfNeeded() {
        entryViewController?.view.layoutIfNeeded()
    }
    
    /** Privately used to prepare the root view controller and show the entry immediately */
    private func show(entryView: EKEntryView) {
        guard let entryVC = prepare(for: entryView.attributes) else {
            return
        }
        entryVC.configure(entryView: entryView)
        self.entryView = entryView
    }
}
