//
//  XJWaterfallView.h
//  XJWaterfallView
//
//  Created by Xiantao Jiao on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class XJPetalView;
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
@property (nonatomic, weak) id<XJWaterfallViewDataSource> dataSource;
@property (nonatomic, strong) UIView* backgroundView;

- (XJPetalView*) dequeueReusablePetalViewWithIdentifier:(NSString*)identifier;

- (void) reloadData;
@end