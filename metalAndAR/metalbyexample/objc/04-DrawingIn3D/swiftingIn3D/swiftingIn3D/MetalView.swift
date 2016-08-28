//
//  MetalView.swift
//  swiftingIn3D
//
//  Created by Stanley Chiang on 8/27/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

import UIKit
import Metal;
import QuartzCore.CAMetalLayer;

protocol MetalViewDelegate: class {
    func drawInView(view:MetalView)
}

class MetalView: UIView {
    
    /// The delegate of this view, responsible for drawing
    weak var delegate:MetalViewDelegate?
    
    /// The Metal layer that backs this view
    var metalLayer:CAMetalLayer = CAMetalLayer()
    
    /// The target frame rate (in Hz). For best results, this should
    /// be a number that evenly divides 60 (e.g., 60, 30, 15).
    var preferredFramesPerSecond:Int!
    
    /// The desired pixel format of the color attachment
    var colorPixelFormat:MTLPixelFormat {
        get {
            return self.metalLayer.pixelFormat
        }
    }
    
    /// The color to which the color attachment should be cleared at the start of
    /// a rendering pass
    var clearColor:MTLClearColor!
    
    /// The duration (in seconds) of the previous frame. This is valid only in the context
    /// of a callback to the delegate's -drawInView: method.
    var frameDuration:NSTimeInterval!
    
    /// The view's layer's current drawable. This is valid only in the context
    /// of a callback to the delegate's -drawInView: method.
    var currentDrawable:CAMetalDrawable!
    
    /// A render pass descriptor configured to use the current drawable's texture
    /// as its primary color attachment and an internal depth texture of the same
    /// size as its depth attachment's texture
    var currentRenderPassDescriptor:MTLRenderPassDescriptor {
        get {
            
            let passDescriptor = MTLRenderPassDescriptor()
            passDescriptor.colorAttachments[0].texture = currentDrawable.texture
            passDescriptor.colorAttachments[0].clearColor = self.clearColor;
            passDescriptor.colorAttachments[0].storeAction = MTLStoreAction.Store;
            passDescriptor.colorAttachments[0].loadAction = MTLLoadAction.Clear;
            
            passDescriptor.depthAttachment.texture = self.depthTexture;
            passDescriptor.depthAttachment.clearDepth = 1.0;
            passDescriptor.depthAttachment.loadAction = MTLLoadAction.Clear;
            passDescriptor.depthAttachment.storeAction = MTLStoreAction.DontCare;

            return passDescriptor
        }
    }
    
    var depthTexture:MTLTexture!
    var displayLink:CADisplayLink!

    init(frame: CGRect, device:MTLDevice) {
        super.init(frame: frame)
        commonInit()
        metalLayer.device = device
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        preferredFramesPerSecond = 60
        clearColor = MTLClearColorMake(1, 1, 1, 1)
        
        metalLayer.pixelFormat = MTLPixelFormat.BGRA8Unorm
    }
    
    func setColorPixelFormat(colorPixelFormat:MTLPixelFormat){
        metalLayer.pixelFormat = colorPixelFormat
    }
    
    override func didMoveToWindow() {
        let idealFrameDuration:NSTimeInterval = 1.0 / 60
        let targetFrameDuration:NSTimeInterval = 1.0 / Double(preferredFramesPerSecond)
        let frameInterval:NSTimeInterval = round(targetFrameDuration / idealFrameDuration)
        
        if window != nil {
//            displayLink.invalidate()
            displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire(_:)))
            displayLink.frameInterval = Int(frameInterval)
            displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        } else {
//            displayLink.invalidate()
//            displayLink = nil
        }
    }
    
    func displayLinkDidFire(displayLink:CADisplayLink) {
        currentDrawable = metalLayer.nextDrawable()
        frameDuration = displayLink.duration
        delegate?.drawInView(self)
    }
    
    func makeDepthTexture() {
        let drawableSize:CGSize = metalLayer.drawableSize
        
        if depthTexture.width != Int(drawableSize.width) || depthTexture.height != Int(drawableSize.height) {
            let desc:MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.Depth32Float, width: Int(drawableSize.width), height: Int(drawableSize.height), mipmapped: false)
            depthTexture = metalLayer.device?.newTextureWithDescriptor(desc)
        }
    }
}
