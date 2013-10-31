//
//  AppDelegate.h
//  CarDVR
//
//  Created by yxd on 13-10-14.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CarDVRPathHelper;

@interface CarDVRAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) CarDVRPathHelper *pathHelper;

@end
