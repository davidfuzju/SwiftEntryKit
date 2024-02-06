//
//  EKViewConroller.swift
//  PKPFoundation
//
//  Created by David FU on 2024/2/5.
//

import Foundation

class EKViewController: UIViewController {
    
    var isAbleToReceiveTouches = false
    
    let rootVC: UIViewController
    
    init(with rootVC: UIViewController) {
        self.rootVC = rootVC
        super.init(nibName: nil, bundle: nil)
        accessibilityViewIsModal = true
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
    
//    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
//        if isAbleToReceiveTouches {
//            return super.hitTest(point, with: event)
//        }
//        
//        guard let rootVC = EKWindowProvider.shared.rootVC else {
//            return nil
//        }
//        
//        if let view = rootVC.view.hitTest(point, with: event) {
//            return view
//        }
//        
//        return nil
//    }
    
}
