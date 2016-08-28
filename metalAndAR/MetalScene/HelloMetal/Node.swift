//
//  Node.swift
//  HelloMetal
//
//  Created by Andrew K. on 10/23/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import Metal
import QuartzCore

class Node {
  
  var time:CFTimeInterval = 0.0
  
  let name: String
  var vertexCount: Int
  var vertexBuffer: MTLBuffer
  var uniformBuffer: MTLBuffer?
  var device: MTLDevice
  
  var positionX:Float = 0.0
  var positionY:Float = 0.0
  var positionZ:Float = 0.0
  
  var rotationX:Float = 0.0
  var rotationY:Float = 0.0
  var rotationZ:Float = 0.0
  var scale:Float     = 1.0
  
  init(name: String, vertices: Array<Vertex>, device: MTLDevice){
    // 1
    var vertexData = Array<Float>()
    for vertex in vertices{
      vertexData += vertex.floatBuffer()
    }
    
    // 2
    let dataSize = vertexData.count * sizeofValue(vertexData[0])
    vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: .CPUCacheModeDefaultCache)
    
    // 3
    self.name = name
    self.device = device
    vertexCount = vertices.count
  }
  
  func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, parentModelViewMatrix: Matrix4, projectionMatrix: Matrix4, clearColor: MTLClearColor?){
    
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture

    renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
    renderPassDescriptor.colorAttachments[0].loadAction = .Load;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 1.0, 1.0);

//    renderPassDescriptor.depthAttachment.loadAction = .Load;
//    renderPassDescriptor.depthAttachment.storeAction = .Store;
//    renderPassDescriptor.depthAttachment.clearDepth = 1.0;
//    
    let commandBuffer = commandQueue.commandBuffer()
    
    let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
      //For now cull mode is used instead of depth buffer
      renderEncoder.setCullMode(MTLCullMode.Front)
      
      renderEncoder.setRenderPipelineState(pipelineState)
      renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
      // 1
      var nodeModelMatrix = self.modelMatrix()
      nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
      // 2
      uniformBuffer = device.newBufferWithLength(sizeof(Float) * Matrix4.numberOfElements() * 2, options: .CPUCacheModeDefaultCache)
      // 3
      var bufferPointer = uniformBuffer?.contents()
      // 4
      memcpy(bufferPointer!, nodeModelMatrix.raw(), sizeof(Float)*Matrix4.numberOfElements())
      memcpy(bufferPointer! + sizeof(Float)*Matrix4.numberOfElements(), projectionMatrix.raw(), sizeof(Float)*Matrix4.numberOfElements())
      // 5
      renderEncoder.setVertexBuffer(self.uniformBuffer, offset: 0, atIndex: 1)
      renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
      renderEncoder.endEncoding()
    
    
    commandBuffer.presentDrawable(drawable)
    commandBuffer.commit()
  }
  
  func modelMatrix() -> Matrix4 {
    let matrix = Matrix4()
    matrix.translate(positionX, y: positionY, z: positionZ)
    matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
    matrix.scale(scale, y: scale, z: scale)
    return matrix
  }
  
  func updateWithDelta(delta: CFTimeInterval){
    time += delta
  }
  
}
