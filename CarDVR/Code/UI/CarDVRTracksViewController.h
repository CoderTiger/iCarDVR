//
//  CarDVRTracksViewController.h
//  CarDVR
//
//  Created by yxd on 14-3-12.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CarDVRVideoItem;
@class CarDVRSettings;

@interface CarDVRTracksViewController : UIViewController

@property (weak, nonatomic) CarDVRVideoItem *videoItem;
@property (weak, nonatomic) CarDVRSettings *settings;

@end
