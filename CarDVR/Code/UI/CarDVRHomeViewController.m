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
static NSString *const kShowPreVideoEditableBrowserSegueId = @"kShowPreVideoEditableBrowserSegueId";

@interface CarDVRHomeViewController ()<UITabBarControllerDelegate>

@property (weak, readonly, nonatomic) CarDVRPathHelper *pathHelper;

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
    // Do any addit ional setup after loading the view from its nib.
    self.title = NSLocalizedString( @"homeViewTitle", @"Home" );
    self.navigationController.navigationBar.translucent = NO;
    if ( [self respondsToSelector:@selector( edgesForExtendedLayout )] )
        self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
    
    // todo: create wifi share button.
    /*
    UIBarButtonItem *editButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                    target:self
                                                                                    action:nil];
    UIBarButtonItem *shareOverWifiButtonItem = [[UIBarButtonItem alloc] initWithImage:nil
                                                                                style:UIBarButtonItemStylePlain
                                                                               target:self
                                                                               action:nil];
    shareOverWifiButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                            target:self
                                                                            action:nil];
    [self.navigationItem setRightBarButtonItems:@[shareOverWifiButtonItem, editButtonItem]];
    */
    
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:kShowPreVideoEditableBrowserSegueId] )
    {
        CarDVRVideoBrowserViewController *videoBrowserViewController = [[segue.destinationViewController viewControllers] objectAtIndex:0];
        
        videoBrowserViewController.switchFromRecordingCamera = self.switchFromRecordingCamera;
        videoBrowserViewController.settins = self.settings;
        videoBrowserViewController.pathHelper = self.pathHelper;
        
        videoBrowserViewController.editable = YES;
        videoBrowserViewController.ownerViewController = [self.viewControllers objectAtIndex:self.selectedIndex];
        switch ( self.selectedIndex )
        {
            case kTabRecentsIndex:
                videoBrowserViewController.type = kCarDVRVideoBrowserViewControllerTypeRecents;
                break;
            case kTabStarredIndex:
                videoBrowserViewController.type = kCarDVRVideoBrowserViewControllerTypeStarred;
                break;
            default:
                videoBrowserViewController.type = kCarDVRVideoBrowserViewControllerTypeUnkown;
                break;
        }
    }
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
