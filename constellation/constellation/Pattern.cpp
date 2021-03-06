/*****************************************************************************
*   Markerless AR desktop application.
******************************************************************************
*   by Khvedchenia Ievgen, 5th Dec 2012
*   http://computer-vision-talks.com
******************************************************************************
*   Ch3 of the book "Mastering OpenCV with Practical Computer Vision Projects"
*   Copyright Packt Publishing 2012.
*   http://www.packtpub.com/cool-projects-with-opencv/book
*****************************************************************************/

////////////////////////////////////////////////////////////////////
// File includes:
#include "Pattern.hpp"

void PatternTrackingInfo::computePose(const Pattern& pattern, const CameraCalibration& calibration)
{
  cv::Mat Rvec;
  cv::Mat_<float> Tvec;
  cv::Mat raux,taux;

  cv::solvePnP(pattern.points3d, points2d, calibration.getIntrinsic(), calibration.getDistorsion(),raux,taux);
  raux.convertTo(Rvec,CV_32F);
  taux.convertTo(Tvec ,CV_32F);

  cv::Mat_<float> rotMat(3,3); 
  cv::Rodrigues(Rvec, rotMat);

  // Copy to transformation matrix
  for (int col=0; col<3; col++)
  {
    for (int row=0; row<3; row++)
    {        
     pose3d.r().mat[row][col] = rotMat(row,col); // Copy rotation component
    }
    pose3d.t().data[col] = Tvec(col); // Copy translation component
  }

  // Since solvePnP finds camera location, w.r.t to marker pose, to get marker pose w.r.t to the camera we invert it.
  pose3d = pose3d.getInverted();
}

void PatternTrackingInfo::draw2dContour(cv::Mat& image, cv::Scalar color) const
{
  for (size_t i = 0; i < points2d.size(); i++)
  {
//      printf("p%zu = (%.2f,%.2f) | p%zu = (%.2f,%.2f) \n",i, points2d[i].x, points2d[i].y,(i+1) % points2d.size(), points2d[ (i+1) % points2d.size() ].x, points2d[ (i+1) % points2d.size() ].y);
//      if (i == 0) {
//          color = cv::Scalar( 0, 255, 255 );
//      }else if (i == 1) {
//          color = cv::Scalar( 255, 255, 0 );
//      }else if (i == 2){
//          color = cv::Scalar( 255, 0, 255 );
//      }else {
//          color = cv::Scalar( 255, 255, 255 );
//      }
    cv::line(image, points2d[i], points2d[ (i+1) % points2d.size() ], cv::Scalar( 255, 255, 0 ), 4, CV_AA);
  }
}

