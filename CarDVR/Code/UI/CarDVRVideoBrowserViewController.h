//
//  CarDVRRecentsViewController.h
//  CarDVR
//
//  Created by yxd on 13-10-30.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    kCarDVRVideoBrowserViewControllerTypeUnkown,
    kCarDVRVideoBrowserViewControllerTypeRecents,
    kCarDVRVideoBrowserViewControllerTypeStarred
} CarDVRVideoBrowserViewControllerType;

@class CarDVRSettings;
@class CarDVRPathHelper;

@interface CarDVRVideoBrowserViewController : UIViewController

@property (weak, nonatomic) CarDVRSettings *settins;
@property (weak, nonatomic) CarDVRPathHelper *pathHelper;
@property (assign, nonatomic) CarDVRVideoBrowserViewControllerType type;
@property (assign, nonatomic) BOOL switchFromRecordingCamera;
@property (assign, nonatomic, getter = isEditable) BOOL editable;
@property (weak, nonatomic) CarDVRVideoBrowserViewController *ownerViewController;

@end
