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

class ViewController: UIViewController {
    
    let scnScene = SCNScene() // a 3D scene
    let leftView = SCNView() // view on the left side
    let rightView = SCNView() // view on the right side
    
    var width: CGFloat = 0.0 // width for each view
    var height: CGFloat = 0.0 // height for each view
    
    var boxGeometry = SCNBox() // a cube
    var boxNode = SCNNode() // node to attach the cube to
    
    var cylinderGeometry = SCNCylinder()
    var cylinderNode = SCNNode()
    
    // camera and node to attach the camera to for left and right view
    let leftCamera = SCNCamera()
    let leftCameraNode = SCNNode()
    let rightCamera = SCNCamera()
    let rightCameraNode = SCNNode()
    
    // a reflective floor and node for the floor
    let ground = SCNFloor()
    var groundNode = SCNNode()
    
    // motion manager instance
    let motionManager = CMMotionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add left and right view as subview of the main view
        self.view.addSubview(leftView)
        self.view.addSubview(rightView)
        setupScene()
        setupBox()
        setupCylinder()
        setupCamera()
        setupFloor()
        setupMotion()
    }
    override func viewDidLayoutSubviews() {
        
        //compute width and height for each view and assign for each
        width = self.view.frame.width/2.0
        height = self.view.frame.height
        let leftViewFrame = CGRect(x: 0, y: 0, width: width, height: height)
        let rightViewFrame = CGRect(x: width, y: 0, width: width, height: height)
        leftView.frame = leftViewFrame
        rightView.frame = rightViewFrame
    }
    
    //assign scene to each view
    func setupScene() {
        leftView.scene = scnScene
        rightView.scene = scnScene
    }
    
    // create a cube with different color on each face
    func setupBox() {
        boxGeometry = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0)
        boxGeometry.materials = [
            ColorMaterial.blueColor(),
            ColorMaterial.greenColor(),
            ColorMaterial.orangeColor(),
            ColorMaterial.purpleColor(),
            ColorMaterial.redColor(),
            ColorMaterial.yellowColor()
        ]
        boxNode = SCNNode(geometry: boxGeometry)
        scnScene.rootNode.addChildNode(boxNode)
    }
    
    func setupCylinder() {
        cylinderGeometry = SCNCylinder(radius: 0.4, height: 2)
        cylinderGeometry.materials = [
            ColorMaterial.blueColor(),
            ColorMaterial.greenColor(),
            ColorMaterial.purpleColor()
        ]
        cylinderNode = SCNNode(geometry: cylinderGeometry)
        cylinderNode.position = SCNVector3(3, 2, -2)
        scnScene.rootNode.addChildNode(cylinderNode)
    }
    
    
    // setup camera for each view
    func setupCamera() {
        leftCameraNode.camera = leftCamera
        leftCameraNode.position = SCNVector3(x: -0.5, y: 0, z: 5)
        rightCameraNode.camera = rightCamera
        rightCameraNode.position = SCNVector3(x: 0.5, y: 0, z: 5)
        scnScene.rootNode.addChildNode(leftCameraNode)
        scnScene.rootNode.addChildNode(rightCameraNode)
        leftView.pointOfView = leftCameraNode
        rightView.pointOfView = rightCameraNode
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
                //change the left camera node euler angle in x, y, z axis
                self.leftCameraNode.eulerAngles = SCNVector3(
                    -Float((self.motionManager.deviceMotion?.attitude.roll)!) - Float(M_PI_2),
                    Float((self.motionManager.deviceMotion?.attitude.yaw)!),
                    -Float((self.motionManager.deviceMotion?.attitude.pitch)!)
                )
                //change the right camera node euler angle in x, y, z axis
                self.rightCameraNode.eulerAngles = SCNVector3(
                    -Float((self.motionManager.deviceMotion?.attitude.roll)!) - Float(M_PI_2),
                    Float((self.motionManager.deviceMotion?.attitude.yaw)!),
                    -Float((self.motionManager.deviceMotion?.attitude.pitch)!)
                )
                
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
