//
//  XJWaterfallView.h
//  XJWaterfallView
//
//  Created by Xiantao Jiao on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XJPetalView.h"


@class XJWaterfallView;

@protocol XJWaterfallViewDataSource <NSObject>
@required
- (NSUInteger) numberOfPetalsForWaterfallView:(XJWaterfallView*)waterfallView;
- (XJPetalView*) waterfallView:(XJWaterfallView*)waterfallView petalViewAtIndex:(NSUInteger)index;
- (CGFloat) waterfallView:(XJWaterfallView*)waterfallView normalizedHeightOfPetalViewAtIndex:(NSUInteger)index;

@optional
- (NSUInteger) numberOfPathsForWaterfallView:(XJWaterfallView*)waterfallView;
- (CGFloat) waterfallView:(XJWaterfallView*)waterfallView widthOfPathOnColumn:(NSUInteger)column;
@end


@interface XJWaterfallView : UIScrollView
@property (nonatomic, assign) id<XJWaterfallViewDataSource> dataSource;
@property (nonatomic, strong) UIView* backgroundView;
@property (nonatomic, assign) CGFloat petalViewGap;
@property (nonatomic, assign) CGFloat rightMargin;

- (XJPetalView*) dequeueReusablePetalViewWithIdentifier:(NSString*)identifier;

- (void) reloadData;
@end