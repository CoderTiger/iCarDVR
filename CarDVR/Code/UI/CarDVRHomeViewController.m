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

- (void)settingsButtonItemTouched;

@end

@implementation CarDVRHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = NSLocalizedString( @"homeViewTitle", @"Home" );
        UIBarButtonItem *settingsButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings"
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:self action:@selector(settingsButtonItemTouched)];
        self.navigationItem.rightBarButtonItem = settingsButtonItem;
        CarDVRRecentsViewController *recentsViewController =
            [[CarDVRRecentsViewController alloc] initWithNibName:@"CarDVRRecentsViewController" bundle:nil];
        CarDVRStarredViewController *starredViewController =
            [[CarDVRStarredViewController alloc] initWithNibName:@"CarDVRStarredViewController" bundle:nil];
        self.viewControllers = @[recentsViewController, starredViewController];
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

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = NO;
}

- (void)settingsButtonItemTouched
{
    CarDVRSettingsViewController *settingsViewController =
        [[CarDVRSettingsViewController alloc] initWithNibName:@"CarDVRSettingsViewController" bundle:nil];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    [self.navigationController presentModalViewController:navigationController animated:YES];
}

@end
