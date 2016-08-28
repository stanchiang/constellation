//
//  Square.swift
//  HelloMetal
//
//  Created by Laura Calinoiu on 09/12/15.
//  Copyright © 2015 Razeware LLC. All rights reserved.
//
import Foundation
import Metal

class Square: Node {
    
    init(device: MTLDevice){
        
        let A = Vertex(x: -3.0, y:   3.0, z:   0.0, r:  0.5, g:  0.5, b:  0.5, a:  1.0)
        let B = Vertex(x: -3.0, y:  -3.0, z:   0.0, r:  0.5, g:  0.5, b:  0.5, a:  1.0)
        let C = Vertex(x:  3.0, y:  -3.0, z:   0.0, r:  0.5, g:  0.5, b:  0.5, a:  1.0)
        let D = Vertex(x:  3.0, y:   3.0, z:   0.0, r:  0.5, g:  0.5, b:  0.5, a:  1.0)
        
        var verticesArray:Array<Vertex> = [A,B,C ,A,C,D]
        super.init(name: "Square", vertices: verticesArray, device: device)
    }
    
}