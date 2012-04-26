//
//  XJWaterfallView.m
//  XJWaterfallView
//
//  Created by Xiantao Jiao on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XJPetalView.h"
#import "XJPetalViewInfo.h"
#import "XJWaterfallPathInfo.h"

#import "XJWaterfallView.h"


@interface XJWaterfallView() {
@private
    __unsafe_unretained id<XJWaterfallViewDataSource> dataSource_;
    UIView* backgroundView_;
    CGFloat petalViewPadding_;
    CGFloat rightMargin_;
    NSMutableArray* visiblePetalViews_;
    NSMutableDictionary* reusablePetalViews_;
    NSUInteger numberOfPaths_;
    NSArray* pathInfos_;
}
@property (nonatomic, strong) NSMutableArray* visiblePetalViews;
@property (nonatomic, strong) NSMutableDictionary* reusablePetalViews;
@property (nonatomic, assign) NSUInteger numberOfPaths;
@property (nonatomic, strong) NSArray* pathInfos;

- (XJWaterfallPathInfo*) infoOfShortestPath;
- (XJWaterfallPathInfo*) infoOfHighestPath;

- (void) prepareParametersNeededForLayout;
- (void) resetContentSizeByAppendingPetalViews;

- (void) tilePetalViewsOnPath:(XJWaterfallPathInfo*)pathInfo minimumY:(CGFloat)minY maximumY:(CGFloat)maxY;
- (NSInteger) lowerBoundIndexWithY:(CGFloat)y pathInfo:(XJWaterfallPathInfo*)pathInfo;

- (void) pushPetalViewForReuse:(XJPetalView*)petalView;
- (XJPetalView*) popReusablePetalViewWithIdentifier:(NSString*)identifier;
@end


@implementation XJWaterfallView

#pragma mark - Private static members

const static NSUInteger DEFAULT_NUMBER_OF_PATHS = 3;
const static CGFloat DEFAULT_PETAL_VIEW_PADDING = 5.0f;
const static CGFloat DEFAULT_RIGHT_MARGIN = 9.0f;


#pragma mark - Initializers and uninitializers

- (id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame]) != nil) {
        [self setBackgroundColor:[UIColor whiteColor]];
        [self setPetalViewPadding:DEFAULT_PETAL_VIEW_PADDING];
        [self setRightMargin:DEFAULT_RIGHT_MARGIN];
    }

    return self;
}


#pragma mark - Public methods

@synthesize dataSource = dataSource_;
@synthesize backgroundView = backgroundView_;

- (void) setBackgroundView:(UIView*)backgroundView {
    if (backgroundView != backgroundView_) {
        if ([backgroundView_ superview] == self) {
            [backgroundView_ removeFromSuperview];
        }

        backgroundView_ = backgroundView;
        [backgroundView_ setFrame:[self bounds]];
        [self addSubview:backgroundView_];
    }
}

@synthesize petalViewPadding = petalViewPadding_;
@synthesize rightMargin = rightMargin_;

- (XJPetalView*) dequeueReusablePetalViewWithIdentifier:(NSString*)identifier {
    XJPetalView* petalView = [self popReusablePetalViewWithIdentifier:identifier];

    [petalView prepareForReuse];

    return petalView;
}

- (void) reloadData {
    // Removes old petal views.
    for (XJPetalView* petalView in [self visiblePetalViews]) {
        [petalView removeFromSuperview];
    }

    [self setVisiblePetalViews:nil];
    [self setReusablePetalViews:nil];

    // Resets path count, path widths and heights, as well as content size.
    [self prepareParametersNeededForLayout];
    [self resetContentSizeByAppendingPetalViews];

    // Scrolls to top and tiles new petal views.
    [self scrollsToTop];
}


#pragma mark - UIView methods

- (void) layoutSubviews {
    [super layoutSubviews];

    CGRect bounds = [self bounds];

    // Centers background view.
    [backgroundView_ setFrame:bounds];

    // Recycles invisible petal views.
    for (XJPetalView* petalView in [[self visiblePetalViews] copy]) {
        if (!CGRectIntersectsRect(bounds, [petalView frame])) {
            [petalView removeFromSuperview];
            [self pushPetalViewForReuse:petalView];
            [[self visiblePetalViews] removeObject:petalView];
        }
    }

    // Tiles visible petal views.
    CGFloat minY = CGRectGetMinY(bounds);
    CGFloat maxY = CGRectGetMaxY(bounds);

    [[self pathInfos] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        [self tilePetalViewsOnPath:((XJWaterfallPathInfo*) obj) minimumY:minY maximumY:maxY];
    }];
}


