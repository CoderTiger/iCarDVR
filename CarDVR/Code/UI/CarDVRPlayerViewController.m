//
//  CarDVRPlayerViewController.m
//  CarDVR
//
//  Created by yxd on 13-11-3.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRPlayerViewController.h"
#import "CarDVRVideoItem.h"

@interface CarDVRPlayerViewController ()

@property (weak, nonatomic) CarDVRVideoItem *videoItem;

@end

@implementation CarDVRPlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
            videoItem:(CarDVRVideoItem *)aVideoItem
{
    NSAssert( aVideoItem != nil, @"aVideoItem should NOT be nil" );
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _videoItem = aVideoItem;
        self.title = [NSString stringWithFormat:NSLocalizedString( @"playerViewTitleFormat", nil ), _videoItem.fileName];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
