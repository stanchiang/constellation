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

//#include <algorithm>
//#include <string>
//#include <vector>

using namespace cv;
using namespace std;

//struct Line {
//    cv::Point _p1;
//    cv::Point _p2;
//    cv::Point _center;
//    
//    Line(cv::Point p1, cv::Point p2) {
//        _p1 = p1;
//        _p2 = p2;
//        _center = cv::Point((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
//    }
//};

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

//    if( !points[1].empty() )
    if( !points[0].empty() )
    {
        vector<uchar> status;
        vector<float> err;
        if(prevGray.empty())
            gray.copyTo(prevGray);
//        calcOpticalFlowPyrLK(prevGray, gray, points[1], points[0], status, err, winSize,
        calcOpticalFlowPyrLK(prevGray, gray, points[0], points[1], status, err, winSize,
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
            
            //w: 320.00 - 414
            //h: 568.00 - 736
            //NSLog(@"c%d", image.cols);360
            //NSLog(@"r%d", image.rows);480
            [LKArray addObject: [NSValue valueWithCGPoint:CGPointMake(point.x * 320/360, point.y * 568/480)]];
            
            circle( image, points[1][i], 3, Scalar(0,255,0), -1, 8);
        }
        points[1].resize(k);
        [self.LKdelegate LKPositions:LKArray];
    }
    
    std::swap(points[1], points[0]);
    swap(prevGray, gray);
    
//    [self matReady:[self scan:image]];
    [self matReady:image];
}

