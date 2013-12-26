//
//  CarDVRPlayerViewController.h
//  CarDVR
//
//  Created by yxd on 13-11-3.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CarDVRVideoItem;

@interface CarDVRVideoDetailViewController : UITableViewController

@property (weak, nonatomic) CarDVRVideoItem *videoItem;

@end
