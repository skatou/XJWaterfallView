//
//  XJWaterfallPathInfo.h
//  XJWaterfallViewDemo
//
//  Created by Xiantao Jiao on 4/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class XJPetalViewInfo;

@interface XJWaterfallPathInfo : NSObject
@property (nonatomic, assign) NSUInteger column;
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign, readonly) CGFloat height;

- (NSUInteger) numberOfPetals;
- (XJPetalViewInfo*) petalViewInfoForRow:(NSUInteger)row;
- (void) addPetalViewInfo:(XJPetalViewInfo*)petalViewInfo;
@end