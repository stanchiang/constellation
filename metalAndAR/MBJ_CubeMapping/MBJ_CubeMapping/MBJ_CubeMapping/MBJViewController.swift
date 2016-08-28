//
//  MBEViewController.m
//  MetalCubeMapping
//
//  Created by Warren Moore on 11/7/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//------------------------------------------------------------------------
//  converted to Swift by Jamnitzer (Jim Wrenholt)
//------------------------------------------------------------------------
import Foundation
import UIKit
import CoreMotion
import Metal
import simd

//------------------------------------------------------------------------------
class MBJViewController: UIViewController
{
    var renderer:MBJRenderer! = nil
    var displayLink:CADisplayLink! = nil
    var motionManager:CMMotionManager! = nil
    
    //------------------------------------------------------------------------
    func metalView() -> MBJMetalView?
    {
        return self.view as? MBJMetalView
    }
    //------------------------------------------------------------------------
    override func viewDidLoad()
    {
        super.viewDidLoad()
        if let myView = self.view as? MBJMetalView
        {
            let metal_layer:CAMetalLayer = myView.metalLayer
           self.renderer = MBJRenderer(layer:metal_layer)
        }
    }
    //------------------------------------------------------------------------
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
       
        self.displayLink = CADisplayLink(target: self, selector: Selector("displayLinkDidFire:"))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)

        self.motionManager = CMMotionManager()
        if (self.motionManager.deviceMotionAvailable)
        {
           self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
           
//   let frame:CMAttitudeReferenceFrame = CMAttitudeReferenceFrame.XTrueNorthZVertical
//   self.motionManager.startDeviceMotionUpdatesUsingReferenceFrame(frame)
            self.motionManager.startDeviceMotionUpdates()
        }

        let tapRecognizer = UITapGestureRecognizer(target: self, action: "tap:")
        self.view.addGestureRecognizer(tapRecognizer)
    }
    //------------------------------------------------------------------------
    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }
    //------------------------------------------------------------------------
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
    {
        return .Portrait
    }
    //------------------------------------------------------------------------
    func tap(recognize: UITapGestureRecognizer)
    {
       self.renderer.useRefractionMaterial = !self.renderer.useRefractionMaterial
    }
    //------------------------------------------------------------------------
    func updateDeviceOrientation()
    {
        if (self.motionManager.deviceMotionAvailable)
        {
           //  print("_  ", terminator:"")
           //  self.renderer.sceneOrientation = translation(float4(0.0, -5.0, 0.0, 0.0))
           //  self.renderer.sceneOrientation = identity()
            
//            if (self.motionManager.deviceMotionActive)
//            {
//                print("deviceMotionActive")
//            }
           // self.motionManager.startDeviceMotionUpdates()
           
            if let motion:CMDeviceMotion = self.motionManager.deviceMotion
            {
//                let aat:CMAttitude = motion.attitude
// //             let aam:CMRotationMatrix = aat.rotationMatrix
//                print("m.roll = \(aat.roll)")
//                print("m.pitch = \(aat.pitch)")
//                print("m.yaw = \(aat.yaw)")

               //assert(false)
                let m:CMRotationMatrix = motion.attitude.rotationMatrix
                //------------------------------------------------------------------------
                // permute rotation matrix from Core Motion to get scene orientation
                //------------------------------------------------------------------------
                let X = float4( Float(m.m12), Float(m.m22), Float(m.m32), 0.0 )
                let Y = float4( Float(m.m13), Float(m.m23), Float(m.m33), 0.0  )
                let Z = float4( Float(m.m11), Float(m.m21), Float(m.m31), 0.0 )
                let W = float4( 0.0,  0.0, 0.0, 1.0  )
                let orientation = float4x4([ X, Y, Z, W ])
                
                self.renderer.sceneOrientation = orientation
                //-----------------------------------------------
                //    if (m.m12 != 0.0) { print("m.m12 = \(m.m12)") }
                //    if (m.m22 != 0.0) { print("m.m22 = \(m.m22)") }
                //    if (m.m32 != 0.0) { print("m.m32 = \(m.m32)") }
                //    //-----------------------------------------------
                //    if (m.m13 != 0.0) { print("m.m13 = \(m.m13)") }
                //    if (m.m23 != 0.0) { print("m.m23 = \(m.m23)") }
                //    if (m.m33 != 0.0) { print("m.m33 = \(m.m33)") }
                //    //-----------------------------------------------
                //    if (m.m11 != 0.0) { print("m.m11 = \(m.m11)") }
                //    if (m.m21 != 0.0) { print("m.m21 = \(m.m21)") }
                //    if (m.m31 != 0.0) { print("m.m31 = \(m.m31)") }
                //-----------------------------------------------
            }
        }
    }
    //------------------------------------------------------------------------
    func displayLinkDidFire(sender:CADisplayLink)
    {
        updateDeviceOrientation()
        redraw()
   }
    //------------------------------------------------------------------------
    func redraw()
    {
        self.renderer.draw()
    }
    //------------------------------------------------------------------------
}
