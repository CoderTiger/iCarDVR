//
//  CarDVRSettingsViewController.m
//  CarDVR
//
//  Created by yxd on 13-10-30.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRSettingsViewController.h"
#import "CarDVRSettings.h"
#import "CarDVRVideoCapturerConstants.h"
#import "CarDVRMaxClipDurationSettingViewController.h"
#import "CarDVRResolutionSettingViewController.h"

static const NSInteger kCarDVRSettingsSectionStorageInfo = 0;
static const NSInteger kCarDVRSettingsSectionVideo = 1;
static const NSInteger kCarDVRSettingsSectionAbout = 2;
static NSString *const kShowMaxClipDurationSettingSegueId = @"kShowMaxClipDurationSettingSegueId";
static NSString *const kShowResolutionSettingSegueId = @"kShowResolutionSettingSegueId";
static const NSUInteger kVideoFrameRateRangePerLevel = 5;
static const NSUInteger kMaxCountOfVideoFrameRateLevel = 6;

@interface CarDVRSettingsViewController ()
<
CarDVRMaxClipDurationSettingViewControllerDelegate,
CarDVRResolutionSettingViewControllerDelegate
>

@property (assign, nonatomic) CarDVRVideoResolution videoResolution;

@property (weak, nonatomic) IBOutlet UILabel *storageUsageLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet UILabel *maxRecordingClipsLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxRecordingClipsValueLable;
@property (weak, nonatomic) IBOutlet UIStepper *maxRecordingClipsStepper;
@property (weak, nonatomic) IBOutlet UILabel *maxClipDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxClipDurationValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *resolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *resolutionValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *frameRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *frameRateValueLabel;
@property (weak, nonatomic) IBOutlet UIStepper *frameRateStepper;
@property (weak, nonatomic) IBOutlet UILabel *aboutBriefLabel;

- (IBAction)doneBarButtonItemTouched:(id)sender;
- (IBAction)cancelBarButtonItemTouched:(id)sender;
- (IBAction)maxRecordingClipsValueChanged:(id)sender;
- (IBAction)frameRateValueChanged:(id)sender;

#pragma mark - Private methods
- (void)loadVideoSettings;
- (void)setMaxRecordingClipsValue:(NSUInteger)count andUpdateStepper:(BOOL)update;
- (void)setMaxClipDurationValue:(NSUInteger)seconds;
- (void)setResolutionValueLabelValue:(CarDVRVideoResolution)videoResolution;
- (void)setFrameRateLevelValue:(NSUInteger)frameRateLevel andUpdateStepper:(BOOL)update;

@end

@implementation CarDVRSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = NSLocalizedString( @"settingsViewTitle", @"Settings" );
    self.maxRecordingClipsLabel.text = NSLocalizedString( @"maxRecordingClipsLabel", nil );
    self.maxClipDurationLabel.text = NSLocalizedString( @"maxClipDurationLabel", nil );
    self.resolutionLabel.text = NSLocalizedString( @"resolutionLabel", nil );
    self.frameRateLabel.text = NSLocalizedString( @"frameRateLabel", nil );
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *appName = [mainBundle objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleNameKey];
    NSString *appVersion = [mainBundle objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleVersionKey];
    self.aboutBriefLabel.text = [NSString stringWithFormat:NSLocalizedString( @"aboutBriefLabel", nil ), appName, appVersion];
    [_settings beginEditing];
    [self loadVideoSettings];
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
    [self.settings.storageInfo getStorageUsageUsingBlock:^(NSNumber *totalSpace, NSNumber *freeSpace) {
        unsigned long long totalBytes = [totalSpace unsignedLongLongValue];
        unsigned long long freeBytes = [freeSpace unsignedLongLongValue];
        double freePercent = (double)freeBytes / (double)totalBytes * 100;
        NSString *storageUsage;
        if ( freeBytes < 1024 )
        {
            storageUsage = [NSString stringWithFormat:NSLocalizedString( @"storageInfoByteFormat", nil ),
                            freePercent, freeBytes];
        }
        else if ( freeBytes < 1024 * 1024 )
        {
            storageUsage = [NSString stringWithFormat:NSLocalizedString( @"storageInfoKBFormat", nil ),
                            freePercent, freeBytes/1024.0];
        }
        else if ( freeBytes < 1024 * 1024 * 1024 )
        {
            storageUsage = [NSString stringWithFormat:NSLocalizedString( @"storageInfoMBFormat", nil ),
                            freePercent, freeBytes/(1024.0*1024.0)];
        }
        else
        {
            storageUsage = [NSString stringWithFormat:NSLocalizedString( @"storageInfoGBFormat", nil ),
                            freePercent, freeBytes/(1024.0*1024.0*1024.0)];
        }
        dispatch_async( dispatch_get_main_queue(), ^{
            self.storageUsageLabel.text = storageUsage;
        });
    }];
}

