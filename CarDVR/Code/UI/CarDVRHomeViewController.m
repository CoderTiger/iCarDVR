//
//  CarDVRHomeViewController.m
//  CarDVR
//
//  Created by yxd on 13-10-24.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRHomeViewController.h"
#import "CarDVRRecentsViewController.h"
#import "CarDVRStarredViewController.h"
#import "CarDVRSettingsViewController.h"

@interface CarDVRHomeViewController ()

@property (weak, nonatomic) CarDVRPathHelper *pathHelper;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingBarButtonItem;

@end

@implementation CarDVRHomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = NSLocalizedString( @"homeViewTitle", @"Home" );
    self.settingBarButtonItem.title = NSLocalizedString( @"settingsViewTitle", @"Settings" );
//    UIBarButtonItem *settingsButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString( @"settingsViewTitle", @"Settings" )
//                                                                           style:UIBarButtonItemStylePlain
//                                                                          target:self
//                                                                          action:@selector(settingsButtonItemTouched)];
//    self.navigationItem.rightBarButtonItem = settingsButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = NO;
}

@end
