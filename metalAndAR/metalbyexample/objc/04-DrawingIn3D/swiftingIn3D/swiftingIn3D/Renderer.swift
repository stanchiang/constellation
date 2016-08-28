//
//  Renderer.swift
//  swiftingIn3D
//
//  Created by Stanley Chiang on 8/27/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

import Metal;
import QuartzCore.CAMetalLayer;
import simd;

struct Vertex {
    let position: vector_float4
    let color: vector_float4
}

struct Uniforms {
    let model:matrix_float4x4
    let modelViewProjectionMatrix:matrix_float4x4
}

class Renderer: NSObject, MetalViewDelegate {
    
    let inFlightBufferCount:Int = 3

    let indexType:MTLIndexType = MTLIndexType.UInt16
    
    var device:MTLDevice!
    var vertexBuffer:MTLBuffer!
    var indexBuffer:MTLBuffer!
    var uniformBuffer:MTLBuffer!
    var commandQueue:MTLCommandQueue!
    var renderPipelineState:MTLRenderPipelineState!
    var depthStencilState:MTLDepthStencilState!
    var displaySemaphore:dispatch_semaphore_t!
    var bufferIndex:Int!
    var rotationX:Float!
    var rotationY:Float!
    var time:Float!
    
    override init() {
        super.init()
        device = MTLCreateSystemDefaultDevice()
        displaySemaphore = dispatch_semaphore_create(inFlightBufferCount)
        makePipeline()
        makeBuffers()
    }
    
    func makePipeline(){
        commandQueue = device.newCommandQueue()
        let library:MTLLibrary = device.newDefaultLibrary()!
        
        let piplineDescriptor:MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
        piplineDescriptor.vertexFunction = library.newFunctionWithName("vertex_project")
        piplineDescriptor.fragmentFunction = library.newFunctionWithName("fragment_flatcolor")
        piplineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm
        piplineDescriptor.depthAttachmentPixelFormat = MTLPixelFormat.Depth32Float
        
        let depthStencilDescriptor:MTLDepthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = MTLCompareFunction.Less
        depthStencilDescriptor.depthWriteEnabled = true
        depthStencilState = device.newDepthStencilStateWithDescriptor(depthStencilDescriptor)
        
        renderPipelineState = try! device.newRenderPipelineStateWithDescriptor(piplineDescriptor)
        
        commandQueue = device.newCommandQueue()
        
    }
    
