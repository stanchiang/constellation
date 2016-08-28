//
//  MathUtilities.swift
//  swiftingIn3D
//
//  Created by Stanley Chiang on 8/27/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

import UIKit
import simd

class MathUtilities: NSObject {
    
    func matrix_float4x4_translation(t:vector_float3) -> matrix_float4x4 {
        let X:vector_float4 = vector_float4(x: 1, y: 0, z: 0, w: 0)
        let Y:vector_float4 = vector_float4(x: 0, y: 1, z: 0, w: 0)
        let Z:vector_float4 = vector_float4(x: 0, y: 0, z: 1, w: 0)
        let W:vector_float4 = vector_float4(x:t.x, y:t.y, z:t.z, w:1)
        
        let mat:matrix_float4x4 = matrix_float4x4(columns: (X, Y, Z, W))
        return mat;
    }
    
    func matrix_float4x4_uniform_scale(scale: Float) -> matrix_float4x4 {
        let x:vector_float4 = vector_float4(x: scale, y: 0, z: 0, w: 0)
        let y:vector_float4 = vector_float4(x: 0, y: scale, z: 0, w: 0)
        let z:vector_float4 = vector_float4(x: 0, y: 0, z: scale, w: 0)
        let w:vector_float4 = vector_float4(x: 0, y: 0, z: 0, w: 1)
        
        let mat:matrix_float4x4 = matrix_float4x4(columns: (x, y, z, w))
        return mat;
    }
    
    func matrix_float4x4_rotation(axis:vector_float3, angle:Float) -> matrix_float4x4 {
        let c:Float = cos(angle)
        let s:Float = sin(angle)

        let X:vector_float4 = vector_float4(x: axis.x * axis.x + (1 - axis.x * axis.x) * c,
                                            y: axis.x * axis.y * (1 - c) - axis.z * s,
                                            z: axis.x * axis.z * (1 - c) + axis.y * s,
                                            w: 0)

        let Y:vector_float4 = vector_float4(x: axis.x * axis.y * (1 - c) + axis.z * s,
                                            y: axis.y * axis.y + (1 - axis.y * axis.y) * c,
                                            z: axis.y * axis.z * (1 - c) - axis.x * s,
                                            w: 0)

        let Z:vector_float4 = vector_float4(x: axis.x * axis.z * (1 - c) - axis.y * s,
                                            y: axis.y * axis.z * (1 - c) + axis.x * s,
                                            z: axis.z * axis.z + (1 - axis.z * axis.z) * c,
                                            w: 0)
        
        let W:vector_float4 = vector_float4(x: 0, y: 0, z: 0, w: 0)
        
        let mat:matrix_float4x4 = matrix_float4x4(columns: (X, Y, Z, W))
        return mat
    }
 
    func matrix_float4x4_perspective(aspect:Float, fovy:Float, near:Float, far:Float) -> matrix_float4x4 {
        let yScale:Float = 1 / tan(fovy * 0.5)
        let xScale:Float = yScale / aspect
        let zRange:Float = far - near
        let zScale:Float = -(far + near) / zRange
        let wzScale:Float = -2 * far * near / zRange
        
        let P:vector_float4 = vector_float4(x: xScale, y: 0, z: 0, w: 0)
        let Q:vector_float4 = vector_float4(x: 0, y: yScale, z: 0, w: 0)
        let R:vector_float4 = vector_float4(x: 0, y: 0, z: zScale, w: -1)
        let S:vector_float4 = vector_float4(x: 0, y: 0, z: wzScale, w: 0)
        
        let mat:matrix_float4x4 = matrix_float4x4(columns: (P, Q, R, S))
        return mat
    }
}
