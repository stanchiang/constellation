//
//  CVWrapper.m
//  constellation
//
//  Created by Stanley Chiang on 8/21/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "CVWrapper.h"
#import "CVWrapperDelegate.h"
#import "ARPipeline.hpp"
#import "trackingOBJ.h"
#import "commonCvFunctions.h"

#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/highgui/cap_ios.h>

#include <iostream>

//TODO: take still photos of needle objects to be searched for in haystack camera capture session
//TODO: pass photos to wrapper and call find object on each landmark (needle object)
//TODO: implement object tracking once object is recognized
@interface CVWrapper()<CvVideoCameraDelegate> {
    cv::Mat patternImage;
    cv::Mat cameraImage;
    bool shouldRotate;
    bool trackCurrentFrame;
    bool isTrackingCustomFrame;
    bool isRecognized;
    NSDate *_lastFrameTime;
    cvar::trackingOBJ* trckOBJ;
    
    CGFloat cx;
    CGFloat cy;
    CGFloat fx;
    CGFloat fy;
}
@property (nonatomic, strong) CvVideoCamera* videoSource;
@end

@implementation CVWrapper
- (void) startCamera:(UIView *) view {
    _videoSource = [[CvVideoCamera alloc] initWithParentView:view];
    _videoSource.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    _videoSource.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    _videoSource.delegate = self;
    _videoSource.rotateVideo = true;
//    _videoSource.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    [_videoSource start];
}

- (void) setupVars {
//    CGRect viewFrame = [self.delegate screenSize];
    AVCaptureDevice  * camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceFormat * format = camera.activeFormat;
    
    CMFormatDescriptionRef fDesc = format.formatDescription;
    CGSize dim = CMVideoFormatDescriptionGetPresentationDimensions(fDesc, true, true);
    
    cx = CGFloat(dim.width) / 2.0;
    cy = CGFloat(dim.height) / 2.0;
    
    CGFloat HFOV = format.videoFieldOfView;
    CGFloat VFOV = ((HFOV)/cx)*cy;
    
    fx = std::abs(CGFloat(dim.width) / (2 * tan(HFOV / 180 * CGFloat(M_PI) / 2)));
    fy = std::abs(CGFloat(dim.height) / (2 * tan(VFOV / 180 * CGFloat(M_PI) / 2)));
    printf("fx=%f cx=%f fy=%f cy=%f\n", fx, cx, fy, cy);
    
    trackCurrentFrame = false;
    isTrackingCustomFrame = false;
    isRecognized = false;
    shouldRotate = true;
    trckOBJ = cvar::trackingOBJ::create(cvar::trackingOBJ::TRACKER_KLT);
}

- (void) trackThisFrame {
    trackCurrentFrame = true;
}

- (void)processImage:(cv::Mat&)image {
    
    if (trackCurrentFrame) {
        cv::resize(image, cameraImage, cv::Size(image.rows * 0.99, image.cols * 0.99 ));
        isTrackingCustomFrame = true;
        trackCurrentFrame = false;
        shouldRotate = false;
    }
    
    if (isTrackingCustomFrame){
        patternImage = cameraImage;
    } else {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"pic1" ofType:@"bmp"];
        const char * cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
        patternImage = cv::imread( cpath, CV_LOAD_IMAGE_ANYCOLOR );
    }
    
    [self searchByMat:patternImage image:image];
    
    //    UIImage *img = [UIImage imageNamed:@"Altoids.png"];
    //    [self searchByUIImage:img image:image];
    
    //note: app can't handle searching for 2 uiimages at the same time; ocassionally crashes when searching for 1 bmp and 1 uiimage; crashes occur on solvepnp function
    //    UIImage *img2 = [UIImage imageNamed:@"IPDCLogo.png"];
    //    [self searchByUIImage:img2 image:image];
    
    //note: had to scale down the image dimentions a considerabe amount to get matching to work. the image was captured from the camera app and transferred to the project folder as a jpg
    
    //    UIImage *img = [UIImage imageNamed:@"shoe"];
    //    [self searchByUIImage:img image:image];

}

- (void) searchByUIImage:(UIImage *) img image: (cv::Mat&)image {
    cv::Mat patternImage = [self cvMatFromUIImage:img];
    [self searchByMat:patternImage image:image];
}

- (void) searchByMat:(cv::Mat&) img image: (cv::Mat&)image {
    
    // note: don't rotate images captured from live camera;
    if (shouldRotate){
        //rotate 90 degrees
        transpose(img, img);
        flip(img, img,1); //transpose+flip(1)=CW
    }
    
    //    fx=1229 cx=36 fy=1153 cy=640
    //[1136, 320, 1041, 240]
    
    CameraCalibration calibration(fx, cx, fy, cy);
    
//    [self insertPatternIntoCameraFrame:patternImage image:image];
    
    ARPipeline pipeline(img, calibration);
    
    if (!isRecognized) {
        printf("still looking...\n");
        isRecognized = pipeline.processFrame(image);
        if (isRecognized && !pipeline.m_patternInfo.points2d.empty()) {
            cv::Mat frame;
            cv::cvtColor(image, frame, cv::COLOR_BGRA2GRAY);
            cv::resize(frame, frame, image.size());
            
            trckOBJ->startTracking(frame, pipeline.m_patternInfo.points2d);
        }
    } else {
        printf("image found\n");
        //start tracking with KLT
        if (!trckOBJ->onTracking(image)){
            isRecognized = false;
        } else {
            isRecognized = true;
        }
    }
    
    [self calcFPS];

}

- (void) calcFPS {
    NSDate *now = [NSDate date];
    NSTimeInterval frameDelay = [now timeIntervalSinceDate:_lastFrameTime];
    double fps = 1.0/frameDelay;
    
    (fps != fps) ? printf("FPS = -\n") : printf("FPS = %.2f\n", fps);
    
    _lastFrameTime = now;
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

- (void) insertPatternIntoCameraFrame: (cv::Mat)patternImage image:(cv::Mat)image {
    cv::Mat newPattern(cvSize(patternImage.rows, patternImage.cols), CV_MAKE_TYPE(patternImage.type(), 4));
    cvtColor(patternImage, newPattern, cv::COLOR_BGR2BGRA,4);
    IplImage patternImageIPL = newPattern;
    IplImage imageIPL = image;
    cvSetImageROI( &imageIPL, cvRect( 0, 0, patternImageIPL.width, patternImageIPL.height ) );
    cvCopy( &patternImageIPL, &imageIPL );
    cvResetImageROI( &imageIPL );
    image = cv::Mat(&imageIPL);
}

@end
