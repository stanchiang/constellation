//
//  SwViewController.swift
//  CVOpenStitch
//
//  Created by Foundry on 04/06/2014.
//  Copyright (c) 2014 Foundry. All rights reserved.
//

import UIKit

class SwViewController: UIViewController, UIScrollViewDelegate {
    var imageView:UIImageView?
    var scrollView:UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        stitch()
    }
    
    override func viewDidLayoutSubviews() {
        scrollView.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor).active = true
        scrollView.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor).active = true
        scrollView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        scrollView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
    }
    
    func stitch() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            
            let image1 = UIImage(named:"pano_19_16_mid.jpg")
            let image2 = UIImage(named:"pano_19_20_mid.jpg")
            let image3 = UIImage(named:"pano_19_22_mid.jpg")
            let image4 = UIImage(named:"pano_19_25_mid.jpg")
            
            let imageArray:[UIImage!] = [image1,image2,image3,image4]
            let stitchedImage:UIImage = CVWrapper.processWithArray(imageArray) as UIImage
            
            dispatch_async(dispatch_get_main_queue()) {
                NSLog("stichedImage %@", stitchedImage)
                let imageView:UIImageView = UIImageView.init(image: stitchedImage)
                self.imageView = imageView
                self.scrollView.addSubview(self.imageView!)
                self.scrollView.backgroundColor = UIColor.blackColor()
                self.scrollView.contentSize = self.imageView!.bounds.size
                self.scrollView.maximumZoomScale = 4.0
                self.scrollView.minimumZoomScale = 0.5
                self.scrollView.delegate = self
                self.scrollView.contentOffset = CGPoint(x: -(self.scrollView.bounds.size.width - self.imageView!.bounds.size.width)/2.0, y: -(self.scrollView.bounds.size.height - self.imageView!.bounds.size.height)/2.0)
                NSLog("scrollview \(self.scrollView.contentSize)")
            }
        }
    }
    
    func viewForZoomingInScrollView(scrollView:UIScrollView) -> UIView? {
        return self.imageView!
    }
    
}
