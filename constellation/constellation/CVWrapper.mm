//
//  CVWrapper.m
//  constellation
//
//  Created by Stanley Chiang on 8/21/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CVWrapper.h"
#import "CVWrapperDelegate.h"
#import "kltTrackingOBJ.h"
#import "ARPipeline.hpp"
#import "commonCvFunctions.h"
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/highgui/cap_ios.h>

#include <iostream>
@interface CVWrapper()<CvVideoCameraDelegate> {
    cv::Mat query_image;
    
    bool track_f;
    cvar::trackingOBJ* trckOBJ;
    cv::Size frame_size;
    int query_scale;
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

- (void) setupVars {
    CGRect viewFrame = [self.delegate screenSize];
    frame_size = cv::Size(viewFrame.size.height, viewFrame.size.width);
    int frame_max_size;
    if(frame_size.width > frame_size.height){
        frame_max_size = frame_size.width;
    }
    else{
        frame_max_size = frame_size.height;
    }
    
    int max_query_size = 320;
    query_scale = 1;
    while((frame_max_size / query_scale) > max_query_size){
        query_scale*=2;
    }
    query_image.create(frame_size.height/query_scale, frame_size.width/query_scale, CV_8UC1);
    trckOBJ = cvar::trackingOBJ::create(cvar::trackingOBJ::TRACKER_KLT);
}

- (void)processImage:(cv::Mat&)image {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"pic1" ofType:@"bmp"];
    const char * cpath = [path cStringUsingEncoding:NSUTF8StringEncoding];
    cv::Mat patternImage = cv::imread( cpath, CV_LOAD_IMAGE_UNCHANGED );
    
    CameraCalibration calibration(1136, 320, 1041, 240);
    ARPipeline pipeline(patternImage, calibration);
    
//    cv::Size frameSize(image.cols, image.rows);

    [self processFrame:image pipeline:pipeline];
}

-(void) processFrame: (cv::Mat&) cameraFrame pipeline: (ARPipeline&) pipeline {
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
    cv::circle(cameraFrame, cv::Point(50, 50), 3, cv::Scalar(0,250,0), -1 );
    
////////////
//    if(!track_f){
//        cv::Mat frame;
//        cv::cvtColor(cameraFrame, frame, cv::COLOR_BGRA2GRAY);
//        cv::resize(frame, query_image, query_image.size());
//        
//        std::vector<cvar::resultInfo> recog_result = ctrlOR.queryImage(query_image);
//        
//        if(!recog_result.empty()){
//            std::vector<cv::Point2f> scaled = cvar::scalePoints(recog_result[0].object_position, (double)3.0);
//            trckOBJ->startTracking(frame, scaled);
//            track_f = true;
//        }
//        
//    }else{
//        track_f = trckOBJ->onTracking(cameraFrame);
//    }
////////////
}
@end
