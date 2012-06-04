//
//  XJPetalView.m
//  XJWaterfallView
//
//  Created by Xiantao Jiao on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XJPetalView.h"


@interface XJPetalView() {
@private
    NSString* reuseIdentifier_;
    UIImageView* imageView_;
}
@property (nonatomic, copy) NSString* reuseIdentifier;
@property (nonatomic, strong) UIImageView* imageView;

- (CGRect) imageViewFrame;
@end


@implementation XJPetalView

#pragma mark - Private statis members

const static CGFloat EDGE_MARGIN = 1.0f;


#pragma mark - Initializers and uninitializer

- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier {
    if ((self = [super initWithFrame:CGRectZero]) != nil) {
        [self setReuseIdentifier:reuseIdentifier];
    }

    return self;
}

- (void) dealloc {
    [self setReuseIdentifier:nil];
    [self setImageView:nil];
}


#pragma mark - Public methods

@synthesize reuseIdentifier = reuseIdentifier_;
@synthesize imageView = imageView_;

- (UIImageView*) imageView {
    if (imageView_ == nil) {
        [self setImageView:[[UIImageView alloc] initWithFrame:CGRectZero]];
        [imageView_ setContentMode:UIViewContentModeScaleAspectFill];
    }

    return imageView_;
}

- (void) prepareForReuse {
    [imageView_ setImage:nil];
}


#pragma mark - UIView methods

- (void) layoutSubviews {
    [super layoutSubviews];
    [imageView_ setFrame:[self imageViewFrame]];
}


#pragma mark - Private methods

- (CGRect) imageViewFrame {
    return CGRectInset([self bounds], EDGE_MARGIN, EDGE_MARGIN);
}

@end