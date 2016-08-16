//
//  CVFLukasKanade.m
//  CVFunhouse
//
//  Created by John Brewer on 7/25/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

// Based on the OpenCV example: <opencv>/samples/cpp/lkdemo.cpp

#import "CVFLucasKanade.h"
#include "CVFLucasKanadeDelegate.h"
#include "opencv2/video/tracking.hpp"
#include "opencv2/imgproc/imgproc.hpp"

using namespace cv;
using namespace std;

TermCriteria termcrit(CV_TERMCRIT_ITER|CV_TERMCRIT_EPS,20,0.03);
cv::Size subPixWinSize(10,10), winSize(31,31);
const int MAX_COUNT = 500;

@interface CVFLucasKanade () {
    Mat gray, prevGray/*, image */;
    vector<Point2f> points[2];
    
}

@end

@implementation CVFLucasKanade

-(void)processMat:(cv::Mat)image
{
    //    mat.copyTo(image);
    cvtColor(image, image, CV_BGR2RGB);
    cvtColor(image, gray, CV_BGR2GRAY);
    
    // automatic initialization
    goodFeaturesToTrack(gray, points[1], MAX_COUNT, 0.01, 10, Mat(), 3, 0, 0.04);
    cornerSubPix(gray, points[1], subPixWinSize, cv::Size(-1,-1), termcrit);
    
    if( !points[1].empty() )
    {
        vector<uchar> status;
        vector<float> err;
        if(prevGray.empty())
            gray.copyTo(prevGray);
        calcOpticalFlowPyrLK(prevGray, gray, points[1], points[0], status, err, winSize,
                             3, termcrit, 0, 0.001);
        size_t i, k;
        
        NSMutableArray *LKArray = [NSMutableArray new];
        for( i = k = 0; i < points[1].size(); i++ )
        {
            if( !status[i] )
                continue;
            
            points[1][k++] = points[1][i];
            
            cv::Point point;
            point = points[1][i];
            
            [LKArray addObject: [NSValue valueWithCGPoint:CGPointMake(point.x, point.y) ]];
            
            circle( image, points[1][i], 3, Scalar(0,255,0), -1, 8);
        }
        points[1].resize(k);
        [self.LKdelegate LKPositions:LKArray];
    }
    
    //    std::swap(points[1], points[0]);
    swap(prevGray, gray);
    
    [self matReady:image];
    
}

@end
