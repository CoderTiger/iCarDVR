//
//  CarDVRStarredViewController.m
//  CarDVR
//
//  Created by yxd on 13-10-30.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRStarredViewController.h"

@interface CarDVRStarredViewController ()

@end

@implementation CarDVRStarredViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( self )
    {
        self.title = NSLocalizedString( @"starredViewTitle", @"Starred" );
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = NSLocalizedString( @"starredViewTitle", @"Starred" );
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = NSLocalizedString( @"starredViewTitle", @"Starred" );
    
    // Prevent 'recents' list view from being covered by navigation bar and tab bar.
    //    self.navigationController.navigationBar.translucent = NO;
    self.tabBarController.tabBar.translucent = NO;
    if ( [self respondsToSelector:@selector( edgesForExtendedLayout )] )
        self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
