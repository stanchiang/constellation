//
//  MBERenderer.m
//  MetalCubeMapping
//
//  Created by Warren Moore on 11/7/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//------------------------------------------------------------------------
//  converted to Swift by Jamnitzer (Jim Wrenholt)
//------------------------------------------------------------------------
import Foundation
import UIKit
import Metal
import simd
import QuartzCore

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
class MBJRenderer
{
    var device:MTLDevice! = nil
    var layer:CAMetalLayer! = nil
    var useRefractionMaterial:Bool = false
    var sceneOrientation:float4x4! = float4x4(1.0)
    
    var commandQueue:MTLCommandQueue! = nil
    var library:MTLLibrary! = nil
    var skyboxPipeline:MTLRenderPipelineState! = nil
    var torusReflectPipeline:MTLRenderPipelineState! = nil
    var torusRefractPipeline:MTLRenderPipelineState! = nil
    var uniformBuffer:MTLBuffer! = nil
    
    var depthTexture:MTLTexture! = nil
    var cubeTexture:MTLTexture! = nil
    var samplerState:MTLSamplerState! = nil
    var skybox:MBJMesh! = nil
    var torus:MBJMesh! = nil
    var rotationAngle:CGFloat = 0.0
    
    //------------------------------------------------------------------------
    init(layer:CAMetalLayer)
    {
        self.layer = layer
        buildMetal()

        self.layer.device = self.device
        if (self.layer != nil)
        {
            let drawableSize:CGSize = self.layer.drawableSize
            if (self.layer.device != nil)
            {
                print("GOOD LAYER & DEVICE")
            }
            else
            {
                print("NIL DEVICE")
            }
       }
        else
        {
            print("NIL LAYER.")
        }
        buildPipelines()
        buildResources()
    }
    //------------------------------------------------------------------------
    func buildMetal()
    {
        self.device = MTLCreateSystemDefaultDevice()
        self.library =  self.device!.newDefaultLibrary()
        commandQueue = device!.newCommandQueue()
    }
    //------------------------------------------------------------------------
    func pipelineForVertexFunctionNamed(vertexFunctionName:String,
        fragmentFunctionName:String) -> MTLRenderPipelineState?
    {
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].format = MTLVertexFormat.Float4
        
        vertexDescriptor.attributes[1].offset = sizeof(float4)
        vertexDescriptor.attributes[1].format = MTLVertexFormat.Float4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.PerVertex
        vertexDescriptor.layouts[0].stride = sizeof(Vertex)
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = self.library.newFunctionWithName(vertexFunctionName)
        pipelineDescriptor.fragmentFunction = self.library.newFunctionWithName(fragmentFunctionName)
        pipelineDescriptor.vertexDescriptor = vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.Depth32Float
        
