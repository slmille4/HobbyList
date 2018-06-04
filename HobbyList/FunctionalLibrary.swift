//
//  FunctionalLibrary.swift
//  Hierophant
//
//  Created by Steve on 12/1/17.
//  Copyright © 2017 Steve. All rights reserved.
//

import UIKit

public struct Screen<A> {
    private let build: (_ f: @escaping(A) -> ()) -> UIViewController
//    public var navigationItem: NavigationItem
    
    init(_ build: @escaping(@escaping(A) -> ()) -> UIViewController) {
        self.build = build
    }
    
    public func run(f: @escaping (A) -> ()) -> UIViewController {
        let vc = build(f)
//        vc.applyNavigationItem(navigationItem: navigationItem)
        return vc
    }
}

public struct NavigationController<A> {
    public let build: (@escaping (A, UINavigationController) -> Void) -> UINavigationController
    
    /*public init(_ build: @escaping ((A, UINavigationController) -> Void) -> UINavigationController) {
        self.build = build
        //        navigationItem = defaultNavigationItem
    }*/
    
    public func run() -> UINavigationController {
        return build { _,_  in }
    }
}

extension UINavigationController {
    public func pushScreen<A>(screen:Screen<A>,callback: @escaping (A) -> ())
    {
        let rvc = screen.run { [unowned self] x in
            callback(x)
            self.popViewController(animated: true)
        }
        self.pushViewController(rvc, animated: true)
    }
}

//extension UIViewController {
//    public func presentModal<A>(screen: NavigationController<A>, /*cancellable: Bool, */callback: @escaping (A) -> ()) {
//        let vc = screen.build { [unowned self] x, nc in
//            callback(x)
//            self.dismiss(animated: true, completion: nil)
//        }
//        vc.modalTransitionStyle = UIModalTransitionStyle.coverVertical
////        if cancellable {
////            let cancelButton = BarButton(title: BarButtonTitle.SystemItem(UIBarButtonSystemItem.cancel), callback: { _ in
////                self.dismiss(animated: true, completion: nil)
////            })
////            let rootVC = vc.viewControllers[0] as UIViewController
////            rootVC.setLeftBarButton(barButton: cancelButton)
////        }
//        present(vc, animated: true, completion: nil)
//    }
//}
