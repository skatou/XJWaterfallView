//
//  XJWaterfallView.m
//  XJWaterfallView
//
//  Created by Xiantao Jiao on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "XJPetalView.h"
#import "XJPetalViewInfo.h"
#import "XJWaterfallPathInfo.h"

#import "XJWaterfallView.h"


@interface XJWaterfallView() {
@private
    __unsafe_unretained id<XJWaterfallViewDataSource> dataSource_;
    UIView* backgroundView_;
    CGFloat petalViewGap_;
    CGFloat rightMargin_;
    NSArray* visiblePetalViews_;
    NSMutableDictionary* reusablePetalViews_;
    NSUInteger numberOfPaths_;
    NSArray* pathInfos_;
}
@property (nonatomic, strong) NSArray* visiblePetalViews;
@property (nonatomic, strong) NSMutableDictionary* reusablePetalViews;
@property (nonatomic, assign) NSUInteger numberOfPaths;
@property (nonatomic, strong) NSArray* pathInfos;

+ (void) reverseArray:(NSMutableArray*)array;

- (XJWaterfallPathInfo*) infoOfShortestPath;
- (XJWaterfallPathInfo*) infoOfHighestPath;

- (void) prepareParametersNeededForLayout;
- (void) resetContentSizeByAppendingPetalViews;

- (void) removeAllVisiblePetalViews;
- (void) tilePetalViewsOnPath:(XJWaterfallPathInfo*)pathInfo minimumY:(CGFloat)minY maximumY:(CGFloat)maxY;
- (void) tilePetalViewWithInfo:(XJPetalViewInfo*)petalViewInfo petalViewList:(NSMutableArray*)petalViews;
- (void) reloadPetalViewsOnPath:(XJWaterfallPathInfo*)pathInfo petalViewList:(NSMutableArray*)petalViews
    minimumY:(CGFloat)minY maximumY:(CGFloat)maxY;
- (NSInteger) firstRowBelowY:(CGFloat)y inPath:(XJWaterfallPathInfo*)pathInfo;

- (void) pushPetalViewForReuse:(XJPetalView*)petalView;
- (XJPetalView*) popReusablePetalViewWithIdentifier:(NSString*)identifier;
@end


@implementation XJWaterfallView

#pragma mark - Private static members

const static NSUInteger DEFAULT_NUMBER_OF_PATHS = 3;
const static CGFloat DEFAULT_PETAL_VIEW_GAP = 5.0f;
const static CGFloat DEFAULT_RIGHT_MARGIN = 9.0f;

static NSString* PETAL_VIEW_ROW_KEY = @"__PETAL_VIEW_ROW__";


#pragma mark - Initializers and uninitializers

- (id) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame]) != nil) {
        [self setBackgroundColor:[UIColor whiteColor]];
        [self setPetalViewGap:DEFAULT_PETAL_VIEW_GAP];
        [self setRightMargin:DEFAULT_RIGHT_MARGIN];
    }

    return self;
}


#pragma mark - Public static methods

+ (void) reverseArray:(NSMutableArray*)array {
    for (NSInteger i = 0, j = [array count] - 1; i < j; ++i, --j) {
        id tmp = [array objectAtIndex:i];

        [array replaceObjectAtIndex:i withObject:[array objectAtIndex:j]];
        [array replaceObjectAtIndex:j withObject:tmp];
    }
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

@synthesize petalViewGap = petalViewGap_;
@synthesize rightMargin = rightMargin_;

- (XJPetalView*) dequeueReusablePetalViewWithIdentifier:(NSString*)identifier {
    XJPetalView* petalView = [self popReusablePetalViewWithIdentifier:identifier];

    [petalView prepareForReuse];

    return petalView;
}

- (void) reloadData {
    // Removes old petal views.
    [self removeAllVisiblePetalViews];
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
    CGFloat minY = CGRectGetMinY(bounds);
    CGFloat maxY = CGRectGetMaxY(bounds);

    [backgroundView_ setFrame:bounds];
    [[self pathInfos] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        [self tilePetalViewsOnPath:((XJWaterfallPathInfo*) obj) minimumY:minY maximumY:maxY];
    }];
}


