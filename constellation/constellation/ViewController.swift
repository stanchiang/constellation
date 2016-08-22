//
//  ViewController.swift
//  constellation
//
//  Created by Stanley Chiang on 8/21/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    let wrapper = CVWrapper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraSession()
        
    }

    func setupCameraSession() {
        wrapper.startCamera(self.view)
    }
    
}