- (IBAction)doneBarButtonItemTouched:(id)sender
{
    [self.settings commitEditing];
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (IBAction)cancelBarButtonItemTouched:(id)sender
{
    [self.settings cancelEditing];
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (IBAction)maxRecordingClipsValueChanged:(id)sender
{
    UIStepper *stepper = sender;
    NSUInteger maxRecordingClipsCount = (NSUInteger)stepper.value;
    [self.settings setMaxCountOfRecordingClips:[NSNumber numberWithUnsignedInteger:maxRecordingClipsCount]];
    [self setMaxRecordingClipsValue:maxRecordingClipsCount andUpdateStepper:NO];
}

- (IBAction)frameRateValueChanged:(id)sender
{
    UIStepper *stepper = sender;
    NSUInteger frameRateLevel = (NSUInteger)stepper.value;
    [self.settings setVideoFrameRate:[NSNumber numberWithUnsignedInteger:( frameRateLevel + 1 ) * kVideoFrameRateRangePerLevel]];
    [self setFrameRateLevelValue:frameRateLevel andUpdateStepper:NO];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
#pragma unused( tableView )
    NSString *title;
    switch ( section )
    {
        case kCarDVRSettingsSectionVideo:
            title = NSLocalizedString( @"settingsSectionVideo", @"Video" );
            break;
        case kCarDVRSettingsSectionStorageInfo:
            title = NSLocalizedString( @"settingsSectionStorageInfo", @"Memory Info" );
            break;
        case kCarDVRSettingsSectionAbout:
            title = NSLocalizedString( @"settingsSectionAbout", @"About" );
            break;
        default:
            NSAssert( NO, @"It should NOT be executed here." );
            break;
    }
    return title;
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ( [segue.identifier isEqualToString:kShowMaxClipDurationSettingSegueId] )
    {
        CarDVRMaxClipDurationSettingViewController *maxClipDurationSettingViewController = segue.destinationViewController;
        maxClipDurationSettingViewController.maxClipDuration = self.settings.maxRecordingDurationPerClip.unsignedIntegerValue;
        maxClipDurationSettingViewController.delegate = self;
    }
    else if ( [segue.identifier isEqualToString:kShowResolutionSettingSegueId] )
    {
        CarDVRResolutionSettingViewController *resolutionSettingViewController = segue.destinationViewController;
        resolutionSettingViewController.videoResolution = self.settings.videoResolution.intValue;
        resolutionSettingViewController.delegate = self;
    }
}

#pragma mark - from CarDVRMaxClipDurationSettingViewControllerDelegate
- (void)maxClipDurationSettingViewControllerDone:(CarDVRMaxClipDurationSettingViewController *)sender
{
    [self setMaxClipDurationValue:sender.maxClipDuration];
    [self.settings setMaxRecordingDurationPerClip:[NSNumber numberWithUnsignedInteger:sender.maxClipDuration]];
}

#pragma mark - from CarDVRResolutionSettingViewControllerDelegate
- (void)resolutionSettingViewControllerDone:(CarDVRResolutionSettingViewController *)sendor
{
    [self setResolutionValueLabelValue:sendor.videoResolution];
    [self.settings setVideoResolution:[NSNumber numberWithInteger:self.videoResolution]];
}

#pragma mark - Private methods
- (void)loadVideoSettings
{
    [self setMaxRecordingClipsValue:self.settings.maxCountOfRecordingClips.unsignedIntegerValue andUpdateStepper:YES];
    [self setMaxClipDurationValue:self.settings.maxRecordingDurationPerClip.unsignedIntegerValue];
    [self setResolutionValueLabelValue:self.settings.videoResolution.integerValue];
    NSUInteger frameRateLevel = self.settings.videoFrameRate.unsignedIntegerValue / kVideoFrameRateRangePerLevel - 1;
    [self setFrameRateLevelValue:frameRateLevel andUpdateStepper:YES];
}

- (void)setMaxRecordingClipsValue:(NSUInteger)count andUpdateStepper:(BOOL)update
{
    self.maxRecordingClipsValueLable.text = [NSString stringWithFormat:@"%u", count];
    if ( update )
    {
        self.maxRecordingClipsStepper.value = count;
    }
}

- (void)setMaxClipDurationValue:(NSUInteger)seconds
{
    if ( seconds < 60 )// if < 60 seconds
    {
        self.maxClipDurationValueLabel.text = [NSString stringWithFormat:NSLocalizedString( @"secondsDuration", nil ), seconds];
    }
    else if ( seconds == 60 )
    {
        self.maxClipDurationValueLabel.text = [NSString stringWithFormat:NSLocalizedString( @"minuteDuration", nil ), 1];
    }
    else if ( ( seconds % 60 )== 0 )
    {
        self.maxClipDurationValueLabel.text = [NSString stringWithFormat:NSLocalizedString( @"minutesDuration", nil ), seconds / 60];
    }
    else
    {
        self.maxClipDurationValueLabel.text = [NSString stringWithFormat:NSLocalizedString( @"maxClipDurationValueLabel", nil ),
                                               seconds / 60, seconds % 60];
    }
}

- (void)setResolutionValueLabelValue:(CarDVRVideoResolution)videoResolution
{
    _videoResolution = videoResolution;
    switch ( videoResolution )
    {
        case kCarDVRVideoResolutionHigh:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoResolutionHigh", @"High" );
            break;
        case kCarDVRVideoResolutionMiddle:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoResolutionMiddle", @"Middle" );
            break;
        case kCarDVRVideoResolutionLow:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoResolutionLow", @"Low" );
            break;
        case kCarDVRVideoResolution352x288:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoResolution352x288", @"352x288" );
            break;
        case kCarDVRVideoResolution640x480:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoResolution640x480", @"640x480" );
            break;
        case kCarDVRVideoResolution1280x720:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoResolution1280x720", @"1280x720" );
            break;
        case kCarDVRVideoResolution1920x1080:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoResolution1920x1080", @"1920x1080" );
            break;
        case kCarDVRVideoResolutioniFrame960x540:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoResolutioniFrame960x540", @"960x540i" );
            break;
        case kCarDVRVideoResolutioniFrame1280x720:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoResolutioniFrame1280x720", @"1280x720i" );
            break;
        default:
            _videoResolution = kCarDVRVideoResolutionHigh;
            break;
    }
}

- (void)setFrameRateLevelValue:(NSUInteger)frameRateLevel andUpdateStepper:(BOOL)update
{
    if ( frameRateLevel >= kMaxCountOfVideoFrameRateLevel )
    {
        frameRateLevel = kMaxCountOfVideoFrameRateLevel - 1;
    }
    NSUInteger frameRate = ( frameRateLevel + 1 ) * kVideoFrameRateRangePerLevel;
    self.frameRateValueLabel.text = [NSString stringWithFormat:NSLocalizedString( @"frameRateFormat", nil ), frameRate];
    if ( update )
    {
        [self.frameRateStepper setValue:frameRateLevel];
    }
}

@end
