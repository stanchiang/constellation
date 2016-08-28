//
//  ViewController.swift
//  swiftingIn3D
//
//  Created by Stanley Chiang on 8/27/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var renderer:Renderer!
    var metalView:MetalView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        renderer = Renderer()
        metalView = MetalView(frame: self.view.frame, device: renderer.device)
        self.metalView.delegate = self.renderer
        self.view.addSubview(metalView)
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

}

