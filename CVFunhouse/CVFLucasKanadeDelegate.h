//
//  CVFLucasKanadeDelegate.h
//  CVFunhouse
//
//  Created by Stanley Chiang on 8/16/16.
//  Copyright © 2016 Jera Design LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CVFLucasKanade;

@protocol CVFLucasKanadeDelegate <NSObject>

-(void) LKPositions:(NSMutableArray *)points;

@end
