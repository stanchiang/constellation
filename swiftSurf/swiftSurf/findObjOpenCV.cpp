//
//  findObjOpenCV.cpp
//  MiniSURF
//
//  Created by Jonathan Saggau on 3/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "findObjOpenCV.h"

/*
 * A Demo to OpenCV Implementation of SURF
 * Further Information Refer to "SURF: Speed-Up Robust Feature"
 * Author: Liu Liu
 * liuliu.1987+opencv@gmail.com
 */
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/features2d/features2d.hpp>
#include <opencv2/calib3d/calib3d.hpp>
#include <opencv2/imgproc/imgproc_c.h>
#include <opencv2/legacy/compat.hpp>

#include <iostream>
#include <vector>

using namespace std;

IplImage* image = 0;

double
compareSURFDescriptors( const float* d1, const float* d2, double best, int length )
{
    double total_cost = 0;
    assert( length % 4 == 0 );
    for( int i = 0; i < length; i += 4 )
    {
        double t0 = d1[i  ] - d2[i  ];
        double t1 = d1[i+1] - d2[i+1];
        double t2 = d1[i+2] - d2[i+2];
        double t3 = d1[i+3] - d2[i+3];
        total_cost += t0*t0 + t1*t1 + t2*t2 + t3*t3;
        if( total_cost > best )
            break;
    }
    return total_cost;
}


int
naiveNearestNeighbor( const float* vec, int laplacian,
                     const CvSeq* model_keypoints,
                     const CvSeq* model_descriptors )
{
    int length = (int)(model_descriptors->elem_size/sizeof(float));
    int i, neighbor = -1;
    double d, dist1 = 1e6, dist2 = 1e6;
    CvSeqReader reader, kreader;
    cvStartReadSeq( model_keypoints, &kreader, 0 );
    cvStartReadSeq( model_descriptors, &reader, 0 );
    
    for( i = 0; i < model_descriptors->total; i++ )
    {
        const CvSURFPoint* kp = (const CvSURFPoint*)kreader.ptr;
        const float* mvec = (const float*)reader.ptr;
    	CV_NEXT_SEQ_ELEM( kreader.seq->elem_size, kreader );
        CV_NEXT_SEQ_ELEM( reader.seq->elem_size, reader );
        if( laplacian != kp->laplacian )
            continue;
        d = compareSURFDescriptors( vec, mvec, dist2, length );
        if( d < dist1 )
        {
            dist2 = dist1;
            dist1 = d;
            neighbor = i;
        }
        else if ( d < dist2 )
            dist2 = d;
    }
    if ( dist1 < 0.6*dist2 )
        return neighbor;
    return -1;
}

void
findPairs( const CvSeq* objectKeypoints, const CvSeq* objectDescriptors,
          const CvSeq* imageKeypoints, const CvSeq* imageDescriptors, vector<int>& ptpairs )
{
    int i;
    CvSeqReader reader, kreader;
    cvStartReadSeq( objectKeypoints, &kreader );
    cvStartReadSeq( objectDescriptors, &reader );
    ptpairs.clear();
    
    for( i = 0; i < objectDescriptors->total; i++ )
    {
        const CvSURFPoint* kp = (const CvSURFPoint*)kreader.ptr;
        const float* descriptor = (const float*)reader.ptr;
        CV_NEXT_SEQ_ELEM( kreader.seq->elem_size, kreader );
        CV_NEXT_SEQ_ELEM( reader.seq->elem_size, reader );
        int nearest_neighbor = naiveNearestNeighbor( descriptor, kp->laplacian, imageKeypoints, imageDescriptors );
        if( nearest_neighbor >= 0 )
        {
            ptpairs.push_back(i);
            ptpairs.push_back(nearest_neighbor);
        }
    }
}


