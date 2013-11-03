//
//  CarDVRPlayerViewController.h
//  CarDVR
//
//  Created by yxd on 13-11-3.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CarDVRVideoItem;

@interface CarDVRPlayerViewController : UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
            videoItem:(CarDVRVideoItem *)aVideoItem;

@end
