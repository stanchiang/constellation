//
//  Triangle.swift
//  HelloMetal
//
//  Created by Andrew K. on 10/24/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import Metal

class Triangle: Node {
  
  init(device: MTLDevice){
    
    let V0 = Vertex(x:  0.0, y:   5.0, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
    let V1 = Vertex(x: -5.0, y:  -5.0, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
    let V2 = Vertex(x:  5.0, y:  -5.0, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
    
    let verticesArray = [V0,V1,V2]
    super.init(name: "Triangle", vertices: verticesArray, device: device)
  }
  
}