#pragma mark - Private methods

@synthesize visiblePetalViews = visiblePetalViews_;
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

    CGFloat spaceWidth = [self numberOfPaths] * [self petalViewGap] + [self rightMargin];
    CGFloat fixedPathWidth = -1.0f;

    if ([[self dataSource] respondsToSelector:@selector(waterfallView:widthOfPathOnColumn:)] == NO) {
        fixedPathWidth = ([self bounds].size.width - spaceWidth) / [self numberOfPaths];

        if (fixedPathWidth < 0.0f) {
            fixedPathWidth = 0.0f;
        }
    }

    CGFloat pathStartX = [self petalViewGap];
    NSMutableArray* visiblePetalViews = [NSMutableArray arrayWithCapacity:[self numberOfPaths]];
    NSMutableArray* pathInfos = [NSMutableArray arrayWithCapacity:[self numberOfPaths]];

    for (NSUInteger col = 0; col < [self numberOfPaths]; ++col) {
        [visiblePetalViews addObject:[NSMutableArray arrayWithCapacity:0]];

        CGFloat pathWidth = 0.0f;

        if (fixedPathWidth < 0.0f) {
            pathWidth = [[self dataSource] waterfallView:self widthOfPathOnColumn:col];
        } else {
            pathWidth = fixedPathWidth;
        }

        XJWaterfallPathInfo* pathInfo = [[XJWaterfallPathInfo alloc] init];

        [pathInfo setColumn:col];
        [pathInfo setX:pathStartX];
        [pathInfo setWidth:pathWidth];
        [pathInfos addObject:pathInfo];
        pathStartX += pathWidth + [self petalViewGap];
    }

    [self setVisiblePetalViews:visiblePetalViews];
    [self setPathInfos:pathInfos];
}

- (void) resetContentSizeByAppendingPetalViews {
    if ([self numberOfPaths] == 0) {
        [self setContentSize:[self bounds].size];

        return;
    }

    CGFloat spaceWidth = [self numberOfPaths] * [self petalViewGap] + [self rightMargin];
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
        CGFloat y = [pathInfo height] + [self petalViewGap];
        CGFloat width = [pathInfo width];
        CGFloat normalizedHeight = [[self dataSource] waterfallView:self normalizedHeightOfPetalViewAtIndex:index];
        CGFloat height = normalizedHeight * width;
        XJPetalViewInfo* petalViewInfo = [[XJPetalViewInfo alloc] init];

        [petalViewInfo setIndex:index];
        [petalViewInfo setRow:[pathInfo numberOfPetals]];
        [petalViewInfo setFrame:CGRectMake(x, y, width, height)];
        [pathInfo addPetalViewInfo:petalViewInfo];
    }

    contentFrame.size.height = [[self infoOfHighestPath] height] + [self petalViewGap];

    // Resets content size.
    contentFrame = CGRectIntegral(contentFrame);
    [self setContentSize:contentFrame.size];
}

- (void) removeAllVisiblePetalViews {
    [[self visiblePetalViews] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        [(NSArray*) obj enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
            [(XJPetalView*) obj removeFromSuperview];
        }];
    }];

    [self setVisiblePetalViews:nil];
}

