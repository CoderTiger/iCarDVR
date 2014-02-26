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

static const NSInteger kCarDVRSettingsSectionStorageInfo = 0;
static const NSInteger kCarDVRSettingsSectionVideo = 1;
static const NSInteger kCarDVRSettingsSectionAbout = 2;
static NSString *const kShowMaxClipDurationSettingSegueId = @"kShowMaxClipDurationSettingSegueId";

@interface CarDVRSettingsViewController ()<CarDVRMaxClipDurationSettingViewControllerDelegate>

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
@property (weak, nonatomic) IBOutlet UIStepper *resolutionStepper;
@property (weak, nonatomic) IBOutlet UILabel *frameRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *frameRateValueLabel;
@property (weak, nonatomic) IBOutlet UIStepper *frameRateStepper;
@property (weak, nonatomic) IBOutlet UILabel *aboutBriefLabel;

- (IBAction)doneBarButtonItemTouched:(id)sender;
- (IBAction)cancelBarButtonItemTouched:(id)sender;
- (IBAction)maxRecordingClipsValueChanged:(id)sender;
- (IBAction)resolutionValueChanged:(id)sender;
- (IBAction)frameRateValueChanged:(id)sender;

#pragma mark - Private methods
- (void)loadVideoSettings;
- (void)setMaxRecordingClipsValue:(NSUInteger)count andUpdateStepper:(BOOL)update;
- (void)setMaxClipDurationValue:(NSUInteger)seconds;
- (void)setResolutionValue:(CarDVRVideoQuality)quality andUpdateStepper:(BOOL)update;

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
            storageUsage = [NSString stringWithFormat:@"Free: %.2f%%, %lluB",
                            freePercent, freeBytes];
        }
        else if ( freeBytes < 1024 * 1024 )
        {
            storageUsage = [NSString stringWithFormat:@"Free: %.2f%%, %.2fKB",
                            freePercent, freeBytes/1024.0];
        }
        else if ( freeBytes < 1024 * 1024 * 1024 )
        {
            storageUsage = [NSString stringWithFormat:@"Free: %.2f%%, %.2fMB",
                            freePercent, freeBytes/(1024.0*1024.0)];
        }
        else
        {
            storageUsage = [NSString stringWithFormat:@"Free: %.2f%%, %.2fGB",
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

- (IBAction)resolutionValueChanged:(id)sender
{
    UIStepper *stepper = sender;
    NSInteger value = stepper.value;
    CarDVRVideoQuality videoQuality = kCarDVRVideoQualityHigh;
    switch (value)
    {
        case 0:
            videoQuality = kCarDVRVideoQualityLow;
            break;
        case 1:
            videoQuality = kCarDVRVideoQualityMiddle;
            break;
        case 2:
            videoQuality = kCarDVRVideoQualityHigh;
            break;
        default:
            NSAssert1( NO, @"[Error] Unsupported video quality level: %d", value );
            break;
    }
    [self.settings setVideoQuality:[NSNumber numberWithUnsignedInteger:videoQuality]];
    [self setResolutionValue:videoQuality andUpdateStepper:NO];
}

- (IBAction)frameRateValueChanged:(id)sender
{
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
}

#pragma mark - from CarDVRMaxClipDurationSettingViewControllerDelegate
- (void)maxClipDurationSettingViewControllerDone:(CarDVRMaxClipDurationSettingViewController *)sender
{
    [self setMaxClipDurationValue:sender.maxClipDuration];
    [self.settings setMaxRecordingDurationPerClip:[NSNumber numberWithUnsignedInteger:sender.maxClipDuration]];
}

#pragma mark - Private methods
- (void)loadVideoSettings
{
    [self setMaxRecordingClipsValue:self.settings.maxCountOfRecordingClips.unsignedIntegerValue andUpdateStepper:YES];
    [self setMaxClipDurationValue:self.settings.maxRecordingDurationPerClip.unsignedIntegerValue];
    [self setResolutionValue:self.settings.videoQuality.intValue andUpdateStepper:YES];
    self.frameRateValueLabel.text = [NSString stringWithFormat:NSLocalizedString( @"frameRateFormat", nil ), self.settings.videoFrameRate];
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

- (void)setResolutionValue:(CarDVRVideoQuality)quality andUpdateStepper:(BOOL)update
{
    switch ( quality )
    {
        case kCarDVRVideoQualityHigh:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoQualityHigh", nil );
            if ( update )
            {
                [self.resolutionStepper setValue:2];
            }
            break;
        case kCarDVRVideoQualityMiddle:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoQualityMiddle", nil );
            if ( update )
            {
                [self.resolutionStepper setValue:1];
            }
            break;
        case kCarDVRVideoQualityLow:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoQualityLow", nil );
            if ( update )
            {
                [self.resolutionStepper setValue:0];
            }
            break;
        default:
            NSAssert1( NO, @"[Error] Unsupported video quality: %@", self.settings.videoQuality );
            break;
    }
}

@end
