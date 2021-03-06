/*M///////////////////////////////////////////////////////////////////////////////////////
//
//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//
//
//                           License Agreement
//
// Copyright (C) 2012, Takuya MINAGAWA.
// Third party copyrights are property of their respective owners.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//M*/
#include "kltTrackingOBJ.h"
#include "commonCvFunctions.h"
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/calib3d/calib3d.hpp>
#include <opencv2/video/tracking.hpp>

using namespace std;
using namespace cv;
using namespace cvar;

kltTrackingOBJ::kltTrackingOBJ(void)
{
	max_corners = 80;
	quality_level = 0.1;
	min_distance = 5;
}


kltTrackingOBJ::~kltTrackingOBJ(void)
{
}


void kltTrackingOBJ::startTracking(const Mat& grayImg, vector<Point2f>& pts)
{
	Mat mask = createMask(grayImg.size(), pts);
	goodFeaturesToTrack(grayImg, corners, max_corners, quality_level, min_distance, mask);
    prevPyr.clear();
	grayImg.copyTo(prevImg);
	object_position = pts;
    object_position_ori = pts;
	float d[] = {1,0,0,0,1,0,0,0,1};
	homographyMat = Mat(3,3,CV_32FC1,d).clone();
	track_status.clear();
}


bool kltTrackingOBJ::onTracking(Mat& image)
{
    cv::Mat grayImg;
    cv::cvtColor(image, grayImg, cv::COLOR_BGRA2GRAY);
	std::vector<cv::Point2f> next_corners;
	std::vector<float> err;
	if(corners.size() == 0)
		return false;
    
    if(prevPyr.empty()){
        cv::buildOpticalFlowPyramid(prevImg, prevPyr, Size(21,21), 3, true);
    }
    
    cv::buildOpticalFlowPyramid(grayImg, nextPyr, Size(21,21), 3, true);
    cv::calcOpticalFlowPyrLK(prevPyr, nextPyr, corners, next_corners, track_status, err, Size(21,21), 3);
    
	//calcOpticalFlowPyrLK(prevImg, grayImg, corners, next_corners, track_status, err);
		
	int tr_num = 0;
    int count_num = 0;
	vector<unsigned char>::iterator status_itr = track_status.begin();
    
    std::vector<cv::Point2f> trackedPrePts;
    std::vector<cv::Point2f> trackedPts;
    for (size_t i=0; i<track_status.size(); i++)
    {
        if (track_status[i] && corners.size()>i && norm(next_corners[i] - corners[i]) <= 100/*&& m_prevPts_twice.size()>i && norm(m_prevPts[i] - m_prevPts_twice[i]) <= 2*/)
        {
            tr_num++;
            trackedPrePts.push_back(corners[i]);
            trackedPts.push_back(next_corners[i]);
//            printf("drawing!!!\n");
            cv::circle(image, corners[i], 3, cv::Scalar(0,250,0), -1);
            cv::line(image, corners[i], next_corners[i], cv::Scalar(0,250,0));
            cv::circle(image, next_corners[i], 3, cv::Scalar(0,250,0), -1);
        }
    }
 
//    printf("////////////\n");
//    printf("track_status: %lu\n", track_status.size());
//    printf("corners: %lu\n", corners.size());
//    printf("next_corners: %lu\n", next_corners.size());
    printf("tr_num: %i\n",tr_num);
//    printf("////////////\n");
    
	if(tr_num < 6){
		return false;
	}
	else{
//		homographyMat = findHomography(transPointVecToMat(corners,track_status), transPointVecToMat(next_corners,track_status),CV_RANSAC,5);
		
        //homographyMat = findHomography(Mat(corners), Mat(next_corners),track_status,cv::RANSAC,10);
        homographyMat = findHomography(cv::Mat(trackedPrePts), cv::Mat(trackedPts),cv::RANSAC,10);

//		Mat poseMat = findHomography(transPointVecToMat(corners), transPointVecToMat(next_corners), status, CV_RANSAC);

		if(countNonZero(homographyMat)==0){
			return false;
		}
		else{
			printf("tracking...\n");
            vector<Point2f> next_object_position = calcAffineTransformPoints(object_position, homographyMat);
			if(!checkPtInsideImage(prevImg.size(), next_object_position)){
                printf("points outside image\n");
				return false;
            }else {
                printf("points inside image\n");
            }
			if(!checkRectShape(next_object_position)){
				printf("not rect shape\n");
                return false;
            }else {
                printf("is rect shaped\n");
            }
			int ret = checkInsideArea(next_corners, next_object_position, track_status);
			if(ret < 6){
                printf("ret < 6 (%i)\n",ret);
				return false;
            } else {
                printf("ret = %i\n",ret);
            }
			grayImg.copyTo(prevImg);
            prevPyr.swap(nextPyr);
			corners = trackedPts;
			object_position = next_object_position;
            
            
            //0 - bl
            //1 - br
            //2 - tr
            //3 - tl
            
            if(object_position.size() >= 4){
                cv::line( image, object_position[0], object_position[1], cv::Scalar( 0, 255, 255 ), 4 );
//                printf("right/yellow   [0](x=%.2f,y=%.2f) ; [1](x=%.2f,y=%.2f)\n", object_position[0].x, object_position[0].y, object_position[1].x, object_position[1].y);
                cv::line( image, object_position[1], object_position[2], cv::Scalar( 255, 255, 0 ), 4 );
//                printf("bottom/teal [1](x=%.2f,y=%.2f) ; [2](x=%.2f,y=%.2f)\n", object_position[1].x, object_position[1].y, object_position[2].x, object_position[2].y);
                cv::line( image, object_position[2], object_position[3], cv::Scalar( 255, 0, 255 ), 4 );
//                printf("top/magneta [2](x=%.2f,y=%.2f) ; [3](x=%.2f,y=%.2f)\n", object_position[2].x, object_position[2].y, object_position[3].x, object_position[3].y);
                cv::line( image, object_position[3], object_position[0], cv::Scalar( 255, 0, 255 ), 4 );
//                printf("left/white [3](x=%.2f,y=%.2f) ; [0](x=%.2f,y=%.2f)\n", object_position[3].x, object_position[3].y, object_position[0].x, object_position[0].y);
                
            }else {
//                printf("only %lu object positions\n", object_position.size());
            }
		}
	}
	return true;
}
