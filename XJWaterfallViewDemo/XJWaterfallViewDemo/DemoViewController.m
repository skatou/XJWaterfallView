//
//  DemoViewController.m
//  XJWaterfallViewDemo
//
//  Created by Xiantao Jiao on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XJWaterfallView.h"

#import "DemoViewController.h"


@interface DemoViewController() {
@private
    XJWaterfallView* waterfallView_;
}
@property (nonatomic, strong) XJWaterfallView* waterfallView;
@end


@implementation DemoViewController

#pragma mark - UIViewController methods

- (void) loadView {
    [self setView:[[UIView alloc] initWithFrame:CGRectZero]];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    [[self view] addSubview:[self waterfallView]];
}


#pragma mark - Private methods

@synthesize waterfallView = waterfallView_;

- (XJWaterfallView*) waterfallView {
    if (waterfallView_ == nil) {
        [self setWaterfallView:[[XJWaterfallView alloc] initWithFrame:[[self view] bounds]]];
        [waterfallView_ setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        [waterfallView_ setContentSize:CGSizeMake(5000.0f, 500.0f)];
    }

    return waterfallView_;
}

@end