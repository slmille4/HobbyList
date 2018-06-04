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
    
    init(_ build: @escaping(@escaping(A) -> ()) -> UIViewController) {
        self.build = build
    }
    
    public func run(f: @escaping (A) -> ()) -> UIViewController {
        let vc = build(f)
        return vc
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
