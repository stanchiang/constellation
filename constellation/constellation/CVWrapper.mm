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
    _videoSource.delegate = self;
    _videoSource.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    [_videoSource start];
    printf("will process frame");
}

- (void)processImage:(cv::Mat&)image {
    cv::circle(image, cv::Point(50, 50), 3, cv::Scalar(0,250,0), -1 );
}

@end
