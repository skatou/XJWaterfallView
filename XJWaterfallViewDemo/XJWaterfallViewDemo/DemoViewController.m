//
//  DemoViewController.m
//  XJWaterfallViewDemo
//
//  Created by Xiantao Jiao on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <stdlib.h>
#import <time.h>

#import "XJPetalView.h"
#import "XJWaterfallView.h"

#import "DemoViewController.h"


@interface DemoViewController() <UIScrollViewDelegate, XJWaterfallViewDataSource> {
@private
    XJWaterfallView* waterfallView_;
    NSInteger numberOfPetals_;
    bool isLoading_;
}
@property (nonatomic, strong) XJWaterfallView* waterfallView;

- (void) loadMorePetals:(void (^)())onComplete;
@end


@implementation DemoViewController

#pragma mark - UIViewController methods

- (void) loadView {
    [self setView:[[UIView alloc] initWithFrame:CGRectZero]];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    [[self view] addSubview:[self waterfallView]];

    srand(time(NULL));
    rand();
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    numberOfPetals_ = 100;
    [[self waterfallView] reloadData];
}


#pragma mark - UIScrollViewDelegate protocol

- (void) scrollViewDidScroll:(UIScrollView*)scrollView {
    if ([[self waterfallView] contentOffset].y + [[self waterfallView] bounds].size.height >
            [[self waterfallView] contentSize].height) {
        [self loadMorePetals:^{
            [[self waterfallView] appendPetals];
        }];
    }
}


#pragma mark - XJWaterfallViewDataSource protocol

- (NSUInteger) numberOfPetalsForWaterfallView:(XJWaterfallView*)waterfallView {
    return numberOfPetals_;
}

- (CGFloat) waterfallView:(XJWaterfallView*)waterfallView normalizedHeightOfPetalViewAtIndex:(NSUInteger)index {
    return 0.5f + 2.0f * ((CGFloat) rand() / INT_MAX);
}

- (XJPetalView*) waterfallView:(XJWaterfallView*)waterfallView petalViewAtIndex:(NSUInteger)index {
    static NSString* IDENTIFIER = @"__ID__";
    XJPetalView* petalView = [waterfallView dequeueReusablePetalViewWithIdentifier:IDENTIFIER];

    if (petalView == nil) {
        petalView = [[XJPetalView alloc] initWithReuseIdentifier:IDENTIFIER];
        [petalView setBackgroundColor:[UIColor lightGrayColor]];
    }

    return petalView;
}


#pragma mark - Private methods

@synthesize waterfallView = waterfallView_;

- (XJWaterfallView*) waterfallView {
    if (waterfallView_ == nil) {
        [self setWaterfallView:[[XJWaterfallView alloc] initWithFrame:[[self view] bounds]]];
        [waterfallView_ setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        [waterfallView_ setDataSource:self];
        [waterfallView_ setDelegate:self];
    }

    return waterfallView_;
}

- (void) loadMorePetals:(void (^)())onComplete {
    if (!isLoading_) {
        isLoading_ = true;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void) {
            numberOfPetals_ += 100;
            isLoading_ = false;

            if (onComplete != nil) {
                onComplete();
            }
        });
    }
}

@end