//
//  ViewController.swift
//  LiveCameraFiltering
//
//  Created by Simon Gladman on 05/07/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//
// Thanks to: http://www.objc.io/issues/21-camera-and-photos/camera-capture-on-ios/
// Thanks to: http://mczonk.de/video-texture-streaming-with-metal/
// Thanks to: http://stackoverflow.com/questions/31147744/converting-cmsamplebuffer-to-cvmetaltexture-in-swift-with-cvmetaltexturecachecre/31242539

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate
{
    let metalView = VideoMetalView(frame: CGRectZero)
    let blurSlider = UISlider(frame: CGRectZero)
    
    var device:MTLDevice!
    
    var videoTextureCache : Unmanaged<CVMetalTextureCacheRef>?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        do
        {
            let input = try AVCaptureDeviceInput(device: backCamera)
            
            captureSession.addInput(input)
        }
        catch
        {
            print("can't access camera")
            return
        }
        
        // although we don't use this, it's required to get captureOutput invoked
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        
        let videoOutput = AVCaptureVideoDataOutput()

        videoOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))
        if captureSession.canAddOutput(videoOutput)
        {
            captureSession.addOutput(videoOutput)
        }
  
        setUpMetal()
        
        view.addSubview(metalView)
        view.addSubview(blurSlider)
        
        blurSlider.addTarget(self, action: #selector(ViewController.sliderChangeHandler), forControlEvents: UIControlEvents.ValueChanged)
        blurSlider.maximumValue = 50
        
        captureSession.startRunning()
    }
    
    private func setUpMetal()
    {
        guard let device = MTLCreateSystemDefaultDevice() else
        {
            return
        }
        
        self.device = device
        
        metalView.framebufferOnly = false

        // Texture for Y
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &videoTextureCache)
        
        // Texture for CbCr
    
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &videoTextureCache)
    }
  
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!)
    {
        connection.videoOrientation = .Portrait
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)

        // Y: luma
        
        var yTextureRef : Unmanaged<CVMetalTextureRef>?
        
        let yWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer!, 0);
        let yHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer!, 0);

        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
            videoTextureCache!.takeUnretainedValue(),
            pixelBuffer!,
            nil,
            MTLPixelFormat.R8Unorm,
            yWidth, yHeight, 0,
            &yTextureRef)
        
        // CbCr: CB and CR are the blue-difference and red-difference chroma components /
        
        var cbcrTextureRef : Unmanaged<CVMetalTextureRef>?
        
        let cbcrWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer!, 1);
        let cbcrHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer!, 1);
        
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
            videoTextureCache!.takeUnretainedValue(),
            pixelBuffer!,
            nil,
            MTLPixelFormat.RG8Unorm,
            cbcrWidth, cbcrHeight, 1,
            &cbcrTextureRef)
        
        let yTexture = CVMetalTextureGetTexture((yTextureRef?.takeUnretainedValue())!)
        let cbcrTexture = CVMetalTextureGetTexture((cbcrTextureRef?.takeUnretainedValue())!)
        
        self.metalView.addTextures(yTexture: yTexture!, cbcrTexture: cbcrTexture!)
        
        yTextureRef?.release()
        cbcrTextureRef?.release()
    }
    
    func sliderChangeHandler()
    {
        metalView.setBlurSigma(blurSlider.value)
    }
    
    override func viewDidLayoutSubviews()
    {
        metalView.frame = view.bounds
        
        metalView.drawableSize = CGSize(width: view.bounds.width * 2, height: view.bounds.height * 2)
        
        blurSlider.frame = CGRect(x: 20,
            y: view.frame.height - blurSlider.intrinsicContentSize().height - 20,
            width: view.frame.width - 40,
            height: blurSlider.intrinsicContentSize().height)
    }
    
}
