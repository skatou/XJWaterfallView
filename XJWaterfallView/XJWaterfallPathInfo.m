//
//  XJWaterfallPathInfo.m
//  XJWaterfallViewDemo
//
//  Created by Xiantao Jiao on 4/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XJPetalViewInfo.h"

#import "XJWaterfallPathInfo.h"


@interface XJWaterfallPathInfo() {
@private
    NSUInteger column_;
    CGFloat x_;
    CGFloat width_;
    NSMutableArray* petalViewInfos_;
}
@property (nonatomic, strong) NSMutableArray* petalViewInfos;
@end


@implementation XJWaterfallPathInfo

#pragma mark - Public methods

@synthesize column = column_;
@synthesize x = x_;
@synthesize width = width_;

- (CGFloat) height {
    if ([self numberOfPetals] == 0) {
        return 0.0f;
    } else {
        return CGRectGetMaxY([[[self petalViewInfos] lastObject] frame]);
    }
}

- (NSUInteger) numberOfPetals {
    return [[self petalViewInfos] count];
}

- (XJPetalViewInfo*) petalViewInfoForRow:(NSUInteger)row {
    if (row < [self numberOfPetals]) {
        return [[self petalViewInfos] objectAtIndex:row];
    } else {
        return nil;
    }
}

- (void) addPetalViewInfo:(XJPetalViewInfo*)petalViewInfo {
    [[self petalViewInfos] addObject:petalViewInfo];
}


#pragma mark - Private methods

@synthesize petalViewInfos = petalViewInfos_;

- (NSMutableArray*) petalViewInfos {
    if (petalViewInfos_ == nil) {
        [self setPetalViewInfos:[NSMutableArray arrayWithCapacity:0]];
    }

    return petalViewInfos_;
}

@end