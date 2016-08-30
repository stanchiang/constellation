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

class VRViewController: UIViewController, UIGestureRecognizerDelegate, SCNSceneRendererDelegate {
    
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
    
    // gesture recognizers
    var walkGesture: UIPanGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add view as subview of the main view
        self.view.addSubview(scnView)
        setupScene()
        addTestCubes()
        setupCamera()
        setupFloor()
        setupMotion()
        
        addGestures()
    }
    override func viewDidLayoutSubviews() {
        scnView.frame = self.view.frame
    }
    
    //assign scene to each view
    func setupScene() {
        scnView.scene = scnScene
        scnView.delegate = self
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
        if motionManager.deviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue(), withHandler: deviceDidMove)
        }
    }
    
    func deviceDidMove(motion: CMDeviceMotion?, error: NSError?) {
        if let motion = motion {
            CameraNode.orientation = motion.gaze(atOrientation: UIApplication.sharedApplication().statusBarOrientation)
        }
    }
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval) {
        //get walk gesture translation
        let translation = walkGesture.translationInView(self.view)
        
        //create impulse vector for hero
        let angle = CameraNode.rotation.w * CameraNode.rotation.y
        let impulse = SCNVector3(x: max(-1, min(1, Float(translation.x) / 50)), y: 0, z: max(-1, min(1, Float(-translation.y) / 50)))
        
        let xVec = impulse.x * cos(angle) - impulse.z * sin(angle)
        let zVec = impulse.x * -sin(angle) - impulse.z * cos(angle)
        
        CameraNode.position = SCNVector3(CameraNode.position.x - xVec/5, CameraNode.position.y, CameraNode.position.z - zVec/5)
    }
    
    
    //Gesture Recognizers
    func addGestures() {
        
        //walk gesture
        walkGesture = UIPanGestureRecognizer(target: self, action: #selector(VRViewController.walkGestureRecognized(_:)))
        walkGesture.delegate = self
        view.addGestureRecognizer(walkGesture)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        if gestureRecognizer == walkGesture {
            return touch.locationInView(view).x < view.frame.size.width / 2
        }
        
        return true
    }
    
    func walkGestureRecognized(gesture: UIPanGestureRecognizer) {
        
        if gesture.state == UIGestureRecognizerState.Ended || gesture.state == UIGestureRecognizerState.Cancelled {
            gesture.setTranslation(CGPointZero, inView: self.view)
        }
    }
}

