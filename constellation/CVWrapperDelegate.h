//
//  CVWrapperDelegate.h
//  constellation
//
//  Created by Stanley Chiang on 8/23/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CVWrapper;

@protocol CVWrapperDelegate <NSObject>

-(CGRect) screenSize;

@end
