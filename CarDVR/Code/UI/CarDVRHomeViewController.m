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

static NSString *const kShowPreSettingsSegueId = @"kShowPreSettingsSegueId";
static const NSUInteger kTabRecentsIndex = 0;
static const NSUInteger kTabStarredIndex = 1;
static const NSUInteger kTabMaxCount = 2;

@interface CarDVRHomeViewController ()

@property (weak, nonatomic) CarDVRPathHelper *pathHelper;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingBarButtonItem;

@end

@implementation CarDVRHomeViewController

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
    self.settingBarButtonItem.title = NSLocalizedString( @"settingsViewTitle", @"Settings" );    
    self.navigationController.navigationBar.translucent = NO;
    if ( [self respondsToSelector:@selector( edgesForExtendedLayout )] )
        self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
    
    self.selectedIndex = self.settings.isStarred.boolValue ? kTabStarredIndex : kTabRecentsIndex;
    CarDVRVideoBrowserViewController *selectedView = [self.viewControllers objectAtIndex:self.selectedIndex];
    selectedView.switchFromRecordingCamera = self.switchFromRecordingCamera;
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
    if ( [segue.identifier isEqualToString:kShowPreSettingsSegueId] )
    {
        CarDVRSettingsViewController *preSettingsViewController = [[segue.destinationViewController viewControllers] objectAtIndex:0];
        preSettingsViewController.settings = self.settings;
    }
}

@end
