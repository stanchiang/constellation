//
//  MBETorusKnotGeometry.m
//  MetalCubeMapping
//
//  Created by Warren Moore on 11/10/14.
//  Copyright (c) 2014 Metal By Example. All rights reserved.
//------------------------------------------------------------------------
//  converted to Swift by Jamnitzer (Jim Wrenholt)
//------------------------------------------------------------------------
import Foundation
import UIKit
import Metal
import simd



//------------------------------------------------------------------------
class MBJTorusKnotMesh : MBJMesh
{
    var p:Int = 0
    var q:Int = 0
    
    var tubeRadius:CGFloat = 0.0
    var segments:Int = 0
    var slices:Int = 0
    var device:MTLDevice
    
    //------------------------------------------------------------------------
    init(p:Int, q:Int, radius:CGFloat,  segments:Int, slices:Int, device:MTLDevice)
    {
        //----------------------------------------------
        // p & q must be two co-prime integers p, q
        //----------------------------------------------
        self.p = p
        self.q = q
        self.tubeRadius = radius
        self.segments = segments
        self.slices = slices
        self.device = device
        
        super.init()
        generateGeometry()
    }
    //------------------------------------------------------------------------
    func generateGeometry()
    {
        let vertexCount:Int = (self.segments + 1) * (self.slices + 1)
        let indexCount:Int = (self.segments) * (self.slices + 1) * 6
        
        var vertices = [Vertex](count:vertexCount, repeatedValue:Vertex())
        var indices = [UInt16](count:indexCount, repeatedValue:0)
        
        let usize = (4 + 4) * sizeof(Float)
        print("sizeof(Vertex) = \(sizeof(Vertex))")
        print("usize = \(usize)")
       
        let epsilon:Float = 1e-4
        let dt:Float = Float(2.0 * M_PI) / Float(self.segments)
        let du:Float = Float(2.0 * M_PI) / Float(self.slices)
        
        var vi:Int = 0
        for (var i:Int = 0; i <= self.segments; ++i)
        {
            //----------------------------------------------
            // calculate a point that lies on the curve
            //----------------------------------------------
            let t0:Float = Float(i) * dt
            let r0:Float = Float(2.0 + cos(Float(self.q) * t0)) * 0.5
            let p0:float3 = float3(r0 * cos(Float(self.p) * t0),
                r0 * sin(Float(self.p) * t0),
                -sinf(Float(self.q) * t0))
            
            //----------------------------------------------
            // approximate the Frenet frame { T, N, B } for 
            // the curve at the current point
            //----------------------------------------------
            let t1:Float = t0 + epsilon
            let r1:Float = (2 + cosf(Float(self.q) * t1)) * 0.5
            
            //----------------------------------------------
            // p1 is p0 advanced infinitesimally along the curve
            //----------------------------------------------
            let p1:float3 = float3(r1 * cos(Float(self.p) * t1),
                r1 * sin(Float(self.p) * t1),
                -sin(Float(self.q) * t1))
            
            //----------------------------------------------
            // compute approximate tangent as 
            // vector connecting p0 to p1
            //----------------------------------------------
            let T:float3 = float3(p1.x - p0.x,
                p1.y - p0.y,
                p1.z - p0.z)
            
            //----------------------------------------------
            // rough approximation of normal vector
            //----------------------------------------------
            var N:float3 = float3(p1.x + p0.x,
                p1.y + p0.y,
                p1.z + p0.z)
            
            //----------------------------------------------
            // compute binormal of curve
            //----------------------------------------------
            var B:float3 = cross(T, N)
            
            //----------------------------------------------
            // refine normal vector by Graham-Schmidt
            //----------------------------------------------
            N = cross(B, T)
            B = normalize(B)
            N = normalize(N)
            
            //----------------------------------------------
            // generate points in a circle perpendicular to 
            // the curve at the current point
            //----------------------------------------------
            for (var j:Int = 0; j <= self.slices; ++j, ++vi)
            {
                let u:Float = Float(j) * du
                //----------------------------------------------
                // compute position of circle point
                //----------------------------------------------
                let x:Float = Float(self.tubeRadius) * cosf(u)
                let y:Float = Float(self.tubeRadius) * sinf(u)
                
                var p2:float3 = float3(x * N.x + y * B.x,
                    x * N.y + y * B.y,
                    x * N.z + y * B.z)
                
                vertices[vi].position.x = p0.x + p2.x
                vertices[vi].position.y = p0.y + p2.y
                vertices[vi].position.z = p0.z + p2.z
                vertices[vi].position.w = 1
                //----------------------------------------------
                // compute normal of circle point
                //----------------------------------------------
                var n2:float3 = vector_normalize(p2)
                
                vertices[vi].normal.x = n2.x
                vertices[vi].normal.y = n2.y
                vertices[vi].normal.z = n2.z
                vertices[vi].normal.w = 0
            }
        }
        
            //------------------------------------------------------------------------
            // generate triplets of indices to create torus triangles
            //------------------------------------------------------------------------
            var i:Int = 0
            for (var vi:Int = 0; vi < (self.segments) * (self.slices + 1); ++vi)
            {
                indices[i++] = UInt16(vi)
                indices[i++] = UInt16(vi + self.slices + 1)
                indices[i++] = UInt16(vi + self.slices)
                
                indices[i++] = UInt16(vi)
                indices[i++] = UInt16(vi + 1)
                indices[i++] = UInt16(vi + self.slices + 1)
            }
        
        self.vertexBuffer = self.device.newBufferWithBytes(
            vertices,
            length: sizeof(Vertex) * vertexCount,
            options: .CPUCacheModeDefaultCache)
        
        self.indexBuffer = self.device.newBufferWithBytes(
            indices,
            length: sizeof(UInt16) * indexCount,
            options: .CPUCacheModeDefaultCache)
        
            //free(indices)
            //free(vertices)
        }
}
//------------------------------------------------------------------------
//------------------------------------------------------------------------