        var pipeline:MTLRenderPipelineState? = nil
        do {
            pipeline = try
                device.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
        }
        catch let pipelineError as NSError
        {
            pipeline = nil
            print("Error occurred when creating render pipeline state \(pipelineError)")
            assert(false)
        }
        return pipeline
    }
    //------------------------------------------------------------------------
    func buildPipelines()
    {
        self.skyboxPipeline = pipelineForVertexFunctionNamed("vertex_skybox",
            fragmentFunctionName:"fragment_cube_lookup")
        
        self.torusReflectPipeline = pipelineForVertexFunctionNamed("vertex_reflect",
            fragmentFunctionName:"fragment_cube_lookup")
        
        self.torusRefractPipeline = pipelineForVertexFunctionNamed("vertex_refract",
            fragmentFunctionName:"fragment_cube_lookup")
    }
    //------------------------------------------------------------------------
    func buildResources()
    {
        let imageNames:[String] = ["px", "nx", "py", "ny", "pz", "nz",  ]
        
        self.cubeTexture = MBJTextureLoader.textureCubeWithImagesNamed(
                imageNames, device:device)
        
        self.skybox = MBJSkyboxMesh(device:device)
        
        self.torus = MBJTorusKnotMesh(p:3, q:8,
                        radius:0.2,
                        segments:256,
                        slices:32,
                        device:self.device)

            self.uniformBuffer = device!.newBufferWithLength(
                sizeof(Uniforms) * 2, options: .CPUCacheModeDefaultCache)
        
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = MTLSamplerMinMagFilter.Nearest
        samplerDescriptor.magFilter = MTLSamplerMinMagFilter.Linear
        self.samplerState = self.device!.newSamplerStateWithDescriptor(samplerDescriptor)
    }
    //------------------------------------------------------------------------
    func buildDepthBuffer()
    {
        let drawableSize:CGSize = self.layer.drawableSize
        let depthTexDesc =
        MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.Depth32Float,
            width: Int(drawableSize.width),
            height: Int(drawableSize.height),
            mipmapped: false)
        
        self.depthTexture = self.device.newTextureWithDescriptor(depthTexDesc)
    }
    //------------------------------------------------------------------------
    func drawSkyboxWithCommandEncoder(commandEncoder:MTLRenderCommandEncoder)
    {
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = MTLCompareFunction.Less
        depthDescriptor.depthWriteEnabled = false
        let depthState = device!.newDepthStencilStateWithDescriptor(depthDescriptor)
        
        commandEncoder.setRenderPipelineState(self.skyboxPipeline)
        commandEncoder.setDepthStencilState( depthState)
        commandEncoder.setVertexBuffer( self.skybox.vertexBuffer, offset: 0, atIndex: 0)
        commandEncoder.setVertexBuffer( self.uniformBuffer, offset: 0, atIndex: 1)
        commandEncoder.setFragmentBuffer( self.uniformBuffer, offset: 0, atIndex: 0)
        commandEncoder.setFragmentTexture( self.cubeTexture, atIndex: 0)
        commandEncoder.setFragmentSamplerState(self.samplerState, atIndex: 0)
        
        commandEncoder.drawIndexedPrimitives( .Triangle,
            indexCount:self.skybox.indexBuffer.length / sizeof(UInt16),
            indexType:MTLIndexType.UInt16,
            indexBuffer:self.skybox.indexBuffer,
            indexBufferOffset:0)
   }
    //------------------------------------------------------------------------
    func drawTorusWithCommandEncoder(commandEncoder:MTLRenderCommandEncoder)
    {
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = MTLCompareFunction.Less
        depthDescriptor.depthWriteEnabled = true
        let depthState = device!.newDepthStencilStateWithDescriptor(depthDescriptor)
        
        if (self.useRefractionMaterial )
        {
            commandEncoder.setRenderPipelineState(self.torusRefractPipeline)
        }
        else
        {
            commandEncoder.setRenderPipelineState(self.torusReflectPipeline)
        }
        commandEncoder.setDepthStencilState( depthState)
        commandEncoder.setVertexBuffer( self.torus.vertexBuffer, offset: 0, atIndex: 0)
        commandEncoder.setVertexBuffer( self.uniformBuffer, offset: sizeof(Uniforms), atIndex: 1)
        commandEncoder.setFragmentBuffer( self.uniformBuffer, offset: sizeof(Uniforms), atIndex: 0)
        commandEncoder.setFragmentTexture( self.cubeTexture, atIndex: 0)
        commandEncoder.setFragmentSamplerState(self.samplerState, atIndex: 0)
        
        commandEncoder.drawIndexedPrimitives( .Triangle,
            indexCount:self.torus.indexBuffer.length / sizeof(UInt16),
            indexType:MTLIndexType.UInt16,
            indexBuffer:self.torus.indexBuffer,
            indexBufferOffset:0)
    }
    //------------------------------------------------------------------------
    func renderPassForDrawable(drawable:CAMetalDrawable) -> MTLRenderPassDescriptor
    {
        let renderPass = MTLRenderPassDescriptor()
        
        renderPass.colorAttachments[0].texture = drawable.texture
        renderPass.colorAttachments[0].loadAction = MTLLoadAction.Clear
        renderPass.colorAttachments[0].storeAction = MTLStoreAction.Store
        renderPass.colorAttachments[0].clearColor = MTLClearColorMake(1, 1, 1, 1)
       
        renderPass.depthAttachment.texture = self.depthTexture
        renderPass.depthAttachment.loadAction = MTLLoadAction.Clear
        renderPass.depthAttachment.storeAction = MTLStoreAction.DontCare
        renderPass.depthAttachment.clearDepth = 1
        
        return renderPass
    }
    //------------------------------------------------------------------------
    func ShowMatrix(msg:String, _ m:float4x4)
    {
        let c0:float4 = m[0]
        let c1:float4 = m[1]
        let c2:float4 = m[2]
        let c3:float4 = m[3]
        print(msg)
        print("\(c0.x), \(c1.x), \(c2.x), \(c3.x) ")
        print("\(c0.y), \(c1.y), \(c2.y), \(c3.y) ")
        print("\(c0.z), \(c1.z), \(c2.z), \(c3.z) ")
        print("\(c0.w), \(c1.w), \(c2.w), \(c3.w) ")
        print("")
    }
    //------------------------------------------------------------------------
    func updateUniforms()
    {
        let cameraPosition:float4 = float4(0.0, 0.0, -4.0, 1.0)
        let size:CGSize = self.layer.bounds.size
        let aspectRatio:Float = Float(size.width / size.height)
        let verticalFOV:Float = (aspectRatio > 1) ? 60.0 : 90.0
        let near:Float = 0.1
        let far:Float = 100
        
        let projectionMatrix:float4x4 = perspective_projection(
            aspectRatio, fovy:verticalFOV * Float(M_PI / 180.0), near:near, far:far)
        let modelMatrix:float4x4 = identity()
        let skyboxViewMatrix:float4x4 = self.sceneOrientation
        
        let torusViewMatrix:float4x4 = translation(cameraPosition) * self.sceneOrientation
        let worldCameraPosition:float4 = self.sceneOrientation.inverse * (-cameraPosition)

        var skyboxUniforms = Uniforms()
            skyboxUniforms.modelMatrix = modelMatrix
            skyboxUniforms.projectionMatrix = projectionMatrix
            skyboxUniforms.normalMatrix = modelMatrix.inverse.transpose
            skyboxUniforms.modelViewProjectionMatrix = projectionMatrix * skyboxViewMatrix * modelMatrix
            skyboxUniforms.worldCameraPosition = worldCameraPosition
            memcpy(self.uniformBuffer.contents(), &skyboxUniforms, sizeof(Uniforms))
    
        var torusUniforms = Uniforms()
            torusUniforms.modelMatrix = modelMatrix
            torusUniforms.projectionMatrix = projectionMatrix
            torusUniforms.normalMatrix = modelMatrix.inverse.transpose
            torusUniforms.modelViewProjectionMatrix = projectionMatrix * torusViewMatrix * modelMatrix
            torusUniforms.worldCameraPosition = worldCameraPosition
            memcpy(self.uniformBuffer.contents() + sizeof(Uniforms), &torusUniforms, sizeof(Uniforms))
    }
    //------------------------------------------------------------------------
    func draw()
    {
        let drawableSize:CGSize = self.layer.drawableSize
        if (self.depthTexture == nil )
        {
            buildDepthBuffer()
        }

        if (CGFloat(self.depthTexture.width) != drawableSize.width) ||
            (CGFloat(self.depthTexture.height) != drawableSize.height )
        {
            buildDepthBuffer()
        }
        let drawable:CAMetalDrawable? = self.layer.nextDrawable()
        if (drawable != nil)
        {
            updateUniforms()
            let commandBuffer:MTLCommandBuffer = commandQueue.commandBuffer()
            let renderPass:MTLRenderPassDescriptor = self.renderPassForDrawable(drawable!)
            let commandEncoder:MTLRenderCommandEncoder =
                commandBuffer.renderCommandEncoderWithDescriptor(renderPass)
            commandEncoder.setCullMode( MTLCullMode.Back)
            commandEncoder.setFrontFacingWinding(MTLWinding.CounterClockwise)
            
            drawSkyboxWithCommandEncoder(commandEncoder)
            drawTorusWithCommandEncoder(commandEncoder)
            
            commandEncoder.endEncoding()
            commandBuffer.presentDrawable(drawable!)
            commandBuffer.commit()
        }
    }
    //------------------------------------------------------------------------
}
