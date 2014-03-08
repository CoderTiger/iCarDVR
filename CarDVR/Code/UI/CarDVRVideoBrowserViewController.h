//
//  CarDVRRecentsViewController.h
//  CarDVR
//
//  Created by yxd on 13-10-30.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CarDVRPathHelper.h"

typedef enum
{
    kCarDVRVideoBrowserViewControllerTypeUnkown,
    kCarDVRVideoBrowserViewControllerTypeRecents,
    kCarDVRVideoBrowserViewControllerTypeStarred
} CarDVRVideoBrowserViewControllerType;

@interface CarDVRVideoBrowserViewController : UIViewController

@property (assign, nonatomic) CarDVRVideoBrowserViewControllerType type;
@property (assign, nonatomic) BOOL switchFromRecordingCamera;

@end
