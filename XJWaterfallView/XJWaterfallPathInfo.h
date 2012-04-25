//
//  XJWaterfallPathInfo.h
//  XJWaterfallViewDemo
//
//  Created by Xiantao Jiao on 4/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class XJPentalViewInfo;

@interface XJWaterfallPathInfo : NSObject
@property (nonatomic, assign) NSUInteger column;
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign, readonly) CGFloat height;

- (NSUInteger) numberOfPetals;
- (XJPentalViewInfo*) petalViewInfoForRow:(NSUInteger)row;
- (void) addPetalViewInfo:(XJPentalViewInfo*)pentalViewInfo;
@end