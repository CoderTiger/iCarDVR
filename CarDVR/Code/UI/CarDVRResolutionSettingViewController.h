//
//  CarDVRResolutionSettingViewController.h
//  CarDVR
//
//  Created by yxd on 14-3-5.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CarDVRVideoCapturerConstants.h"

@class CarDVRResolutionSettingViewController;
@protocol CarDVRResolutionSettingViewControllerDelegate <NSObject>

- (void)resolutionSettingViewControllerDone:(CarDVRResolutionSettingViewController *)sendor;

@end

@interface CarDVRResolutionSettingViewController : UITableViewController

@property (weak, nonatomic) id<CarDVRResolutionSettingViewControllerDelegate> delegate;
@property (assign, nonatomic) CarDVRVideoResolution videoResolution;

@end