void
flannFindPairs( const CvSeq*, const CvSeq* needleDescriptors,
               const CvSeq*, const CvSeq* heystackDescriptors, vector<int>& ptpairs )
{
	int length = (int)(needleDescriptors->elem_size/sizeof(float));
    
    cv::Mat m_needle(needleDescriptors->total, length, CV_32F);
	cv::Mat m_haystack(heystackDescriptors->total, length, CV_32F);
    
    
	// copy descriptors
    CvSeqReader needle_reader;
	float* needle_ptr = m_needle.ptr<float>(0);
    cvStartReadSeq( needleDescriptors, &needle_reader );
    for(int i = 0; i < needleDescriptors->total; i++ )
    {
        const float* descriptor = (const float*)needle_reader.ptr;
        CV_NEXT_SEQ_ELEM( needle_reader.seq->elem_size, needle_reader );
        memcpy(needle_ptr, descriptor, length*sizeof(float));
        needle_ptr += length;
    }
    CvSeqReader haystack_reader;
	float* haystack_ptr = m_haystack.ptr<float>(0);
    cvStartReadSeq( heystackDescriptors, &haystack_reader );
    for(int i = 0; i < heystackDescriptors->total; i++ )
    {
        const float* descriptor = (const float*)haystack_reader.ptr;
        CV_NEXT_SEQ_ELEM( haystack_reader.seq->elem_size, haystack_reader );
        memcpy(haystack_ptr, descriptor, length*sizeof(float));
        haystack_ptr += length;
    }
    
    // find nearest neighbors using FLANN
    cv::Mat m_indices(needleDescriptors->total, 2, CV_32S);
    cv::Mat m_dists(needleDescriptors->total, 2, CV_32F);
    cv::flann::Index flann_index(m_haystack, cv::flann::KDTreeIndexParams(4));  // using 4 randomized kdtrees
    flann_index.knnSearch(m_needle, m_indices, m_dists, 2, cv::flann::SearchParams(64) ); // maximum number of leafs checked
    
    int* indices_ptr = m_indices.ptr<int>(0);
    float* dists_ptr = m_dists.ptr<float>(0);
    for (int i=0;i<m_indices.rows;++i) {
    	if (dists_ptr[2*i]<0.6*dists_ptr[2*i+1]) {
    		ptpairs.push_back(i);
    		ptpairs.push_back(indices_ptr[2*i]);
    	}
    }
}


/* a rough implementation for object location */
int
locatePlanarObject( const CvSeq* objectKeypoints, const CvSeq* objectDescriptors,
                   const CvSeq* imageKeypoints, const CvSeq* imageDescriptors,
                   const CvPoint src_corners[4], CvPoint dst_corners[4] )
{
    double h[9];
    CvMat _h = cvMat(3, 3, CV_64F, h);
    vector<int> ptpairs;
    vector<CvPoint2D32f> pt1, pt2;
    CvMat _pt1, _pt2;
    int i, n;
    
#ifdef USE_FLANN
    printf("use flann\n");
    flannFindPairs( objectKeypoints, objectDescriptors, imageKeypoints, imageDescriptors, ptpairs );
#else
    printf("no flann\n");
    findPairs( objectKeypoints, objectDescriptors, imageKeypoints, imageDescriptors, ptpairs );
#endif
    
    n = (int)(ptpairs.size()/2);
    printf("ptpairs.size / 2 = %i \n",n);
    if( n < 45 )
//    if( n < 4 )
        return 0;
    
    pt1.resize(n);
    pt2.resize(n);
    for( i = 0; i < n; i++ )
    {
        pt1[i] = ((CvSURFPoint*)cvGetSeqElem(objectKeypoints,ptpairs[i*2]))->pt;
        pt2[i] = ((CvSURFPoint*)cvGetSeqElem(imageKeypoints,ptpairs[i*2+1]))->pt;
    }
    
    _pt1 = cvMat(1, n, CV_32FC2, &pt1[0] );
    _pt2 = cvMat(1, n, CV_32FC2, &pt2[0] );
    if( !cvFindHomography( &_pt1, &_pt2, &_h, CV_RANSAC, 5 ))
        return 0;
    
    for( i = 0; i < 4; i++ )
    {
        double x = src_corners[i].x, y = src_corners[i].y;
        double Z = 1./(h[6]*x + h[7]*y + h[8]);
        double X = (h[0]*x + h[1]*y + h[2])*Z;
        double Y = (h[3]*x + h[4]*y + h[5])*Z;
        dst_corners[i] = cvPoint(cvRound(X), cvRound(Y));
    }
    
    return 1;
}
