//
//  CVWrapper.h
//  constellation
//
//  Created by Stanley Chiang on 8/21/16.
//  Copyright © 2016 Stanley Chiang. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CVWrapperDelegate;

@interface CVWrapper : NSObject<UIActionSheetDelegate> {
    
}
@property (nonatomic, weak) id<CVWrapperDelegate> delegate;
- (void) startCamera:(UIView *) view;
- (void) setupVars;
@end
