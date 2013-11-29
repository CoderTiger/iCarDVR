//
//  CarDVRHomeViewController.h
//  CarDVR
//
//  Created by yxd on 13-10-24.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CarDVRPathHelper.h"

@class CarDVRSettings;

@interface CarDVRHomeViewController : UITabBarController

@property (weak, nonatomic) CarDVRSettings *settings;

@end
