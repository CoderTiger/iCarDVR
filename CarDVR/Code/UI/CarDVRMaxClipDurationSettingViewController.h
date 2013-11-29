//
//  CarDVRMaxClipDurationSettingViewController.h
//  CarDVR
//
//  Created by yxd on 13-11-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CarDVRMaxClipDurationSettingViewController;
@protocol CarDVRMaxClipDurationSettingViewControllerDelegate <NSObject>

- (void)maxClipDurationSettingViewControllerDone:(CarDVRMaxClipDurationSettingViewController *)sender;

@end

@interface CarDVRMaxClipDurationSettingViewController : UIViewController

@property (weak, nonatomic) id<CarDVRMaxClipDurationSettingViewControllerDelegate> delegate;
@property (assign, nonatomic) NSUInteger maxClipDuration;

@end
