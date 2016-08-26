//
//  NSObject+CVWrapper.h
//  swiftSurf
//
//  Created by Stanley Chiang on 8/25/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CVWrapperDelegate;

@interface CVWrapper : NSObject {
    
}
@property (nonatomic, weak) id<CVWrapperDelegate> delegate;
- (void) initCamera:(UIView *) view;
- (void) initImages:(UIView *) view;
@end
