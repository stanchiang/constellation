//
//  VideoMetalView.swift
//  MetalVideoCapture
//
//  Created by Stanley Chiang on 8/27/16.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import MetalKit
import MetalPerformanceShaders

class VideoMetalView: MTKView {
    var ytexture:MTLTexture?
    var cbcrTexture: MTLTexture?
    
    var pipelineState: MTLComputePipelineState!
    var defaultLibrary: MTLLibrary!
    var commandQueue: MTLCommandQueue!
    var threadsPerThreadgroup:MTLSize!
    var threadgroupsPerGrid: MTLSize!
    
    var blur: MPSImageGaussianBlur!
    
    required init(frame: CGRect)
    {
        super.init(frame: frame, device:  MTLCreateSystemDefaultDevice())
        
        defaultLibrary = device!.newDefaultLibrary()!
        commandQueue = device!.newCommandQueue()
        
        let kernelFunction = defaultLibrary.newFunctionWithName("YCbCrColorConversion")
        
        do
        {
            pipelineState = try device!.newComputePipelineStateWithFunction(kernelFunction!)
        }
        catch
        {
            fatalError("Unable to create pipeline state")
        }
        
        threadsPerThreadgroup = MTLSizeMake(16, 16, 1)
        threadgroupsPerGrid = MTLSizeMake(2048 / threadsPerThreadgroup.width, 1536 / threadsPerThreadgroup.height, 1)
        
        blur = MPSImageGaussianBlur(device: device!, sigma: 0)
    }
    
    required init(coder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func addTextures(yTexture ytexture:MTLTexture, cbcrTexture: MTLTexture)
    {
        self.ytexture = ytexture
        self.cbcrTexture = cbcrTexture
    }
    
    func setBlurSigma(sigma: Float)
    {
        blur = MPSImageGaussianBlur(device: device!, sigma: sigma)
    }
    
    override func drawRect(dirtyRect: CGRect)
    {
        guard let drawable = currentDrawable, ytexture = ytexture, cbcrTexture = cbcrTexture else
        {
            return
        }
        
        let commandBuffer = commandQueue.commandBuffer()
        let commandEncoder = commandBuffer.computeCommandEncoder()
        
        commandEncoder.setComputePipelineState(pipelineState)
        
        commandEncoder.setTexture(ytexture, atIndex: 0)
        commandEncoder.setTexture(cbcrTexture, atIndex: 1)
        commandEncoder.setTexture(drawable.texture, atIndex: 2) // out texture
        
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        commandEncoder.endEncoding()
        
        let inPlaceTexture = UnsafeMutablePointer<MTLTexture?>.alloc(1)
        inPlaceTexture.initialize(drawable.texture)
        
        blur.encodeToCommandBuffer(commandBuffer, inPlaceTexture: inPlaceTexture, fallbackCopyAllocator: nil)
        
        commandBuffer.presentDrawable(drawable)
        
        commandBuffer.commit();
        
        
        
    }
}