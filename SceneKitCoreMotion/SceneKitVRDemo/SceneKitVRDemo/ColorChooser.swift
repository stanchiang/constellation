//
//  ColorChooser.swift
//  SceneKitVRDemo
//
//  Created by Sujan Vaidya on 8/9/16.
//  Copyright © 2016 Sujan Vaidya. All rights reserved.
//

import Foundation
import SceneKit

// returns SCNMaterial of different color
class ColorMaterial {
    
    class func redColor() -> SCNMaterial {
        let redMaterial = SCNMaterial()
        redMaterial.diffuse.contents = UIColor.redColor()
        return redMaterial
    }
    
    class func greenColor() -> SCNMaterial {
        let greenMaterial = SCNMaterial()
        greenMaterial.diffuse.contents = UIColor.greenColor()
        return greenMaterial
    }
    
    class func blueColor() -> SCNMaterial {
        let blueMaterial = SCNMaterial()
        blueMaterial.diffuse.contents = UIColor.blueColor()
        return blueMaterial
    }
    
    class func yellowColor() -> SCNMaterial {
        let yellowMatarial = SCNMaterial()
        yellowMatarial.diffuse.contents = UIColor.yellowColor()
        return yellowMatarial
    }
    
    class func purpleColor() -> SCNMaterial {
        let purpleMaterial = SCNMaterial()
        purpleMaterial.diffuse.contents = UIColor.purpleColor()
        return purpleMaterial
    }
    
    class func orangeColor() -> SCNMaterial {
        let orangeMaterial = SCNMaterial()
        orangeMaterial.diffuse.contents = UIColor.orangeColor()
        return orangeMaterial
    }
    
    class func magentaColor() -> SCNMaterial {
        let magentaMaterial = SCNMaterial()
        magentaMaterial.diffuse.contents = UIColor.magentaColor()
        return magentaMaterial
    }
    
}
