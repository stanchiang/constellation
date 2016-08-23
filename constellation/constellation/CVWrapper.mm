//
//  CVWrapper.m
//  constellation
//
//  Created by Stanley Chiang on 8/21/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CVWrapper.h"
#import "ARPipeline.hpp"

#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/highgui/cap_ios.h>

#include <iostream>
@interface CVWrapper()<CvVideoCameraDelegate> {
    
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
    printf("will process frame");
}

- (void)processImage:(cv::Mat&)image {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"pic1" ofType:@"bmp"];
    const char * cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
    cv::Mat patternImage = cv::imread( cpath, CV_LOAD_IMAGE_UNCHANGED );
    
    CameraCalibration calibration(1136, 320, 1041, 240);
    ARPipeline pipeline(patternImage, calibration);
    
    cv::Size frameSize(image.cols, image.rows);
    
    processFrame(image, pipeline);
}

bool processFrame(const cv::Mat& cameraFrame, ARPipeline& pipeline) {
    // Clone image used for background (we will draw overlay on it)
    cv::Mat img = cameraFrame.clone();
    
    if (pipeline.m_patternDetector.enableHomographyRefinement) {
        printf("Pose refinement: On");
    } else {
        printf("Pose refinement: Off");
    }
    
    printf("RANSAC threshold: %f",pipeline.m_patternDetector.homographyReprojectionThreshold);
    
    // Find a pattern
    pipeline.processFrame(cameraFrame);
    
    // Update a pattern pose
    pipeline.getPatternLocation();
    
    // Request redraw of the window
    cv::circle(img, cv::Point(50, 50), 3, cv::Scalar(0,250,0), -1 );
    
    return true;
}
@end