    func makeBuffers(){
        let vertices:[Vertex] = [Vertex(position: vector_float4(-1,  1,  1, 1), color: vector_float4(0, 1, 1, 1)),
                                 Vertex(position: vector_float4(-1, -1,  1, 1), color: vector_float4(0, 0, 1, 1)),
                                 Vertex(position: vector_float4( 1, -1,  1, 1), color: vector_float4(1, 0, 1, 1)),
                                 Vertex(position: vector_float4( 1,  1,  1, 1), color: vector_float4(1, 1, 1, 1)),
                                 Vertex(position: vector_float4(-1,  1, -1, 1), color: vector_float4(0, 1, 0, 1)),
                                 Vertex(position: vector_float4(-1, -1, -1, 1), color: vector_float4(0, 0, 0, 1)),
                                 Vertex(position: vector_float4( 1, -1, -1, 1), color: vector_float4(1, 0, 0, 1)),
                                 Vertex(position: vector_float4( 1,  1, -1, 1), color: vector_float4(1, 1, 0, 1))]

        let indices:[__uint16_t] = [3, 2, 6, 6, 7, 3,
                                    4, 5, 1, 1, 0, 4,
                                    4, 0, 3, 3, 7, 4,
                                    1, 5, 6, 6, 2, 1,
                                    0, 1, 2, 2, 3, 0,
                                    7, 6, 5, 5, 4, 7]
        
        vertexBuffer = device.newBufferWithBytes(vertices, length: vertices.count, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        vertexBuffer.label = "Vertices"
        
        indexBuffer = device.newBufferWithBytes(indices, length: indices.count, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        indexBuffer.label = "Indices"
        
        uniformBuffer = device.newBufferWithLength(sizeof(Uniforms) * inFlightBufferCount, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        uniformBuffer.label = "Uniforms"
    }
    
    func updateUniformsForView(view:MetalView, duration:NSTimeInterval) {
        time = time + Float(duration)
        rotationX = rotationX + Float(duration) * (Float(M_PI) / 2)
        rotationY = rotationY + Float(duration) * (Float(M_PI) / 3)
        let scaleFactor:Float = sinf(5 * time) * 0.25 + 1
        let xAxis:vector_float3 = vector_float3(1,0,0)
        let yAxis:vector_float3 = vector_float3(0,1,0)
        let xRot:matrix_float4x4 = MathUtilities().matrix_float4x4_rotation(xAxis, angle: rotationX)
        let yRot:matrix_float4x4 = MathUtilities().matrix_float4x4_rotation(yAxis, angle: rotationY)
        let scale:matrix_float4x4 = MathUtilities().matrix_float4x4_uniform_scale(scaleFactor)
        let modelMatrix:matrix_float4x4 = matrix_multiply(matrix_multiply(xRot, yRot), scale)
        
        let cameraTranslation:vector_float3 = vector_float3(0,0,-5)
        let viewMatrix = MathUtilities().matrix_float4x4_translation(cameraTranslation)
        
        let drawableSize:CGSize = view.metalLayer.drawableSize
        let aspect:Float = Float(drawableSize.width / drawableSize.height)
        let fov:Float = Float((2 * M_PI) / 5)
        let near:Float = 1
        let far:Float = 100
        let projectionMatrix:matrix_float4x4 = MathUtilities().matrix_float4x4_perspective(aspect, fovy: fov, near: near, far: far)
        
        var uniforms = Uniforms(model: modelMatrix, modelViewProjectionMatrix: matrix_multiply(projectionMatrix, matrix_multiply(viewMatrix, modelMatrix)))
        let uniformBufferOffset:UInt = UInt(sizeof(Uniforms) * self.bufferIndex)
        
        memcpy(uniformBuffer.contents().advancedBy(Int(uniformBufferOffset)), &uniforms, sizeofValue(uniforms))
//        memcpy([self.uniformBuffer contents] + uniformBufferOffset, &uniforms, sizeof(uniforms));
    }
    
    func drawInView(view: MetalView) {
        dispatch_semaphore_wait(displaySemaphore, DISPATCH_TIME_FOREVER)
        view.clearColor = MTLClearColorMake(0.95, 0.95, 0.95, 1)
        updateUniformsForView(view, duration: view.frameDuration)
        let commandBuffer:MTLCommandBuffer = commandQueue.commandBuffer()
        let passDescriptor:MTLRenderPassDescriptor = view.currentRenderPassDescriptor
        
        let renderPass:MTLRenderCommandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(passDescriptor)
        renderPass.setRenderPipelineState(renderPipelineState)
        renderPass.setDepthStencilState(depthStencilState)
        renderPass.setFrontFacingWinding(MTLWinding.CounterClockwise)
        renderPass.setCullMode(MTLCullMode.Back)
        
        let uniformBufferOffset:UInt = UInt(sizeof(Uniforms) * bufferIndex)
        renderPass.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        renderPass.setVertexBuffer(uniformBuffer, offset: Int(uniformBufferOffset), atIndex: 1)
        
        renderPass.drawIndexedPrimitives(MTLPrimitiveType.Triangle,
                                         indexCount: indexBuffer.length,
                                         indexType: indexType,
                                         indexBuffer: indexBuffer,
                                         indexBufferOffset: 0)
        renderPass.endEncoding()
        
        commandBuffer.presentDrawable(view.currentDrawable)
        
        commandBuffer.addCompletedHandler { (commandBuffer) in
            self.bufferIndex = (self.bufferIndex + 1) % self.inFlightBufferCount
            dispatch_semaphore_signal(self.displaySemaphore)
        }
        
        commandBuffer.commit()
    }
}
