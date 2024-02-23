//
//  EKViewConroller.swift
//  PKPFoundation
//
//  Created by David FU on 2024/2/5.
//

import Foundation

class EKViewController: UIViewController {
    
    class EKView: UIView {
        
        var isAbleToReceiveTouches: Bool = false
        
        weak var provider: EKViewControllerProvider?
        
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if isAbleToReceiveTouches {
                return super.hitTest(point, with: event)
            }
            
            guard let rootVC = provider?.rootVC else {
                return nil
            }
            
            if let view = rootVC.view.hitTest(point, with: event) {
                return view
            }
            
            return nil
        }
        
    }
    
    var isAbleToReceiveTouches = false {
        didSet {
            (self.view as! EKView).isAbleToReceiveTouches = isAbleToReceiveTouches
        }
    }
    
    let rootVC: UIViewController
    
    weak var provider: EKViewControllerProvider?
    
    init(with rootVC: UIViewController, provider: EKViewControllerProvider) {
        self.rootVC = rootVC
        self.provider = provider
        super.init(nibName: nil, bundle: nil)
        accessibilityViewIsModal = true
    }
    
    override func loadView() {
        super.loadView()
        let view = EKView()
        view.isAbleToReceiveTouches = isAbleToReceiveTouches
        view.provider = provider
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        addChild(rootVC)
        view.addSubview(rootVC.view)
        rootVC.didMove(toParent: self)
        rootVC.view.fillSuperview()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