///**
// * Get edges of an image
// * @param gray - grayscale input image
// * @param canny - output edge image
// */
//void getCanny(Mat gray, Mat &canny) {
//    Mat thres;
//    double high_thres = threshold(gray, thres, 0, 255, CV_THRESH_BINARY | CV_THRESH_OTSU), low_thres = high_thres * 0.5;
//    cv::Canny(gray, canny, low_thres, high_thres);
//}
//
//bool cmp_y(const Line &p1, const Line &p2) {
//    return p1._center.y < p2._center.y;
//}
//
//bool cmp_x(const Line &p1, const Line &p2) {
//    return p1._center.x < p2._center.x;
//}
//
///**
// * Compute intersect point of two lines l1 and l2
// * @param l1
// * @param l2
// * @return Intersect Point
// */
//Point2f computeIntersect(Line l1, Line l2) {
//    int x1 = l1._p1.x, x2 = l1._p2.x, y1 = l1._p1.y, y2 = l1._p2.y;
//    int x3 = l2._p1.x, x4 = l2._p2.x, y3 = l2._p1.y, y4 = l2._p2.y;
//    if (float d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)) {
//        Point2f pt;
//        pt.x = ((x1 * y2 - y1 * x2) * (x3 - x4) - (x1 - x2) * (x3 * y4 - y3 * x4)) / d;
//        pt.y = ((x1 * y2 - y1 * x2) * (y3 - y4) - (y1 - y2) * (x3 * y4 - y3 * x4)) / d;
//        return pt;
//    }
//    return Point2f(-1, -1);
//}
//
//-(Mat) scan: (Mat)img_proc {
//    
//    /* get input image */
////    Mat img = imread(file);
//    // resize input image to img_proc to reduce computation
////    Mat img_proc;
////    int w = img.size().width, h = img.size().height, min_w = 200;
//    int w = img_proc.cols, h = img_proc.rows, min_w = 200;
//    double scale = min(10.0, w * 1.0 / min_w);
//    int w_proc = w * 1.0 / scale, h_proc = h * 1.0 / scale;
////    resize(img, img_proc, cv::Size(w_proc, h_proc));
//    Mat img_dis = img_proc.clone();
//    
//    /* get four outline edges of the document */
//    // get edges of the image
//    Mat ggray, canny;
//    cvtColor(img_proc, ggray, CV_BGR2GRAY);
//    getCanny(ggray, canny);
//    
//    // extract lines from the edge image
//    vector<Vec4i> lines;
//    vector<Line> horizontals, verticals;
//    HoughLinesP(canny, lines, 1, CV_PI / 180, w_proc / 3, w_proc / 3, 20);
//    for (size_t i = 0; i < lines.size(); i++) {
//        Vec4i v = lines[i];
//        double delta_x = v[0] - v[2], delta_y = v[1] - v[3];
//        Line l(cv::Point(v[0], v[1]), cv::Point(v[2], v[3]));
//        // get horizontal lines and vertical lines respectively
//        if (fabs(delta_x) > fabs(delta_y)) {
//            horizontals.push_back(l);
//        } else {
//            verticals.push_back(l);
//        }
//        // for visualization only
////        if (debug)
//            line(img_proc, cv::Point(v[0], v[1]), cv::Point(v[2], v[3]), Scalar(0, 0, 255), 1, CV_AA);
//    }
//    
//    // edge cases when not enough lines are detected
//    if (horizontals.size() < 2) {
//        if (horizontals.size() == 0 || horizontals[0]._center.y > h_proc / 2) {
//            horizontals.push_back(Line(cv::Point(0, 0), cv::Point(w_proc - 1, 0)));
//        }
//        if (horizontals.size() == 0 || horizontals[0]._center.y <= h_proc / 2) {
//            horizontals.push_back(Line(cv::Point(0, h_proc - 1), cv::Point(w_proc - 1, h_proc - 1)));
//        }
//    }
//    if (verticals.size() < 2) {
//        if (verticals.size() == 0 || verticals[0]._center.x > w_proc / 2) {
//            verticals.push_back(Line(cv::Point(0, 0), cv::Point(0, h_proc - 1)));
//        }
//        if (verticals.size() == 0 || verticals[0]._center.x <= w_proc / 2) {
//            verticals.push_back(Line(cv::Point(w_proc - 1, 0), cv::Point(w_proc - 1, h_proc - 1)));
//        }
//    }
//    // sort lines according to their center point
//    sort(horizontals.begin(), horizontals.end(), cmp_y);
//    sort(verticals.begin(), verticals.end(), cmp_x);
//    // for visualization only
////    if (debug) {
//        line(img_proc, horizontals[0]._p1, horizontals[0]._p2, Scalar(0, 255, 0), 2, CV_AA);
//        line(img_proc, horizontals[horizontals.size() - 1]._p1, horizontals[horizontals.size() - 1]._p2, Scalar(0, 255, 0), 2, CV_AA);
//        line(img_proc, verticals[0]._p1, verticals[0]._p2, Scalar(255, 0, 0), 2, CV_AA);
//        line(img_proc, verticals[verticals.size() - 1]._p1, verticals[verticals.size() - 1]._p2, Scalar(255, 0, 0), 2, CV_AA);
////    }
//    
//    /* perspective transformation */
//    
//    // define the destination image size: A4 - 200 PPI
//    int w_a4 = 1654, h_a4 = 2339;
//    //int w_a4 = 595, h_a4 = 842;
//    Mat dst = Mat::zeros(h_a4, w_a4, CV_8UC3);
//    
//    // corners of destination image with the sequence [tl, tr, bl, br]
//    vector<Point2f> dst_pts, img_pts;
//    dst_pts.push_back(cv::Point(0, 0));
//    dst_pts.push_back(cv::Point(w_a4 - 1, 0));
//    dst_pts.push_back(cv::Point(0, h_a4 - 1));
//    dst_pts.push_back(cv::Point(w_a4 - 1, h_a4 - 1));
//    
//    // corners of source image with the sequence [tl, tr, bl, br]
//    img_pts.push_back(computeIntersect(horizontals[0], verticals[0]));
//    img_pts.push_back(computeIntersect(horizontals[0], verticals[verticals.size() - 1]));
//    img_pts.push_back(computeIntersect(horizontals[horizontals.size() - 1], verticals[0]));
//    img_pts.push_back(computeIntersect(horizontals[horizontals.size() - 1], verticals[verticals.size() - 1]));
//    
//    // convert to original image scale
//    for (size_t i = 0; i < img_pts.size(); i++) {
//        // for visualization only
////        if (debug) {
//            circle(img_proc, img_pts[i], 10, Scalar(255, 255, 0), 3);
////        }
//        img_pts[i].x *= scale;
//        img_pts[i].y *= scale;
//    }
//    
//    // get transformation matrix
//    Mat transmtx = getPerspectiveTransform(img_pts, dst_pts);
//    
//    // apply perspective transformation
////    warpPerspective(img, dst, transmtx, dst.size());
//    
//    return dst;
//    // save dst img
////    imwrite("dst.jpg", dst);
//    
//    // for visualization only
////    if (debug) {
////        namedWindow("dst", CV_WINDOW_KEEPRATIO);
////        imshow("src", img_dis);
////        imshow("canny", canny);
////        imshow("img_proc", img_proc);
////        imshow("dst", dst);
////        waitKey(0);
////    }
//}
//

@end
