//
//  XJPetalViewInfo.m
//  XJWaterfallViewDemo
//
//  Created by Xiantao Jiao on 4/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XJPetalViewInfo.h"


@interface XJPetalViewInfo() {
@private
    NSUInteger index_;
    NSUInteger row_;
    CGRect frame_;
}
@end


@implementation XJPetalViewInfo

#pragma mark - Public methods

@synthesize index = index_;
@synthesize row = row_;
@synthesize frame = frame_;

@end