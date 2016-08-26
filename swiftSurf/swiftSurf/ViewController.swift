//
//  ViewController.swift
//  swiftSurf
//
//  Created by Stanley Chiang on 8/25/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, CVWrapperDelegate {
    let wrapper = CVWrapper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        wrapper.delegate = self
        wrapper.initImages(self.view)
//        wrapper.initCamera(self.view)
    }
    
    func screenSize() -> CGRect {
        return UIScreen.mainScreen().bounds
    }
}

