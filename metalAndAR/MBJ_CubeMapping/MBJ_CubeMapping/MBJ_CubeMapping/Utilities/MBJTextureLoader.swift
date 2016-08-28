//
//  MBETextureLoader.m
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

class MBJTextureLoader
{
//------------------------------------------------------------------------------
class func dataForImage(image:UIImage) -> UnsafeMutablePointer<Void>
{
    let imageRef = image.CGImage
    //------------------------------------------------------------------------
    // Create a suitable bitmap context for extracting the bits of the image
    //------------------------------------------------------------------------
    let width = CGImageGetWidth(imageRef)
    let height = CGImageGetHeight(imageRef)
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    let rawData = calloc(height * width * 4, Int(sizeof(UInt8)))

    let bytesPerPixel: Int = 4
    let bytesPerRow: Int = bytesPerPixel * width
    let bitsPerComponent: Int = 8

    let options = CGImageAlphaInfo.PremultipliedLast.rawValue |
        CGBitmapInfo.ByteOrder32Big.rawValue
    
    let bitmapContext = CGBitmapContextCreate(rawData, width, height,
        bitsPerComponent, bytesPerRow, colorSpace, options)
    //CGColorSpaceRelease(colorSpace)
   
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0,
                CGFloat(width), CGFloat(height)), imageRef)
    //CGContextRelease(context)
   
    return UnsafeMutablePointer<Void>(rawData)
}
//------------------------------------------------------------------------------
class func texture2DWithImageNamed(imageName:String, device:MTLDevice) -> MTLTexture
{
    let image = UIImage(named:imageName)!
    let imageSize:CGSize = CGSizeMake(image.size.width * image.scale, image.size.height * image.scale)
    let bytesPerPixel: Int = 4
    let bytesPerRow:Int = bytesPerPixel * Int(imageSize.width)
    let imageData = MBJTextureLoader.dataForImage(image)

    let textureDescriptor =
    MTLTextureDescriptor.texture2DDescriptorWithPixelFormat( .RGBA8Unorm,
        width: Int(imageSize.width), height: Int(imageSize.height),
        mipmapped: false)
    
    let texture = device.newTextureWithDescriptor(textureDescriptor)
    texture.label = "textureForImage"

    let region = MTLRegionMake2D(0, 0, Int(imageSize.width), Int(imageSize.height))
    
    texture.replaceRegion(region, mipmapLevel: 0,
    withBytes: imageData, bytesPerRow: Int(bytesPerRow))

    //free(imageData)
    return texture
}
//------------------------------------------------------------------------------
class func textureCubeWithImagesNamed(imageNames:[String], device:MTLDevice) -> MTLTexture
{
    assert(imageNames.count == 6, "Cube texture can only be created from exactly six images")
    
    let firstImage = UIImage(named:imageNames[0])!
    let cubeSize:Int = Int(firstImage.size.width * firstImage.scale)
    
    let bytesPerPixel: Int = 4
    let bytesPerRow: Int = bytesPerPixel * cubeSize
    let bytesPerImage: Int = bytesPerRow * cubeSize
    
    let region = MTLRegionMake2D(0, 0, cubeSize, cubeSize)
    
    let textureDescriptor =
    MTLTextureDescriptor.textureCubeDescriptorWithPixelFormat( .RGBA8Unorm,
        size:cubeSize,
        mipmapped: false)
    
    let texture = device.newTextureWithDescriptor(textureDescriptor)
    texture.label = "textureCube"

    for (var slice:Int = 0; slice < 6; ++slice)
    {
        let imageName = imageNames[slice]
        let image:UIImage = UIImage(named:imageName)!
        let imageData = self.dataForImage(image)
        
        assert(Int(image.size.width) == cubeSize, "Cube map images must be square and uniformly-sized")
        assert(Int(image.size.height) == cubeSize, "Cube map images must be square and uniformly-sized")
        
        texture.replaceRegion(region,
            mipmapLevel: 0,
            slice:slice,
            withBytes: imageData,
            bytesPerRow: Int(bytesPerRow),
            bytesPerImage:bytesPerImage)
        // free(imageData)
    }
    return texture
}
//------------------------------------------------------------------------------
}
