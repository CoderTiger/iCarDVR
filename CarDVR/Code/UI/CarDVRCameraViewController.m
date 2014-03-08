//
//  CarDVRCameraViewController.m
//  CarDVR
//
//  Created by yxd on 13-10-14.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRCameraViewController.h"
#import "CarDVRVideoCapturer.h"
#import "CarDVRHomeViewController.h"
#import "CarDVRAppDelegate.h"
#import "CarDVRLocationDetector.h"
#import "CarDVRSettings.h"

static NSString *const kShowHomeSegueId = @"kShowHomeSegueId";
static const CGFloat kRecordingStatusTivViewCornerRadius = 5.0f;

@interface CarDVRCameraViewController ()<CarDVRLocationDetectorDelegate>

@property (strong, nonatomic) CarDVRVideoCapturer *videoCapturer;
@property (strong, nonatomic) CarDVRLocationDetector *locationDetector;
@property (weak, readonly) CarDVRSettings *settings;
@property (strong, nonatomic) NSDate *startRecordingDate;

@property (weak, nonatomic) IBOutlet UIButton *flashOnButton;
@property (weak, nonatomic) IBOutlet UIButton *flashAutoButton;
@property (weak, nonatomic) IBOutlet UIButton *flashOffButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *starButton;
@property (weak, nonatomic) IBOutlet UIButton *starredButton;
@property (weak, nonatomic) IBOutlet UIView *previewerView;
@property (weak, nonatomic) IBOutlet UIView *recordingStatusTipView;
@property (weak, nonatomic) IBOutlet UILabel *recordingDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *recordingSignLabel;
@property (weak, nonatomic) IBOutlet UIView *flashEffectMaskView;

- (IBAction)flashOnButtonTouched:(id)sender;
- (IBAction)flashAutoButtonTouched:(id)sender;
- (IBAction)flashOffButtonTouched:(id)sender;
- (IBAction)fotoButtonTouched:(id)sender;
- (IBAction)startButtonTouched:(id)sender;
- (IBAction)stopButtonTouched:(id)sender;
- (IBAction)starButtonTouched:(id)sender;
- (IBAction)starredButtonTouched:(id)sender;

#pragma mark - private methods
- (void)setFlashMode:(CarDVRCameraFlashMode)aFlashMode;
- (void)installVideoCapturer;
- (void)installLocationDetector;
- (void)loadSettings;
- (void)layoutSubviews;
- (void)startRecordingVideo;
- (void)stopRecordingVideo;
- (void)setStarredValue:(BOOL)anValue;

- (void)handleUIApplicationDidEnterBackgroundNotification;
- (void)handleCarDVRVideoCapturerDidStartRecordingNotification;
- (void)handleCarDVRVideoCapturerDidStopRecordingNotification;
- (void)handleCarDVRVideoCapturerUpdateSubtitlesNotification;
- (void)handleCarDVRVideoCapturerDidStartCapturingImageNotification;
- (void)handleCarDVRVideoCapturerDidStopCapturingImageNotification:(NSNotification *)aNotification;

@end

@implementation CarDVRCameraViewController

- (CarDVRSettings *)settings
{
    CarDVRAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    return appDelegate.settings;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setTitle:NSLocalizedString( @"cameraViewTitle", @"Camera" )];
    [self installVideoCapturer];
    [self installLocationDetector];
    [self loadSettings];
    self.recordingStatusTipView.layer.cornerRadius = kRecordingStatusTivViewCornerRadius;
    NSNotificationCenter *defaultNC = [NSNotificationCenter defaultCenter];
    [defaultNC addObserver:self
                  selector:@selector(handleUIApplicationDidEnterBackgroundNotification)
                      name:UIApplicationDidEnterBackgroundNotification
                    object:nil];
    [defaultNC addObserver:self
                  selector:@selector(handleCarDVRVideoCapturerDidStartRecordingNotification)
                      name:kCarDVRVideoCapturerDidStartRecordingNotification
                    object:nil];
    [defaultNC addObserver:self
                  selector:@selector(handleCarDVRVideoCapturerDidStopRecordingNotification)
                      name:kCarDVRVideoCapturerDidStopRecordingNotification
                    object:nil];
    [defaultNC addObserver:self
                  selector:@selector(handleCarDVRVideoCapturerUpdateSubtitlesNotification)
                      name:kCarDVRVideoCapturerUpdateSubtitlesNotification
                    object:nil];
    [defaultNC addObserver:self
                  selector:@selector(handleCarDVRVideoCapturerDidStartCapturingImageNotification)
                      name:kCarDVRVideoCapturerDidStartCapturingImageNotification
                    object:nil];
    [defaultNC addObserver:self
                  selector:@selector(handleCarDVRVideoCapturerDidStopCapturingImageNotification:)
                      name:kCarDVRVideoCapturerDidStopCapturingImageNotification
                    object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
#pragma unused(animated)
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
#pragma unused(animated)
    [self.videoCapturer setPreviewerView:self.previewerView];
    [self layoutSubviews];
}

- (void)viewWillDisappear:(BOOL)animated
{
#pragma unused(animated)
    [self stopRecordingVideo];
    [self setFlashMode:kCarDVRCameraFlashModeOff];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
#pragma unused( sender )
    if ( [segue.identifier isEqualToString:kShowHomeSegueId] )
    {
        BOOL isRecording = self.videoCapturer.isRecording;
        [self stopRecordingVideo];
        CarDVRHomeViewController *homeViewController = segue.destinationViewController;
        homeViewController.settings = self.settings;
        homeViewController.switchFromRecordingCamera = isRecording;
    }
}

