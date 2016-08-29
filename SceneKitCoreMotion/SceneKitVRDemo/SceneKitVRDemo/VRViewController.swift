//
//  ViewController.swift
//  SceneKitVRDemo
//
//  Created by Sujan Vaidya on 8/9/16.
//  Copyright © 2016 Sujan Vaidya. All rights reserved.
//

import UIKit
import SceneKit // for 3D view
import CoreMotion // for tracking device motion

class VRViewController: UIViewController {
    
    let scnScene = SCNScene() // a 3D scene
    let scnView = SCNView()
    
    // camera and node to which the camera is attached
    let Camera = SCNCamera()
    let CameraNode = SCNNode()
    
    // a reflective floor and node for the floor
    let ground = SCNFloor()
    var groundNode = SCNNode()
    
    // motion manager instance
    let motionManager = CMMotionManager()
    
    let forwardButton = UIButton()
    let backwardButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add view as subview of the main view
        self.view.addSubview(scnView)
        setupScene()
        addTestCubes()
        setupCamera()
        setupFloor()
        setupMotion()
        
        addButtons()
    }
    override func viewDidLayoutSubviews() {
        scnView.frame = self.view.frame
        
        forwardButton.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        forwardButton.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor).active = true
        forwardButton.widthAnchor.constraintEqualToConstant(100).active = true
        forwardButton.heightAnchor.constraintEqualToAnchor(forwardButton.widthAnchor).active = true
        
        backwardButton.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        backwardButton.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor).active = true
        backwardButton.widthAnchor.constraintEqualToConstant(100).active = true
        backwardButton.heightAnchor.constraintEqualToAnchor(backwardButton.widthAnchor).active = true
        
    }
    
    func addButtons(){
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.addTarget(self, action: #selector(forwardAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        forwardButton.backgroundColor = UIColor.greenColor()
        forwardButton.setTitle("forward", forState: UIControlState.Normal)
        view.addSubview(forwardButton)
        
        
        backwardButton.translatesAutoresizingMaskIntoConstraints = false
        backwardButton.addTarget(self, action: #selector(backwardAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        backwardButton.backgroundColor = UIColor.redColor()
        backwardButton.setTitle("backward", forState: UIControlState.Normal)
        view.addSubview(backwardButton)

    }
    
    func forwardAction(sender: UIButton) {
        print("willMoveForward")
        CameraNode.position = SCNVector3(CameraNode.position.x, CameraNode.position.y, CameraNode.position.z-1)
    }
    
    func backwardAction(sender: UIButton) {
        print("willMoveBackward")
        CameraNode.position = SCNVector3(CameraNode.position.x, CameraNode.position.y, CameraNode.position.z+1)
    }
    
    //assign scene to each view
    func setupScene() {
        scnView.scene = scnScene
    }
    
    func addTestCubes(){
        setupCube(0, y: 0, z: 0, color: ColorMaterial.blueColor())
        
        setupCube(1, y: 0, z: 0, color: ColorMaterial.greenColor())
        setupCube(-1, y: 0, z: 0, color: ColorMaterial.cyanColor())
        
        setupCube(0, y: 1, z: 0, color: ColorMaterial.orangeColor())
        setupCube(0, y: -1, z: 0, color: ColorMaterial.redColor())
        
        setupCube(0, y: 0, z: 1, color: ColorMaterial.purpleColor())
        setupCube(0, y: 0, z: -1, color: ColorMaterial.brownColor())
    }
    
    func setupCube(x:Int, y:Int, z:Int, color:SCNMaterial){
        let cubeGeometry = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0)
        cubeGeometry.materials = [color]
        let cubeNode = SCNNode(geometry: cubeGeometry)
        cubeNode.position = SCNVector3(x, y, z)
        scnScene.rootNode.addChildNode(cubeNode)
    }
    
    // setup camera
    func setupCamera() {
        CameraNode.camera = Camera
        CameraNode.position = SCNVector3(x: -0.5, y: 2, z: 5)
        scnScene.rootNode.addChildNode(CameraNode)
        scnView.pointOfView = CameraNode
    }
    
    // setup reflective floor
    func setupFloor() {
        ground.reflectivity = 0.05
        ground.materials = [ColorMaterial.magentaColor()]
        groundNode.geometry = ground
        groundNode.position = SCNVector3(x: 0, y: -1, z: 0)
        scnScene.rootNode.addChildNode(groundNode)
    }
    
    func setupMotion() {
        // time for motion update
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        if motionManager.deviceMotionAvailable {
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: { (devMotion, error) -> Void in
                //change the  camera node euler angle in x, y, z axis
                self.CameraNode.eulerAngles = SCNVector3(
                    -Float((self.motionManager.deviceMotion?.attitude.roll)!) - Float(M_PI_2),
                    Float((self.motionManager.deviceMotion?.attitude.yaw)!),
                    -Float((self.motionManager.deviceMotion?.attitude.pitch)!)
                )
            })
        }
    }
}
