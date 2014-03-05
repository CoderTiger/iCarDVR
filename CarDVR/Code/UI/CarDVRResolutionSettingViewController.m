//
//  CarDVRResolutionSettingViewController.m
//  CarDVR
//
//  Created by yxd on 14-3-5.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import "CarDVRResolutionSettingViewController.h"

@interface CarDVRResolutionSettingViewController ()<UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *videoResolutionHighLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoResolutionMiddleLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoResolutionLowLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoResolution352x288Label;
@property (weak, nonatomic) IBOutlet UILabel *videoResolution640x480Label;
@property (weak, nonatomic) IBOutlet UILabel *videoResolution1280x720Label;
@property (weak, nonatomic) IBOutlet UILabel *videoResolution1920x1080Label;
@property (weak, nonatomic) IBOutlet UILabel *videoResolution960x540iLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoResolution1280x720iLabel;


#pragma mark - Private methods
- (NSIndexPath *)indexPathForVideoResolution:(CarDVRVideoResolution)videoResolution;
- (CarDVRVideoResolution)videoResolutionForIndexPath:(NSIndexPath *)indexPath;

@end

@implementation CarDVRResolutionSettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //
    // Localize text ...
    //
    self.title = NSLocalizedString( @"resolutionSettingViewTitle", @"Resolution" );
    self.videoResolutionHighLabel.text = NSLocalizedString( @"videoResolutionHigh", @"High" );
    self.videoResolutionMiddleLabel.text = NSLocalizedString( @"videoResolutionMiddle", @"Middle" );
    self.videoResolutionLowLabel.text = NSLocalizedString( @"videoResolutionLow", @"Low" );
    self.videoResolution352x288Label.text = NSLocalizedString( @"videoResolution352x288", @"352x288" );
    self.videoResolution640x480Label.text = NSLocalizedString( @"videoResolution640x480", @"640x480" );
    self.videoResolution1280x720iLabel.text = NSLocalizedString( @"videoResolution1280x720", @"1280x720" );
    self.videoResolution1920x1080Label.text = NSLocalizedString( @"videoResolution1920x1080", @"1920x1080" );
    self.videoResolution960x540iLabel.text = NSLocalizedString( @"videoResolutioniFrame960x540", @"960x540i" );
    self.videoResolution1280x720iLabel.text = NSLocalizedString( @"videoResolutioniFrame1280x720", @"1280x720i" );
}

- (void)viewWillAppear:(BOOL)animated
{
#pragma unused( animated )
    //
    // set checkmark for current video resolution
    //
    NSIndexPath *indexPath = [self indexPathForVideoResolution:self.videoResolution];
    [self.tableView selectRowAtIndexPath:indexPath
                                animated:NO
                          scrollPosition:UITableViewScrollPositionTop];
    [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
#pragma unused( animated )
    if ( self.delegate )
    {
        [self.delegate resolutionSettingViewControllerDone:self];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - from UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *prevSelectedIndexPath = [self indexPathForVideoResolution:self.videoResolution];
    if ( prevSelectedIndexPath )
    {
        [tableView cellForRowAtIndexPath:prevSelectedIndexPath].accessoryType = UITableViewCellAccessoryNone;
    }
    self.videoResolution = [self videoResolutionForIndexPath:indexPath];
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
}

#pragma mark - Private methods
- (NSIndexPath *)indexPathForVideoResolution:(CarDVRVideoResolution)videoResolution
{
    NSInteger section = 0;
    NSInteger row = 0;
    switch ( videoResolution )
    {
        case kCarDVRVideoResolutionHigh:
            row = 0;
            break;
        case kCarDVRVideoResolutionMiddle:
            row = 1;
            break;
        case kCarDVRVideoResolutionLow:
            row = 2;
            break;
        case kCarDVRVideoResolution352x288:
            row = 3;
            break;
        case kCarDVRVideoResolution640x480:
            row = 4;
            break;
        case kCarDVRVideoResolution1280x720:
            row = 5;
            break;
        case kCarDVRVideoResolution1920x1080:
            row = 6;
            break;
        case kCarDVRVideoResolutioniFrame960x540:
            row = 7;
            break;
        case kCarDVRVideoResolutioniFrame1280x720:
            row = 8;
            break;
        default:
            NSAssert1( NO, @"[Error]unknown CarDVRVideoResolution value: %d", (NSInteger)videoResolution );
            break;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    return indexPath;
}

- (CarDVRVideoResolution)videoResolutionForIndexPath:(NSIndexPath *)indexPath
{
    CarDVRVideoResolution videoResolution = kCarDVRVideoResolutionHigh;
    switch ( indexPath.row )
    {
        case 0:
            videoResolution = kCarDVRVideoResolutionHigh;
            break;
        case 1:
            videoResolution = kCarDVRVideoResolutionMiddle;
            break;
        case 2:
            videoResolution = kCarDVRVideoResolutionLow;
            break;
        case 3:
            videoResolution = kCarDVRVideoResolution352x288;
            break;
        case 4:
            videoResolution = kCarDVRVideoResolution640x480;
            break;
        case 5:
            videoResolution = kCarDVRVideoResolution1280x720;
            break;
        case 6:
            videoResolution = kCarDVRVideoResolution1920x1080;
            break;
        case 7:
            videoResolution = kCarDVRVideoResolutioniFrame960x540;
            break;
        case 8:
            videoResolution = kCarDVRVideoResolutioniFrame1280x720;
            break;
        default:
            NSAssert1( NO, @"[Error]invalid resolution row: %d", indexPath.row );
            break;
    }
    return videoResolution;
}

@end