#pragma mark - private methods
- (void)setFlashMode:(CarDVRCameraFlashMode)aFlashMode
{
    switch ( aFlashMode )
    {
        case kCarDVRCameraFlashModeOn:
            self.flashOnButton.hidden = NO;
            self.flashOffButton.hidden = YES;
            self.flashAutoButton.hidden = YES;
            break;
        case kCarDVRCameraFlashModeAuto:
            self.flashOnButton.hidden = YES;
            self.flashOffButton.hidden = YES;
            self.flashAutoButton.hidden = NO;
            break;
        case kCarDVRCameraFlashModeOff:
            self.flashOnButton.hidden = YES;
            self.flashOffButton.hidden = NO;
            self.flashAutoButton.hidden = YES;
            break;
        default:
            NSAssert1( NO, @"Unknown flash mode: %d", aFlashMode );
            return;
    }
    self.videoCapturer.cameraFlashMode = aFlashMode;
}

- (void)installVideoCapturer
{
    if ( _videoCapturer )
        return;
    CarDVRAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    _videoCapturer = [[CarDVRVideoCapturer alloc] initWithPathHelper:appDelegate.pathHelper
                                                            settings:appDelegate.settings];
}

- (void)installLocationDetector
{
    if ( _locationDetector )
        return;
    _locationDetector = [[CarDVRLocationDetector alloc] initWithDelegate:self];
}

- (void)loadSettings
{
    //
    // load starred flag
    //
    BOOL isStarred = self.settings.starred.boolValue;
    self.starButton.hidden = isStarred;
    self.starredButton.hidden = !isStarred;
}

- (void)layoutSubviews
{
    CGRect viewBounds = self.view.bounds;
    [self.previewerView setFrame:viewBounds];
    [self.videoCapturer fitDeviceOrientation];
}

- (void)startRecordingVideo
{
    if ( self.videoCapturer.isRecording )
    {
        [self.videoCapturer stopRecording];
    }
    [self.videoCapturer startRecording];
    self.startButton.hidden = self.videoCapturer.isRecording;
    self.stopButton.hidden = !self.startButton.hidden;
}

- (void)stopRecordingVideo
{
    if ( self.videoCapturer.isRecording )
    {
        [self.videoCapturer stopRecording];
    }
}

- (void)setStarredValue:(BOOL)anValue
{
    self.settings.starred = [NSNumber numberWithBool:anValue];
    BOOL isStarred = self.settings.starred.boolValue;
    self.starButton.hidden = isStarred;
    self.starredButton.hidden = !isStarred;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self layoutSubviews];
}

- (IBAction)flashOnButtonTouched:(id)sender
{
    [self setFlashMode:kCarDVRCameraFlashModeAuto];
}

- (IBAction)flashAutoButtonTouched:(id)sender
{
    [self setFlashMode:kCarDVRCameraFlashModeOff];
}

- (IBAction)flashOffButtonTouched:(id)sender
{
    [self setFlashMode:kCarDVRCameraFlashModeOn];
}

- (IBAction)fotoButtonTouched:(id)sender
{
    [self.videoCapturer captureStillImage];
}

- (IBAction)startButtonTouched:(id)sender
{
    [self startRecordingVideo];
}

- (IBAction)stopButtonTouched:(id)sender
{
    [self stopRecordingVideo];
}

- (IBAction)starButtonTouched:(id)sender
{
    [self setStarredValue:YES];
}

- (IBAction)starredButtonTouched:(id)sender
{
    [self setStarredValue:NO];
}

- (void)handleUIApplicationDidEnterBackgroundNotification
{
    [self setFlashMode:kCarDVRCameraFlashModeOff];
    [self stopRecordingVideo];
}

- (void)handleCarDVRVideoCapturerDidStartRecordingNotification
{
    [self.locationDetector start];
    self.startRecordingDate = [NSDate date];
    self.startButton.hidden = YES;
    self.stopButton.hidden = NO;
    self.recordingStatusTipView.hidden = NO;
    self.recordingDurationLabel.text = @"00:00:00";
    [UIView animateWithDuration:0.5f animations:^{
        self.recordingStatusTipView.alpha = 0.5f;
    }];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)handleCarDVRVideoCapturerDidStopRecordingNotification
{
    [self.locationDetector stop];
    self.startButton.hidden = NO;
    self.stopButton.hidden = YES;
    self.recordingStatusTipView.alpha = 0;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)handleCarDVRVideoCapturerUpdateSubtitlesNotification
{
    NSDate *currentDate = [NSDate date];
    NSTimeInterval recordingDuration = [currentDate timeIntervalSinceDate:self.startRecordingDate];
    div_t hourDuration = div( recordingDuration, 3600 );
    div_t minDuration = div( hourDuration.rem, 60 );
    self.recordingDurationLabel.text = [NSString stringWithFormat:@"%02d:%02d:%02d",
                                        hourDuration.quot, minDuration.quot, minDuration.rem];
    self.recordingSignLabel.alpha = 0;
    [UIView animateWithDuration:0.5f animations:^{
        self.recordingSignLabel.alpha = 1.0f;
    }];
}

- (void)handleCarDVRVideoCapturerDidStartCapturingImageNotification
{
    const NSTimeInterval kFlashDuration = 1.0f;
    self.flashEffectMaskView.alpha = 0.9f;
    [UIView animateWithDuration:kFlashDuration animations:^{
        self.flashEffectMaskView.alpha = 0;
    }];
}

- (void)handleCarDVRVideoCapturerDidStopCapturingImageNotification:(NSNotification *)aNotification
{
    // todo: complete
}

#pragma mark - from CarDVRLocationDetectorDelegate
- (void)detector:(CarDVRLocationDetector *)aDetector didUpdateToLocation:(CLLocation *)aLocation
{
#pragma unused( aDetector )
    [self.videoCapturer didUpdateToLocation:aLocation];
}

@end
