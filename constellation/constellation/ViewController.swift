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
    let button = UIButton()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraSession()
        addCameraCaptureButton()
    }
    
    func setupCameraSession() {
        wrapper.setupVars()
        wrapper.startCamera(self.view)
    }
    
    func addCameraCaptureButton(){
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(captureImage(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(button)
    }
    
    func captureImage(sender: UIButton){
        print("detect and track this frame")
        AudioServicesPlaySystemSound(1108)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        wrapper.trackThisFrame()
    }
    
    override func viewWillLayoutSubviews() {
        button.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor, constant: -30).active = true
        button.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor).active = true
        button.heightAnchor.constraintEqualToConstant(60).active = true
        button.widthAnchor.constraintEqualToAnchor(button.heightAnchor).active = true
        
    }
    
    override func viewDidLayoutSubviews() {
        button.layer.cornerRadius = button.frame.width / 2
        button.backgroundColor = UIColor.clearColor()
        button.layer.borderColor = UIColor.cyanColor().CGColor
        button.layer.borderWidth = 5
    }
    
    func screenSize() -> CGRect {
        return UIScreen.mainScreen().bounds
    }
    
}

