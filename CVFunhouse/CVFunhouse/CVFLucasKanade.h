//
//  CVFLucasKanade.h
//  CVFunhouse
//
//  Created by John Brewer on 7/25/12.
//  Copyright (c) 2012 Jera Design LLC. All rights reserved.
//

#import "CVFImageProcessor.h"
#import "CVFLucasKanadeDelegate.h"

@protocol CVFLucasKanadeDelegate;

@interface CVFLucasKanade : CVFImageProcessor
@property (nonatomic, weak) id<CVFLucasKanadeDelegate> LKdelegate;
@end
