//
//  CarDVRSettingsViewController.m
//  CarDVR
//
//  Created by yxd on 13-10-30.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRSettingsViewController.h"

@interface CarDVRSettingsViewController ()

- (void)cancelButtonItemTouched;
- (void)doneButtonItemTouched;

@end

@implementation CarDVRSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = NSLocalizedString( @"settingsViewTitle", @"Settings" );
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancelButtonItemTouched)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(doneButtonItemTouched)];
        // Custom initialization
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

- (void)cancelButtonItemTouched
{
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)doneButtonItemTouched
{
    [self.navigationController dismissModalViewControllerAnimated:YES];
//    [self dismissModalViewControllerAnimated:YES];
}

@end
