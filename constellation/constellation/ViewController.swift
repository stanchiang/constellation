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
    var imageBuffer:CVImageBufferRef!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCameraSession()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        view.layer.addSublayer(previewLayer)
        
        cameraSession.startRunning()
    }
    
    lazy var cameraSession: AVCaptureSession = {
        let s = AVCaptureSession()
        s.sessionPreset = AVCaptureSessionPreset1280x720
        return s
    }()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let preview =  AVCaptureVideoPreviewLayer(session: self.cameraSession)
        preview.frame = self.view.frame
        return preview
    }()
    
    func setupCameraSession() {
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) as AVCaptureDevice
        
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice)
        
        cameraSession.beginConfiguration()
        
        if (cameraSession.canAddInput(deviceInput) == true) {
            cameraSession.addInput(deviceInput)
        }
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = nil
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if (cameraSession.canAddOutput(dataOutput) == true) {
            cameraSession.addOutput(dataOutput)
        }
        
        cameraSession.commitConfiguration()
        
        let queue = dispatch_queue_create("com.stan.constellation", DISPATCH_QUEUE_SERIAL)
        dataOutput.setSampleBufferDelegate(self, queue: queue)
        
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        print("about to call process image buffer")
        CVWrapper.processImageBuffer(imageBuffer)
        
    }
    
}

