//
//  ViewController.swift
//  constellation
//
//  Created by Stanley Chiang on 8/21/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, CVWrapperDelegate {
    let wrapper = CVWrapper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraSession()
        
    }

    func setupCameraSession() {
//        self.view.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        wrapper.setupVars()
        wrapper.startCamera(self.view)
    }
    
    func screenSize() -> CGRect {
        return UIScreen.mainScreen().bounds
    }
    
}

