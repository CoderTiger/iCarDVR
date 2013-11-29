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

static const NSInteger kCarDVRSettingsSectionVideo = 0;

@interface CarDVRSettingsViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (weak, nonatomic) IBOutlet UILabel *maxRecordingClipsLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxRecordingClipsValueLable;
@property (weak, nonatomic) IBOutlet UILabel *maxClipDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxClipDurationValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *resolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *resolutionValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *frameRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *frameRateValueLabel;

- (IBAction)doneBarButtonItemTouched:(id)sender;
- (IBAction)cancelBarButtonItemTouched:(id)sender;
- (IBAction)maxRecordingClipsValueChanged:(id)sender;
- (IBAction)resolutionValueChanged:(id)sender;
- (IBAction)frameRateValueChanged:(id)sender;

#pragma mark - Private methods
- (void)loadVideoSettings;

@end

@implementation CarDVRSettingsViewController

- (void)setSettings:(CarDVRSettings *)settings
{
    _settings = settings;
    [_settings beginEditing];
    [self loadVideoSettings];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = NSLocalizedString( @"settingsViewTitle", @"Settings" );
    self.maxRecordingClipsLabel.text = NSLocalizedString( @"maxRecordingClipsLabel", nil );
    self.maxClipDurationLabel.text = NSLocalizedString( @"maxClipDurationLabel", nil );
    self.resolutionLabel.text = NSLocalizedString( @"resolutionLabel", nil );
    self.frameRateLabel.text = NSLocalizedString( @"frameRateLabel", nil );
    
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
    NSInteger maxRecordingClipsCount = (NSInteger)stepper.value;
    [self.settings setMaxCountOfRecordingClips:[NSNumber numberWithInteger:maxRecordingClipsCount]];
    self.maxRecordingClipsValueLable.text = [NSString stringWithFormat:@"%d", maxRecordingClipsCount];
}

- (IBAction)resolutionValueChanged:(id)sender
{
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
}

#pragma mark - Private methods
- (void)loadVideoSettings
{
    self.maxRecordingClipsValueLable.text = [self.settings.maxCountOfRecordingClips stringValue];
    self.maxClipDurationValueLabel.text = [self.settings.maxRecordingDurationPerClip stringValue];
    switch ( self.settings.videoQuality.intValue )
    {
        case kCarDVRVideoQualityHigh:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoQualityHigh", nil );
            break;
        case kCarDVRVideoQualityMiddle:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoQualityMiddle", nil );
            break;
        case kCarDVRVideoQualityLow:
            self.resolutionValueLabel.text = NSLocalizedString( @"videoQualityLow", nil );
            break;
        default:
            NSAssert1( NO, @"[Error] Unsupported video quality: %@", self.settings.videoQuality );
            break;
    }
    self.frameRateValueLabel.text = [self.settings.videoFrameRate stringValue];
}

@end
