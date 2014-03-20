//
//  CarDVRHomeViewController.m
//  CarDVR
//
//  Created by yxd on 13-10-24.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRHomeViewController.h"
#import "CarDVRVideoBrowserViewController.h"
#import "CarDVRSettingsViewController.h"
#import "CarDVRSettings.h"
#import "CarDVRAppDelegate.h"

static const NSUInteger kTabRecentsIndex = 0;
static const NSUInteger kTabStarredIndex = 1;
static const NSUInteger kTabMaxCount = 2;

@interface CarDVRHomeViewController ()<UITabBarControllerDelegate>

@property (weak, readonly, nonatomic) CarDVRPathHelper *pathHelper;

- (IBAction)editButtonItemTouched:(id)sender;

@end

@implementation CarDVRHomeViewController

@synthesize pathHelper = _pathHelper;

- (CarDVRPathHelper *)pathHelper
{
    if ( !_pathHelper )
    {
        CarDVRAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        _pathHelper = appDelegate.pathHelper;
    }
    return _pathHelper;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( self )
    {
        NSAssert1( ( self.viewControllers.count == kTabMaxCount ),
                  @"Wrong count of tab views: %u",
                  self.viewControllers.count );
        if ( self.viewControllers.count != kTabMaxCount )
        {
            return nil;
        }
        ( (CarDVRVideoBrowserViewController *)self.viewControllers[kTabRecentsIndex] ).type = kCarDVRVideoBrowserViewControllerTypeRecents;
        ( (CarDVRVideoBrowserViewController *)self.viewControllers[kTabStarredIndex] ).type = kCarDVRVideoBrowserViewControllerTypeStarred;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = NSLocalizedString( @"homeViewTitle", @"Home" );
    self.navigationController.navigationBar.translucent = NO;
    if ( [self respondsToSelector:@selector( edgesForExtendedLayout )] )
        self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
   
    for ( CarDVRVideoBrowserViewController *videoBrowserViewController in self.viewControllers )
    {
        videoBrowserViewController.switchFromRecordingCamera = self.switchFromRecordingCamera;
        videoBrowserViewController.settins = self.settings;
        videoBrowserViewController.pathHelper = self.pathHelper;
    }
    self.selectedIndex = self.settings.isStarred.boolValue ? kTabStarredIndex : kTabRecentsIndex;
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

- (IBAction)editButtonItemTouched:(id)sender
{
}

#pragma mark - from UITabBarControllerDelegate
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
#pragma unused( tabBarController )
    if ( [viewController isKindOfClass:[CarDVRVideoBrowserViewController class]] )
    {
        // todo: complete
    }
}

@end