- (void) tilePetalViewsOnPath:(XJWaterfallPathInfo*)pathInfo minimumY:(CGFloat)minY maximumY:(CGFloat)maxY {
    NSMutableArray* petalViews = [[self visiblePetalViews] objectAtIndex:[pathInfo column]];

    // Recycles invisible petal views.
    [[self class] reverseArray:petalViews];

    while ([petalViews count] > 0) {
        XJPetalView* petalView = [petalViews lastObject];
        NSInteger row = [[[petalView layer] valueForKey:PETAL_VIEW_ROW_KEY] integerValue];
        CGRect petalViewFrame = [[pathInfo petalViewInfoForRow:row] frame];

        if (CGRectGetMaxY(petalViewFrame) > minY) {
            break;
        }

        [petalView removeFromSuperview];
        [petalViews removeLastObject];
        [self pushPetalViewForReuse:petalView];
    }

    [[self class] reverseArray:petalViews];

    while ([petalViews count] > 0) {
        XJPetalView* petalView = [petalViews lastObject];
        NSInteger row = [[[petalView layer] valueForKey:PETAL_VIEW_ROW_KEY] integerValue];
        CGRect petalViewFrame = [[pathInfo petalViewInfoForRow:row] frame];

        if (CGRectGetMinY(petalViewFrame) < maxY) {
            break;
        }

        [petalView removeFromSuperview];
        [petalViews removeLastObject];
        [self pushPetalViewForReuse:petalView];
    }

    // Tiles visible petal views.
    if ([petalViews count] == 0) {
        [self reloadPetalViewsOnPath:pathInfo petalViewList:petalViews minimumY:minY maximumY:maxY];
    } else {
        [[self class] reverseArray:petalViews];

        NSInteger firstRow = [[[[petalViews lastObject] layer] valueForKey:PETAL_VIEW_ROW_KEY] integerValue];

        for (firstRow--; firstRow >= 0; --firstRow) {
            XJPetalViewInfo* petalViewInfo = [pathInfo petalViewInfoForRow:firstRow];
            CGRect petalViewFrame = [[pathInfo petalViewInfoForRow:firstRow] frame];

            if (CGRectGetMaxY(petalViewFrame) <= minY) {
                break;
            }

            [self tilePetalViewWithInfo:petalViewInfo petalViewList:petalViews];
        }

        [[self class] reverseArray:petalViews];

        NSInteger lastRow = [[[[petalViews lastObject] layer] valueForKey:PETAL_VIEW_ROW_KEY] integerValue];

        for (lastRow++; lastRow < [pathInfo numberOfPetals]; ++lastRow) {
            XJPetalViewInfo* petalViewInfo = [pathInfo petalViewInfoForRow:lastRow];
            CGRect petalViewFrame = [petalViewInfo frame];

            if (CGRectGetMinY(petalViewFrame) >= maxY) {
                break;
            }

            [self tilePetalViewWithInfo:petalViewInfo petalViewList:petalViews];
        }
    }
}

- (void) tilePetalViewWithInfo:(XJPetalViewInfo*)petalViewInfo petalViewList:(NSMutableArray*)petalViews {
    XJPetalView* petalView = [[self dataSource] waterfallView:self petalViewAtIndex:[petalViewInfo index]];

    [[petalView layer] setValue:[NSNumber numberWithInteger:[petalViewInfo row]] forKey:PETAL_VIEW_ROW_KEY];
    [petalView setFrame:CGRectIntegral([petalViewInfo frame])];
    [petalViews addObject:petalView];
    [self addSubview:petalView];
}

- (void) reloadPetalViewsOnPath:(XJWaterfallPathInfo*)pathInfo petalViewList:(NSMutableArray*)petalViews
        minimumY:(CGFloat)minY maximumY:(CGFloat)maxY {
    NSInteger row = [self firstRowBelowY:minY inPath:pathInfo];

    for (; row < [pathInfo numberOfPetals]; ++row) {
        XJPetalViewInfo* petalViewInfo = [pathInfo petalViewInfoForRow:row];
        CGRect petalViewFrame = [petalViewInfo frame];

        if (CGRectGetMinY(petalViewFrame) >= maxY) {
            break;
        }

        [self tilePetalViewWithInfo:petalViewInfo petalViewList:petalViews];
    }
}

- (NSInteger) firstRowBelowY:(CGFloat)y inPath:(XJWaterfallPathInfo*)pathInfo {
    NSInteger row = [pathInfo numberOfPetals];
    NSInteger left = 0;
    NSInteger right = [pathInfo numberOfPetals] - 1;

    while (left <= right) {
        NSInteger mid = (left + right) / 2;

        if (CGRectGetMinY([[pathInfo petalViewInfoForRow:mid] frame]) < y) {
            left = mid + 1;
        } else {
            right = mid - 1;
            row = MIN(row, mid);
        }
    }

    return row;
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