#pragma mark - Private methods

@synthesize visiblePetalViews = visiblePetalViews_;

- (NSMutableArray*) visiblePetalViews {
    if (visiblePetalViews_ == nil) {
        [self setVisiblePetalViews:[NSMutableArray arrayWithCapacity:0]];
    }

    return visiblePetalViews_;
}

@synthesize reusablePetalViews = reusablePetalViews_;

- (NSMutableDictionary*) reusablePetalViews {
    if (reusablePetalViews_ == nil) {
        [self setReusablePetalViews:[NSMutableDictionary dictionaryWithCapacity:0]];
    }

    return reusablePetalViews_;
}

@synthesize numberOfPaths = numberOfPaths_;
@synthesize pathInfos = pathInfos_;

- (XJWaterfallPathInfo*) infoOfShortestPath {
    __block XJWaterfallPathInfo* bestPathInfo = nil;
    __block CGFloat minValue = 0.0f;

    [[self pathInfos] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        XJWaterfallPathInfo* pathInfo = (XJWaterfallPathInfo*) obj;

        if (bestPathInfo == nil || [pathInfo height] < minValue) {
            bestPathInfo = pathInfo;
            minValue = [pathInfo height];
        }
    }];

    return bestPathInfo;
}

- (XJWaterfallPathInfo*) infoOfHighestPath {
    __block XJWaterfallPathInfo* bestPathInfo = nil;
    __block CGFloat maxValue = 0.0f;

    [[self pathInfos] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        XJWaterfallPathInfo* pathInfo = (XJWaterfallPathInfo*) obj;

        if (bestPathInfo == nil || [pathInfo height] > maxValue) {
            bestPathInfo = pathInfo;
            maxValue = [pathInfo height];
        }
    }];

    return bestPathInfo;
}

- (void) prepareParametersNeededForLayout {
    if ([[self dataSource] respondsToSelector:@selector(numberOfPathsForWaterfallView:)] == YES) {
        [self setNumberOfPaths:[[self dataSource] numberOfPathsForWaterfallView:self]];
    } else {
        [self setNumberOfPaths:DEFAULT_NUMBER_OF_PATHS];
    }

    [self setPathInfos:nil];

    if ([self numberOfPaths] == 0) {
        return;
    }

    CGFloat spaceWidth = [self numberOfPaths] * [self petalViewPadding] + [self rightMargin];
    CGFloat fixedPathWidth = -1.0f;

    if ([[self dataSource] respondsToSelector:@selector(waterfallView:widthOfPathOnColumn:)] == NO) {
        fixedPathWidth = ([self bounds].size.width - spaceWidth) / [self numberOfPaths];

        if (fixedPathWidth < 0.0f) {
            fixedPathWidth = 0.0f;
        }
    }

    CGFloat pathStartX = [self petalViewPadding];
    NSMutableArray* pathInfos = [NSMutableArray arrayWithCapacity:[self numberOfPaths]];

    for (NSUInteger col = 0; col < [self numberOfPaths]; ++col) {
        CGFloat pathWidth = 0.0f;

        if (fixedPathWidth < 0.0f) {
            pathWidth = [[self dataSource] waterfallView:self widthOfPathOnColumn:col];
        } else {
            pathWidth = fixedPathWidth;
        }

        XJWaterfallPathInfo* pathInfo = [[XJWaterfallPathInfo alloc] init];

        [pathInfo setX:pathStartX];
        [pathInfo setWidth:pathWidth];
        [pathInfos addObject:pathInfo];
        pathStartX += pathWidth + [self petalViewPadding];
    }

    [self setPathInfos:pathInfos];
}

