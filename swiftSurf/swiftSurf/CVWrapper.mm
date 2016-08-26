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
    IplImage* needleIplImage2;
    IplImage* haystackIplImage;
//    IplImage* output;
}

@property (nonatomic, strong) CvVideoCamera* videoSource;
@end

@implementation CVWrapper

- (void) initImages {
    
    //TODO: don't use cached UIImages
    UIImage *img = [UIImage imageNamed:@"Altoids.png"];
    needleIplImage = [OpenCVUtilities CreateGRAYIplImageFromUIImage:img];
    
    UIImage *img2 = [UIImage imageNamed:@"IPDCLogo.png"];
    needleIplImage2 = [OpenCVUtilities CreateGRAYIplImageFromUIImage:img2];
}

- (void) initCamera:(UIView *) view {
    _videoSource = [[CvVideoCamera alloc] initWithParentView:view];
    _videoSource.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    _videoSource.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    _videoSource.delegate = self;
    _videoSource.rotateVideo = true;
    [_videoSource start];
//    printf("will process frame");
}

- (void) processImage:(cv::Mat &)image {
    UIImage *otherImg =  [self UIImageFromMat: &image];
    haystackIplImage = [OpenCVUtilities CreateGRAYIplImageFromUIImage:otherImg];
    cvCircle(haystackIplImage, cvPoint(50,50), 2, {{0,0,255}}, -1, 8, 0);
    [self findObject:needleIplImage];
    [self findObject:needleIplImage2];
    image = cv::Mat(haystackIplImage);
}

-(UIImage*)UIImageFromMat:(cv::Mat *)mat
{
    CGImageRef cgImage = [self CGImageFromMat:mat];
    UIImage *uiImage = [[UIImage alloc] initWithCGImage: cgImage
                                                  scale: 1.0
                                            orientation: UIImageOrientationUp];
    CGImageRelease(cgImage);
    return uiImage;
}

-(CGImageRef)CGImageFromMat:(cv::Mat *)mat
{
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = mat->step;
    
    size_t bitsPerPixel;
    CGColorSpaceRef space;
    
    if (mat->channels() == 1) {
        bitsPerPixel = 8;
        space = CGColorSpaceCreateDeviceGray(); // must release after CGImageCreate
    } else if (mat->channels() == 3) {
        bitsPerPixel = 24;
        space = CGColorSpaceCreateDeviceRGB(); // must release after CGImageCreate
    } else if (mat->channels() == 4) {
        bitsPerPixel = 32;
        space = CGColorSpaceCreateDeviceRGB(); // must release after CGImageCreate
    } else {
        abort();
    }
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNone;
    CGDataProviderRef provider = CGDataProviderCreateWithData(mat,
                                                              mat->data,
                                                              0,
                                                              ReleaseMatDataCallback);
    const CGFloat *decode = NULL;
    bool shouldInterpolate = true;
    CGColorRenderingIntent intent = kCGRenderingIntentDefault;
    
    CGImageRef cgImageRef = CGImageCreate(mat->cols,
                                          mat->rows,
                                          bitsPerComponent,
                                          bitsPerPixel,
                                          bytesPerRow,
                                          space,
                                          bitmapInfo,
                                          provider,
                                          decode,
                                          shouldInterpolate,
                                          intent);
    CGColorSpaceRelease(space);
    CGDataProviderRelease(provider);
    return cgImageRef;
}

static void ReleaseMatDataCallback(void *info, const void *data, size_t size)
{
#pragma unused(data)
#pragma unused(size)
    cv::Mat *mat = static_cast<cv::Mat*>(info);

    if (size != 0) {
        printf("deleting mat");
        delete mat;
    }else {
        printf("nothing to delete");
    }
    
}

//Magic
- (void) findObject: (IplImage *)needleObj {
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
    if( !needleObj || !haystackIplImage)
    {
        NSLog(@"Missing object or image");
        return;
    }
    
    CvSize objSize = cvGetSize(needleObj);
    IplImage* object_color = cvCreateImage(objSize, 8, 3);
    cvCvtColor( needleObj, object_color, CV_GRAY2BGR );
    
    CvSeq *needleKeypoints = 0, *needleDescriptors = 0;
    CvSeq *haystackKeypoints = 0, *haystackDescriptors = 0;
    int i;
    CvSURFParams params = cvSURFParams(500, 1);
    
    double tt = (double)cvGetTickCount();
//    NSLog(@"Now finding object descriptors");
    
    cvExtractSURF( needleObj, 0, &needleKeypoints, &needleDescriptors, storage, params );
//    NSLog(@"Needle Descriptors: %d", needleDescriptors->total);
    
    cvExtractSURF( haystackIplImage, 0, &haystackKeypoints, &haystackDescriptors, storage, params );
//    NSLog(@"Haystack Descriptors: %d", haystackDescriptors->total);
    
    tt = (double)cvGetTickCount() - tt;
//    NSLog(@"Extraction time = %gms", tt/(cvGetTickFrequency()*1000.));
    
    CvPoint src_corners[4] = {{0,0}, {needleObj->width,0}, {needleObj->width, needleObj->height}, {0, needleObj->height}};
    CvPoint dst_corners[4];
//    output = cvCreateImage(cvSize(haystackIplImage->width, haystackIplImage->height),  8,  1 );
//    cvCopy( haystackIplImage, output );
    
//    NSLog(@"Now locating Planar Object");
    if( locatePlanarObject( needleKeypoints, needleDescriptors, haystackKeypoints,
                           haystackDescriptors, src_corners, dst_corners ))
    {
        printf("\nlocated planar\n");
        for( i = 0; i < 4; i++ )
        {
            CvPoint r1 = dst_corners[i%4];
            CvPoint r2 = dst_corners[(i+1)%4];
            cvLine( haystackIplImage, cvPoint(r1.x, r1.y),
                   cvPoint(r2.x, r2.y), colors[3], 3 );
        }
    }
    
//    NSLog(@"Converting Output");
    UIImage *convertedOutput = [OpenCVUtilities UIImageFromGRAYIplImage:haystackIplImage];
    
//    NSLog(@"Opening Stuff");
    [imageView setImage:convertedOutput];
    cvReleaseImage(&object_color);
}
@end
