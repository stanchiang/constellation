//
//  MBETypes.h
//  MetalCubeMapping
//
//  Created by Warren Moore on 11/10/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//
//------------------------------------------------------------------------
//  converted to Swift by Jamnitzer (Jim Wrenholt)
//------------------------------------------------------------------------
import Foundation
import UIKit
import Metal
import simd

//------------------------------------------------------------------------
struct Uniforms
{
    var modelMatrix:float4x4 = float4x4(0)
    var projectionMatrix:float4x4 = float4x4(0)
    var normalMatrix:float4x4 = float4x4(0)
    var modelViewProjectionMatrix:float4x4 = float4x4(0)
    var worldCameraPosition:float4 = float4(0)
}
//------------------------------------------------------------------------
struct Vertex
{
    var position:float4 = float4(0)
    var normal:float4 = float4(0)
} 
//------------------------------------------------------------------------
