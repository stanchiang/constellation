//
//  CVWrapper.h
//  constellation
//
//  Created by Stanley Chiang on 8/21/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CVWrapper : NSObject
+ (bool) processImageBuffer:(CVImageBufferRef)imageBuffer;

@end
