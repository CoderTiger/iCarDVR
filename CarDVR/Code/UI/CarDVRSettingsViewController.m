//
//  CarDVRSettingsViewController.m
//  CarDVR
//
//  Created by yxd on 13-10-30.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRSettingsViewController.h"

@interface CarDVRSettingsViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *OKBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

- (IBAction)OKBarButtonItemTouched:(id)sender;
- (IBAction)cancelBarButtonItemTouched:(id)sender;

@end

@implementation CarDVRSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = NSLocalizedString( @"settingsViewTitle", @"Settings" );
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
#pragma unused( animated )
    self.navigationController.navigationBarHidden = NO;
}

- (IBAction)OKBarButtonItemTouched:(id)sender
{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (IBAction)cancelBarButtonItemTouched:(id)sender
{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

@end
