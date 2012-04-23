//
//  AppDelegate.m
//  XJWaterfallViewDemo
//
//  Created by Xiantao Jiao on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate

#pragma mark - Public methods

@synthesize window = _window;


#pragma mark - UIApplicationDelegate protocol

- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    [self setWindow:[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];
    [[self window] setBackgroundColor:[UIColor blackColor]];
    [[self window] makeKeyAndVisible];

    return YES;
}

- (void) applicationWillResignActive:(UIApplication*)application {
}

- (void) applicationDidEnterBackground:(UIApplication*)application {
}

- (void) applicationWillEnterForeground:(UIApplication*)application {
}

- (void) applicationDidBecomeActive:(UIApplication*)application {
}

- (void) applicationWillTerminate:(UIApplication*)application {
}

@end