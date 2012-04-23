//
//  AppDelegate.m
//  XJWaterfallViewDemo
//
//  Created by Xiantao Jiao on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DemoViewController.h"

#import "AppDelegate.h"


@implementation AppDelegate

#pragma mark - Public methods

@synthesize window = _window;

- (UIWindow*) window {
    if (_window == nil) {
        [self setWindow:[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]]];
        [_window setBackgroundColor:[UIColor blackColor]];
    }

    return _window;
}


#pragma mark - UIApplicationDelegate protocol

- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
    DemoViewController* demoViewController = [[DemoViewController alloc] init];
    UINavigationController* rootViewController =
        [[UINavigationController alloc] initWithRootViewController:demoViewController];

    [[rootViewController navigationBar] setBarStyle:UIBarStyleBlack];
    [[rootViewController toolbar] setBarStyle:UIBarStyleBlack];
    [[self window] setRootViewController:rootViewController];
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