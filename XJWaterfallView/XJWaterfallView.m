//
//  XJWaterfallView.m
//  XJWaterfallView
//
//  Created by Xiantao Jiao on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XJPetalView.h"

#import "XJWaterfallView.h"


@interface XJWaterfallView() {
@private
    __weak id<XJWaterfallViewDataSource> dataSource_;
    UIView* backgroundView_;
    NSMutableArray* visiblePetalViews_;
    NSMutableDictionary* reusablePetalViews_;
    NSUInteger numberOfPaths_;
    NSArray* pathWidths_;
    NSMutableArray* currentPathHeights_;
}
@property (nonatomic, strong) NSMutableArray* visiblePetalViews;
@property (nonatomic, strong) NSMutableDictionary* reusablePetalViews;
@property (nonatomic, assign) NSUInteger numberOfPaths;
@property (nonatomic, strong) NSArray* pathWidths;
@property (nonatomic, strong) NSMutableArray* currentPathHeights;

- (CGFloat) maximumValueInArray:(NSArray*)array;
- (NSInteger) indexOfMinimumValueInArray:(NSArray*)array;

- (void) prepareParametersNeedForLayout;
- (void) resetContentSizeByAppendingPetalViewsFromIndex:(NSUInteger)index;

- (void) pushReusablePetalView:(XJPetalView*)petalView;
- (XJPetalView*) popReusablePetalViewWithIdentifier:(NSString*)identifier;
@end


@implementation XJWaterfallView

#pragma mark - Private static members

const static NSUInteger DEFAULT_NUMBER_OF_PATHS = 3;
const static CGFloat RIGHT_MARGIN = 15.0f;
const static CGFloat PADDING = 10.0f;


#pragma mark - Public methods

- (UIView*) backgroundView {
    if (backgroundView_ == nil) {
        [self setBackgroundView:[[UIView alloc] initWithFrame:CGRectZero]];
        [backgroundView_ setBackgroundColor:[UIColor whiteColor]];
    }

    return backgroundView_;
}

- (void) setBackgroundView:(UIView*)backgroundView {
    if (backgroundView != backgroundView_) {
        if ([backgroundView_ superview] == self) {
            [backgroundView_ removeFromSuperview];
        }

        backgroundView_ = backgroundView;
    }
}

@synthesize dataSource = dataSource_;

- (void) setDataSource:(id<XJWaterfallViewDataSource>)dataSource {
    if (dataSource != dataSource_) {
        dataSource_ = dataSource;
        [self reloadData];
    }
}

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
    [self prepareParametersNeedForLayout];
    [self resetContentSizeByAppendingPetalViewsFromIndex:0];

    // Scrolls to top and tiles new petal views.
    [self scrollsToTop];
}


#pragma mark - UIView methods

- (void) layoutSubviews {
    [super layoutSubviews];

    CGRect bounds = [self bounds];

    [backgroundView_ setFrame:bounds];
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
@synthesize pathWidths = pathWidths_;
@synthesize currentPathHeights = currentPathHeights_;

- (CGFloat) maximumValueInArray:(NSArray*)array {
    return [[array valueForKeyPath:@"@max.floatValue"] floatValue];
}

- (NSInteger) indexOfMinimumValueInArray:(NSArray*)array {
    __block NSInteger index = NSNotFound;
    __block NSNumber* minValue = [NSNumber numberWithFloat:0.0f];

    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        NSNumber* now = (NSNumber*) obj;

        if ([now compare:minValue] == NSOrderedAscending) {
            index = idx;
            minValue = now;
        }
    }];

    return index;
}

- (void) prepareParametersNeedForLayout {
    if ([[self dataSource] respondsToSelector:@selector(numberOfPathsForWaterfallView:)] == YES) {
        [self setNumberOfPaths:[[self dataSource] numberOfPathsForWaterfallView:self]];
    } else {
        [self setNumberOfPaths:DEFAULT_NUMBER_OF_PATHS];
    }

    if ([self numberOfPaths] == 0) {
        [self setPathWidths:nil];
        [self setCurrentPathHeights:nil];

        return;
    }

    CGFloat spaceWidth = [self numberOfPaths] * PADDING + RIGHT_MARGIN;
    CGFloat fixedPathWidth = -1.0f;

    if ([[self dataSource] respondsToSelector:@selector(waterfallView:widthOfPathOnColumn:)] == NO) {
        fixedPathWidth = ([self bounds].size.width - spaceWidth) / [self numberOfPaths];

        if (fixedPathWidth < 0.0f) {
            fixedPathWidth = 0.0f;
        }
    }

    NSMutableArray* pathWidths = [NSMutableArray arrayWithCapacity:0];
    NSMutableArray* pathHeights = [NSMutableArray arrayWithCapacity:0];

    for (NSUInteger col = 0; col < [self numberOfPaths]; ++col) {
        if (fixedPathWidth < 0.0f) {
            [pathWidths addObject:[NSNumber numberWithFloat:[[self dataSource]
                waterfallView:self widthOfPathOnColumn:col]]];
        } else {
            [pathWidths addObject:[NSNumber numberWithFloat:fixedPathWidth]];
        }

        [pathHeights addObject:[NSNumber numberWithFloat:PADDING]];
    }

    [self setPathWidths:pathWidths];
    [self setCurrentPathHeights:pathHeights];
}

- (void) resetContentSizeByAppendingPetalViewsFromIndex:(NSUInteger)index {
    if ([self numberOfPaths] == 0) {
        [self setContentSize:[self bounds].size];

        return;
    }

    CGFloat spaceWidth = [self numberOfPaths] * PADDING + RIGHT_MARGIN;
    CGRect contentFrame = CGRectMake(0.0f, 0.0f, spaceWidth, 0.0f);

    // Calculates content width.
    for (NSUInteger col = 0; col < [self numberOfPaths]; ++col) {
        contentFrame.size.width += [[[self pathWidths] objectAtIndex:col] floatValue];
    }

    // Calculates content height.
    NSUInteger numberOfPetal = [[self dataSource] numberOfPetalsForWaterfallView:self];
    NSMutableArray* pathHeights = [NSMutableArray arrayWithArray:[self pathWidths]];

    for (; index < numberOfPetal; ++index) {
        NSInteger pathColumn = [self indexOfMinimumValueInArray:pathHeights];
        CGFloat minValue = [[pathHeights objectAtIndex:pathColumn] floatValue];
        CGFloat normalizedHeight = [[self dataSource] waterfallView:self normalizedHeightOfPetalViewAtIndex:index];
        CGFloat height = normalizedHeight * [[[self pathWidths] objectAtIndex:pathColumn] floatValue];

        [pathHeights replaceObjectAtIndex:pathColumn
            withObject:[NSNumber numberWithFloat:(minValue + PADDING + height)]];
    }

    contentFrame.size.height = [self maximumValueInArray:pathHeights];

    // Resets content size.
    contentFrame = CGRectIntegral(contentFrame);
    [self setContentSize:contentFrame.size];
}

- (void) pushReusablePetalView:(XJPetalView*)petalView {
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

    if ([petalViews count] > 0) {
        XJPetalView* petalView = [petalViews lastObject];

        [petalViews removeLastObject];

        return petalView;
    } else {
        return nil;
    }
}

@end