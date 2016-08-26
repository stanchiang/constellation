//
//  NSObject+CVWrapper.m
//  swiftSurf
//
//  Created by Stanley Chiang on 8/25/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "CVWrapper.h"
#import "CVWrapperDelegate.h"
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/highgui/cap_ios.h>
#import "OpenCVUtilities.h"
#import "findObjOpenCV.h"

#include <opencv2/nonfree/nonfree.hpp>
#include <opencv2/legacy/compat.hpp>
#include <iostream>
@interface CVWrapper()<CvVideoCameraDelegate> {
    UIImageView *imageView;
    
@private
    IplImage* needleIplImage;
    IplImage* haystackIplImage;
    IplImage* output;
}

@property (nonatomic, strong) CvVideoCamera* videoSource;
@end

@implementation CVWrapper

- (void) initImages:(UIView *) view {
    imageView = [[UIImageView alloc] initWithFrame:view.frame];
    [view addSubview:imageView];
    //TODO: don't use cached UIImages
    
    UIImage *img = [UIImage imageNamed:@"IPDCLogo.png"];
    needleIplImage = [OpenCVUtilities CreateGRAYIplImageFromUIImage:img];
    
    UIImage *otherImg = [UIImage imageNamed:@"Banner.png"];
    haystackIplImage = [OpenCVUtilities CreateGRAYIplImageFromUIImage:otherImg];
    [self findObject];
    
}

- (void) initCamera:(UIView *) view {
    
    UIImage *img = [UIImage imageNamed:@"IPDCLogo.png"];
    needleIplImage = [OpenCVUtilities CreateGRAYIplImageFromUIImage:img];
    
    _videoSource = [[CvVideoCamera alloc] initWithParentView:view];
    _videoSource.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    _videoSource.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    _videoSource.delegate = self;
    _videoSource.rotateVideo = true;
    [_videoSource start];
    printf("will process frame");
    
    
}

- (void)processImage:(cv::Mat &)image {
    //    UIImage *otherImg = [UIImage imageNamed:@"Banner.png"];
    //    haystackIplImage = [OpenCVUtilities CreateGRAYIplImageFromUIImage:otherImg];
    //    [self findObject];
    
}

//Magic
- (void)findObject
{
    NSLog(@"%@ %@", self, NSStringFromSelector(_cmd));
    cv::initModule_nonfree();
    CvMemStorage* storage = cvCreateMemStorage(0);
    static CvScalar colors[] =
    {
        {{0,0,255}},
        {{0,128,255}},
        {{0,255,255}},
        {{0,255,0}},
        {{255,128,0}},
        {{255,255,0}},
        {{255,0,0}},
        {{255,0,255}},
        {{255,255,255}}
    };
    if( !needleIplImage || !haystackIplImage )
    {
        NSLog(@"Missing object or image");
        return;
    }
    
    CvSize objSize = cvGetSize(needleIplImage);
    IplImage* object_color = cvCreateImage(objSize, 8, 3);
    cvCvtColor( needleIplImage, object_color, CV_GRAY2BGR );
    
    CvSeq *needleKeypoints = 0, *needleDescriptors = 0;
    CvSeq *haystackKeypoints = 0, *haystackDescriptors = 0;
    int i;
    CvSURFParams params = cvSURFParams(500, 1);
    
    double tt = (double)cvGetTickCount();
    NSLog(@"Now finding object descriptors");
    
    cvExtractSURF( needleIplImage, 0, &needleKeypoints, &needleDescriptors, storage, params );
    NSLog(@"Needle Descriptors: %d", needleDescriptors->total);
    
    cvExtractSURF( haystackIplImage, 0, &haystackKeypoints, &haystackDescriptors, storage, params );
    NSLog(@"Haystack Descriptors: %d", haystackDescriptors->total);
    
    tt = (double)cvGetTickCount() - tt;
    NSLog(@"Extraction time = %gms", tt/(cvGetTickFrequency()*1000.));
    
    CvPoint src_corners[4] = {{0,0}, {needleIplImage->width,0}, {needleIplImage->width, needleIplImage->height}, {0, needleIplImage->height}};
    CvPoint dst_corners[4];
    output = cvCreateImage(cvSize(haystackIplImage->width, haystackIplImage->height),  8,  1 );
    cvCopy( haystackIplImage, output );
    
    NSLog(@"Now locating Planar Object");
#ifdef USE_FLANN
    NSLog(@"Now using approximate nearest neighbor search");
#endif
    if( locatePlanarObject( needleKeypoints, needleDescriptors, haystackKeypoints,
                           haystackDescriptors, src_corners, dst_corners ))
    {
        for( i = 0; i < 4; i++ )
        {
            CvPoint r1 = dst_corners[i%4];
            CvPoint r2 = dst_corners[(i+1)%4];
            cvLine( output, cvPoint(r1.x, r1.y),
                   cvPoint(r2.x, r2.y), colors[8] );
        }
    }
    
    NSLog(@"Converting Output");
    UIImage *convertedOutput = [OpenCVUtilities UIImageFromGRAYIplImage:output];
    
    NSLog(@"Opening Stuff");
    [imageView setImage:convertedOutput];
    cvReleaseImage(&object_color);
}
@end
