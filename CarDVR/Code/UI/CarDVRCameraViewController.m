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

@interface CarDVRCameraViewController ()<CarDVRLocationDetectorDelegate>

@property (strong, nonatomic) CarDVRVideoCapturer *videoCapturer;
@property (strong, nonatomic) CarDVRLocationDetector *locationDetector;
@property (weak, readonly) CarDVRSettings *settings;

@property (weak, nonatomic) IBOutlet UIButton *flashOnButton;
@property (weak, nonatomic) IBOutlet UIButton *flashAutoButton;
@property (weak, nonatomic) IBOutlet UIButton *flashOffButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *starButton;
@property (weak, nonatomic) IBOutlet UIButton *starredButton;
@property (weak, nonatomic) IBOutlet UIButton *microphoneOffButton;
@property (weak, nonatomic) IBOutlet UIButton *microphoneOnButton;
@property (weak, nonatomic) IBOutlet UIView *previewerView;

- (IBAction)flashOnButtonTouched:(id)sender;
- (IBAction)flashAutoButtonTouched:(id)sender;
- (IBAction)flashOffButtonTouched:(id)sender;
- (IBAction)fotoButtonTouched:(id)sender;
- (IBAction)startButtonTouched:(id)sender;
- (IBAction)stopButtonTouched:(id)sender;
- (IBAction)starButtonTouched:(id)sender;
- (IBAction)starredButtonTouched:(id)sender;
- (IBAction)microphoneOffButtonTouched:(id)sender;
- (IBAction)microphoneOnButtonTouched:(id)sender;

#pragma mark - private methods
- (void)setFlashMode:(CarDVRCameraFlashMode)aFlashMode;
- (void)installVideoCapturer;
- (void)installLocationDetector;
- (void)loadSettings;
- (void)layoutSubviews;
- (void)startRecordingVideo;
- (void)stopRecordingVideo;
- (void)setMicrophoneOnValue:(BOOL)anValue;

- (void)handleUIApplicationDidEnterBackgroundNotification;
- (void)handleCarDVRVideoCapturerDidStartRecordingNotification;
- (void)handleCarDVRVideoCapturerDidStopRecordingNotification;

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
        [self stopRecordingVideo];
        CarDVRHomeViewController *homeViewController = segue.destinationViewController;
        homeViewController.settings = self.settings;
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
    // load microphone on flag
    //
    BOOL isMicrophoneOn = self.settings.microphoneOn.boolValue;
    self.microphoneOffButton.hidden = isMicrophoneOn;
    self.microphoneOnButton.hidden = !isMicrophoneOn;
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

- (void)setMicrophoneOnValue:(BOOL)anValue
{
    self.settings.microphoneOn = [NSNumber numberWithBool:anValue];
    BOOL isMicrophoneOn = self.settings.microphoneOn.boolValue;
    self.microphoneOffButton.hidden = isMicrophoneOn;
    self.microphoneOnButton.hidden = !isMicrophoneOn;
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
    // TODO: complete
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
    [self.videoCapturer setStarred:YES];
    self.starButton.hidden = self.videoCapturer.starred;
    self.starredButton.hidden = !self.starredButton.hidden;
}

- (IBAction)starredButtonTouched:(id)sender
{
    [self.videoCapturer setStarred:NO];
    self.starButton.hidden = self.videoCapturer.starred;
    self.starredButton.hidden = !self.starredButton.hidden;
}

- (IBAction)microphoneOffButtonTouched:(id)sender
{
#pragma unused(sender)
    [self setMicrophoneOnValue:YES];
}

- (IBAction)microphoneOnButtonTouched:(id)sender
{
#pragma unused(sender)
    [self setMicrophoneOnValue:NO];
}

- (void)handleUIApplicationDidEnterBackgroundNotification
{
    [self setFlashMode:kCarDVRCameraFlashModeOff];
}

- (void)handleCarDVRVideoCapturerDidStartRecordingNotification
{
    [self.locationDetector start];
    self.startButton.hidden = YES;
    self.stopButton.hidden = NO;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)handleCarDVRVideoCapturerDidStopRecordingNotification
{
    [self.locationDetector stop];
    self.startButton.hidden = NO;
    self.stopButton.hidden = YES;
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

#pragma mark - from CarDVRLocationDetectorDelegate
- (void)detector:(CarDVRLocationDetector *)aDetector didUpdateToLocation:(CLLocation *)aLocation
{
#pragma unused( aDetector )
    [self.videoCapturer didUpdateToLocation:aLocation];
}

@end
