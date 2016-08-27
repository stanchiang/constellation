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
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/highgui/cap_ios.h>

#include <iostream>
@interface CVWrapper()<CvVideoCameraDelegate> {
    cv::Mat query_image;
    
    bool track_f;
    cv::Size frame_size;
    int query_scale;
    
    NSDate *_lastFrameTime;
    
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
    CGRect viewFrame = [self.delegate screenSize];
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
//    printf("fx=%f cx=%f fy=%f cy=%f\n", fx, cx, fy, cy);
}

- (void)processImage:(cv::Mat&)image {
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"pic1" ofType:@"bmp"];
    const char * cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
    cv::Mat patternImage = cv::imread( cpath, CV_LOAD_IMAGE_ANYCOLOR );
    
    //rotate 90 degrees
    transpose(patternImage, patternImage);
    flip(patternImage, patternImage,1); //transpose+flip(1)=CW
    
//    fx=1229 cx=36 fy=1153 cy=640
//[1136, 320, 1041, 240]
    CameraCalibration calibration(fx, cx, fy, cy);


    ARPipeline pipeline(patternImage, calibration);

//    [self insertPatternIntoCameraFrame:patternImage image:image];

    [self processFrame: image pipeline:pipeline];
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

-(void) processFrame: (cv::Mat&) cameraFrame pipeline: (ARPipeline&) pipeline {
    // Clone image used for background (we will draw overlay on it)
    cv::Mat img = cameraFrame.clone();
    
    // Find a pattern
    pipeline.processFrame(cameraFrame);
    
    // Request redraw of the window
    cv::circle(cameraFrame, cv::Point(50, 50), 3, cv::Scalar(0,250,0), -1 );
    
    NSDate *now = [NSDate date];
    NSTimeInterval frameDelay = [now timeIntervalSinceDate:_lastFrameTime];
    double fps = 1.0/frameDelay;
    
    (fps != fps) ? printf("FPS = -\n") : printf("FPS = %.2f\n", fps);
    
    _lastFrameTime = now;
}
@end
