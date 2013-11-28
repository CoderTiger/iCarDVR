//
//  AppDelegate.m
//  CarDVR
//
//  Created by yxd on 13-10-14.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRAppDelegate.h"
#import "CarDVRCameraViewController.h"
#import "CarDVRPathHelper.h"
#import "CarDVRSettings.h"

@interface CarDVRAppDelegate ()

@property (strong, nonatomic) UIViewController *mainViewController;

@end

@implementation CarDVRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _pathHelper = [[CarDVRPathHelper alloc] init];
    _settings = [[CarDVRSettings alloc] initWithPathHelper:_pathHelper];
    /*
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    self.mainViewController = [[CarDVRCameraViewController alloc] initWithNibName:@"CarDVRCameraViewController"
                                                                           bundle:nil];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.mainViewController];
    self.navigationController.navigationBarHidden = YES;
    self.window.rootViewController = self.navigationController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    */
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

@end