- (void) resetContentSizeByAppendingPetalViews {
    if ([self numberOfPaths] == 0) {
        [self setContentSize:[self bounds].size];

        return;
    }

    CGFloat spaceWidth = [self numberOfPaths] * [self petalViewPadding] + [self rightMargin];
    __block CGRect contentFrame = CGRectMake(0.0f, 0.0f, spaceWidth, 0.0f);
    __block NSUInteger fromIndex = 0;

    // Calculates content width.
    [[self pathInfos] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        XJWaterfallPathInfo* pathInfo = (XJWaterfallPathInfo*) obj;

        contentFrame.size.width += [pathInfo width];
        fromIndex += [pathInfo numberOfPetals];
    }];

    // Calculates content height, at the same time calculates frame of each petal view.
    NSUInteger numberOfPetal = [[self dataSource] numberOfPetalsForWaterfallView:self];

    for (NSUInteger index = fromIndex; index < numberOfPetal; ++index) {
        XJWaterfallPathInfo* pathInfo = [self infoOfShortestPath];
        CGFloat x = [pathInfo x];
        CGFloat y = [pathInfo height] + [self petalViewPadding];
        CGFloat width = [pathInfo width];
        CGFloat normalizedHeight = [[self dataSource] waterfallView:self normalizedHeightOfPetalViewAtIndex:index];
        CGFloat height = normalizedHeight * width;
        XJPentalViewInfo* petalViewInfo = [[XJPentalViewInfo alloc] init];

        [petalViewInfo setIndex:index];
        [petalViewInfo setFrame:CGRectMake(x, y, width, height)];
        [pathInfo addPetalViewInfo:petalViewInfo];
    }

    contentFrame.size.height = [[self infoOfHighestPath] height] + [self petalViewPadding];

    // Resets content size.
    contentFrame = CGRectIntegral(contentFrame);
    [self setContentSize:contentFrame.size];
}

- (void) tilePetalViewsOnPath:(XJWaterfallPathInfo*)pathInfo minimumY:(CGFloat)minY maximumY:(CGFloat)maxY {
    NSInteger index = [self lowerBoundIndexWithY:maxY pathInfo:pathInfo];

    for (index--; index >= 0; --index) {
        XJPentalViewInfo* petalViewInfo = [pathInfo petalViewInfoForRow:index];
        CGRect petalViewFrame = [petalViewInfo frame];

        if (petalViewInfo != nil && CGRectGetMaxY(petalViewFrame) > minY) {
            XJPetalView* petalView = [[self dataSource] waterfallView:self petalViewAtIndex:[petalViewInfo index]];

            if ([petalView superview] == nil) {
                [petalView setFrame:CGRectIntegral(petalViewFrame)];
                [self addSubview:petalView];
                [[self visiblePetalViews] addObject:petalView];
            }
        } else {
            break;
        }
    }
}

- (NSInteger) lowerBoundIndexWithY:(CGFloat)y pathInfo:(XJWaterfallPathInfo*)pathInfo {
    NSInteger index = [pathInfo numberOfPetals];
    NSInteger left = 0;
    NSInteger right = [pathInfo numberOfPetals] - 1;

    while (left <= right) {
        NSInteger mid = (left + right) / 2;

        if (CGRectGetMinY([[pathInfo petalViewInfoForRow:mid] frame]) >= y) {
            if (mid < index) {
                index = mid;
            }

            right = mid - 1;
        } else {
            left = mid + 1;
        }
    }

    return index;
}

- (void) pushPetalViewForReuse:(XJPetalView*)petalView {
    if ([petalView reuseIdentifier] == nil) {
        return;
    }

    NSMutableArray* petalViews = [[self reusablePetalViews] objectForKey:[petalView reuseIdentifier]];

    if (petalViews == nil) {
        petalViews = [NSMutableArray arrayWithCapacity:0];
        [[self reusablePetalViews] setObject:petalViews forKey:[petalView reuseIdentifier]];
    }

    [petalViews addObject:petalView];
}

- (XJPetalView*) popReusablePetalViewWithIdentifier:(NSString*)identifier {
    if (identifier == nil) {
        return nil;
    }

    NSMutableArray* petalViews = [[self reusablePetalViews] objectForKey:identifier];

    if ([petalViews count] == 0) {
        return nil;
    } else {
        XJPetalView* petalView = [petalViews lastObject];

        [petalViews removeLastObject];

        return petalView;
    }
}

@end