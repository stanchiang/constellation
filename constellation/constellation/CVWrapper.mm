//
//  CVWrapper.m
//  constellation
//
//  Created by Stanley Chiang on 8/21/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CVWrapper.h"
#import "detector.hpp"

@implementation CVWrapper
+ (bool) processImageBuffer:(CVImageBufferRef)imageBuffer {
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    if (!baseAddress) {
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        return false;
    }
    
    // Get the pixel buffer width and height
    int width = (int)CVPixelBufferGetWidth(imageBuffer);
    int height = (int)CVPixelBufferGetHeight(imageBuffer);
    
    //  char *savedImageData = 0;
    // create IplImage
    cv::Mat mat(height, width, CV_8UC4, baseAddress);
    
    //    IplImage *flipCopy = cvCloneImage(iplimage);
    //    cvFlip(flipCopy, flipCopy, 0);
    cv::Mat workingCopy;
    
    cv::transpose(mat, workingCopy);
    cv::flip(workingCopy, workingCopy, 1);

    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    printf("will process frame");
    return processFrame(workingCopy);
}
@end
