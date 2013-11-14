//
//  CarDVRVideoCapturerInterval.m
//  CarDVR
//
//  Created by yxd on 13-10-28.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRVideoCapturerInterval.h"
#import <AVFoundation/AVFoundation.h>
#import "CarDVRPathHelper.h"
#import "CarDVRSettings.h"

static const NSUInteger kMaxCountOfRecordingMovieClips = 2;

@interface CarDVRVideoCapturerInterval ()<AVCaptureFileOutputRecordingDelegate>
{
    dispatch_queue_t _workQueue;
}

@property (weak, nonatomic) id capturer;
@property (weak, nonatomic) CarDVRPathHelper *pathHelper;
@property (weak, nonatomic) CarDVRSettings *settings;
@property (readonly, copy, nonatomic) NSString *const videoResolutionPreset;

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureDevice *backCamera;
@property (strong, nonatomic) AVCaptureDevice *frontCamera;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) AVCaptureMovieFileOutput *movieFileOutput;

@property (strong, nonatomic) NSTimer *recordingLoopTimer;

@property (assign, nonatomic, getter = isBatchConfiguration) BOOL batchConfiguration;

#pragma mark - private methods
- (void)initConfigurations;
- (AVCaptureDevice *)currentCamera;
- (void)installAVCaptureDeviceWithSession:(AVCaptureSession *)aSession;
- (void)installAVCaptureMovieFileOutputWithSession:(AVCaptureSession *)aSession;
- (void)installAVCaptureObjects;
- (void)setOrientation:(UIInterfaceOrientation)anOrientation
    forMovieFileOutput:(AVCaptureMovieFileOutput *)aMovieFileOutput;
- (NSURL *)newRecordingMovieFileOutputURL;
- (void)handleAVCaptureSessionRuntimeErrorNotification:(NSNotification *)aNotification;
- (void)handleUIApplicationDidBecomeActiveNotification;
- (void)handleUIApplicationDidEnterBackgroundNotification;
- (void)handleRecordingLoopTimer:(NSTimer *)aTimer;

@end

@implementation CarDVRVideoCapturerInterval

@synthesize hasBackCamera = _hasBackCamera;
@synthesize hasFrontCamera = _hasFrontCamera;

- (void)setPreviewerView:(UIView *)previewerView
{
    if ( previewerView == _previewerView )
        return;
    [_previewLayer removeFromSuperlayer];
    _previewerView = previewerView;
    if ( _previewerView )
    {
        [_previewerView.layer addSublayer:_previewLayer];
        [self fitDeviceOrientation];
    }
}

- (BOOL)hasBackCamera
{
    return ( _backCamera != nil );
}

- (BOOL)hasFrontCamera
{
    return ( _frontCamera != nil );
}

- (void)setCameraFlashMode:(CarDVRCameraFlashMode)cameraFlashMode
{
    AVCaptureDevice *currentCamera = [self currentCamera];
    if ( currentCamera.hasFlash && currentCamera.hasTorch )
    {
        AVCaptureFlashMode flashMode = AVCaptureFlashModeOff;
        AVCaptureTorchMode torchMode = AVCaptureTorchModeOff;
        switch ( cameraFlashMode )
        {
            case CarDVRCameraFlashModeOn:
                flashMode = AVCaptureFlashModeOn;
                torchMode = AVCaptureTorchModeOn;
                break;
            case CarDVRCameraFlashModeAuto:
                flashMode = AVCaptureFlashModeAuto;
                torchMode = AVCaptureTorchModeAuto;
                break;
            case CarDVRCameraFlashModeOff:
                break;
            default:
                NSAssert1( NO, @"Unsupported camera flash mode: %d", (int)cameraFlashMode );
                break;
        }
        
        NSError *error = nil;
        [currentCamera lockForConfiguration:&error];
        if ( !error )
        {
            @try
            {
                if ( cameraFlashMode != CarDVRCameraFlashModeOff )
                {
                    if ( !currentCamera.isFlashAvailable || !currentCamera.isTorchAvailable )
                    {
                        // The device overheats and needs to cool off.
                        flashMode = AVCaptureFlashModeOff;
                        torchMode = AVCaptureTorchModeOff;
                    }
                }
                if ( [currentCamera isFlashModeSupported:flashMode]
                    && [currentCamera isTorchModeSupported:torchMode] )
                {
                    currentCamera.flashMode = flashMode;
                    currentCamera.torchMode = torchMode;
                    _cameraFlashMode = cameraFlashMode;
                }
            }
            @catch ( NSException *exception )
            {
                // TODO: handle exception
            }
            @finally
            {
                [currentCamera unlockForConfiguration];
            }
        }
    }
    else
    {
        _cameraFlashMode = CarDVRCameraFlashModeOff;
    }
}

- (NSString *const)videoResolutionPreset
{
    switch ( self.videoQuality )
    {
        case CarDVRVideoQualityHigh:
            return AVCaptureSessionPresetHigh;
        case CarDVRVideoQualityMiddle:
            return AVCaptureSessionPresetMedium;
        case CarDVRVideoQualityLow:
            return AVCaptureSessionPresetLow;
        default:
            NSAssert1( NO, @"Unsupported video quality: %d", (int)self.videoQuality );
            break;
    }
    return AVCaptureSessionPresetHigh;// return AVCaptureSessionPresetHigh by default.
}

- (id)initWithCapturer:(id)aCapturer
                 queue:(dispatch_queue_t)aQueue
            pathHelper:(CarDVRPathHelper *)aPathHelper
              settings:(CarDVRSettings *)aSettings
{
    self = [super init];
    if ( self )
    {
        _capturer = aCapturer;
        _workQueue = aQueue;
        _pathHelper = aPathHelper;
        _settings = aSettings;
        _cameraFlashMode = CarDVRCameraFlashModeOff;
        _starred = NO;
        _batchConfiguration = NO;
        
        [self initConfigurations];
        [self installAVCaptureObjects];
        
        NSNotificationCenter *defaultNC = [NSNotificationCenter defaultCenter];
        [defaultNC addObserver:self
                      selector:@selector(handleAVCaptureSessionRuntimeErrorNotification:)
                          name:AVCaptureSessionRuntimeErrorNotification
                        object:nil];
        [defaultNC addObserver:self
                      selector:@selector(handleUIApplicationDidBecomeActiveNotification)
                          name:UIApplicationDidBecomeActiveNotification
                        object:nil];
        [defaultNC addObserver:self
                      selector:@selector(handleUIApplicationDidEnterBackgroundNotification)
                          name:UIApplicationDidEnterBackgroundNotification
                        object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_captureSession stopRunning];
}

- (void)start
{
    if ( _running )
        return;
    if ( [self.movieFileOutput isRecording] )
    {
        [self.movieFileOutput stopRecording];
    }
    
    // remove the recorded clips before.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *recentRecordedClips = [fileManager contentsOfDirectoryAtPath:self.pathHelper.recentsFolderPath
                                                                    error:nil];
    if ( recentRecordedClips )
    {
        dispatch_async( _workQueue, ^{
            for ( NSString *clipFileName in recentRecordedClips )
            {
                [fileManager removeItemAtPath:[self.pathHelper.recentsFolderPath stringByAppendingPathComponent:clipFileName]
                                        error:nil];
            }
        });
    }
    
    // start recording new clip
    NSURL *movieFileOuputURL = [self newRecordingMovieFileOutputURL];
    [self.movieFileOutput startRecordingToOutputFileURL:movieFileOuputURL recordingDelegate:self];
    _running = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kCarDVRVideoCapturerDidStartRecordingNotification
                                                        object:self.capturer];
    
    if ( !self.recordingLoopTimer )
    {
        self.recordingLoopTimer = [NSTimer scheduledTimerWithTimeInterval:self.settings.maxRecordingDuration.doubleValue
                                                                   target:self
                                                                 selector:@selector(handleRecordingLoopTimer:)
                                                                 userInfo:nil
                                                                  repeats:YES];
    }
    else
    {
        [self.recordingLoopTimer fire];
    }
}

- (void)stop
{
    if ( !_running )
        return;
    [self.recordingLoopTimer invalidate];
    if ( [self.movieFileOutput isRecording] )
    {
        [self.movieFileOutput stopRecording];
    }
    _running = NO;
}

- (void)fitDeviceOrientation
{
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    NSInteger systemMainVersion = [[[UIDevice currentDevice] systemVersion] integerValue];
    
    // adjust the orientation of the previewer
    if ( systemMainVersion < 6 )
    {
        if ( _previewLayer.isOrientationSupported )
        {
            _previewLayer.orientation = statusBarOrientation;
        }
    }
    else
    {
        if ( _previewLayer.connection.isVideoOrientationSupported )
        {
            _previewLayer.connection.videoOrientation = statusBarOrientation;
        }
    }
    _previewLayer.frame = self.previewerView.bounds;
    
    // adjust the orientation of the current output movie.
    [self setOrientation:statusBarOrientation forMovieFileOutput:self.movieFileOutput];
}

- (void)focus
{
    // TODO: complete
}

#pragma mark - from AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
      fromConnections:(NSArray *)connections
{
    // TODO: complete
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
      fromConnections:(NSArray *)connections
                error:(NSError *)error
{
    BOOL recordedSuccessfully = YES;
    if ( [error code] != noErr )
    {
        // A problem occurred: Find out if the recording was successful.
        id value = [[error userInfo] objectForKey:AVErrorRecordingSuccessfullyFinishedKey];
        if ( value )
        {
            recordedSuccessfully = [value boolValue];
        }
    }
    if ( !recordedSuccessfully )
    {
        NSLog( @"[Error] failed to record video with error: %@", error );
    }
    if ( !self.isRunning )
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kCarDVRVideoCapturerDidStopRecordingNotification
                                                            object:self.capturer];
    }
}

#pragma mark - private methods
- (AVCaptureDevice *)currentCamera
{
    switch ( _cameraPosition )
    {
        case CarDVRCameraPositionBack:
            return _backCamera;
        case CarDVRCameraPositionFront:
            return _frontCamera;
        default:
            NSAssert1( NO, @"Unsupported camera position: %d", _cameraPosition );
            // TODO: handle error
            break;
    }
    return nil;
}

- (void)initConfigurations
{
    _videoQuality = CarDVRVideoQualityHigh;
//    _videoQuality = CarDVRVideoQualityMiddle;
    _cameraPosition = CarDVRCameraPositionBack;
}

- (void)installAVCaptureDeviceWithSession:(AVCaptureSession *)aSession
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
    {
        if ( device.position == AVCaptureDevicePositionBack )
        {
            _backCamera = device;
            continue;
        }
        if ( device.position == AVCaptureDevicePositionFront )
        {
            _frontCamera = device;
            continue;
        }
    }
    
    AVCaptureDevice *currentCamera = [self currentCamera];
    NSError *error = nil;
    AVCaptureDeviceInput *currentCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:currentCamera error:&error];
    if ( !currentCameraInput )
    {
        // TODO: handle error
    }
    else
    {
        if ( [aSession canAddInput:currentCameraInput] )
        {
            [aSession addInput:currentCameraInput];
        }
        else
        {
            // TODO: handle error
        }
    }
}

- (void)installAVCaptureMovieFileOutputWithSession:(AVCaptureSession *)aSession
{
    AVCaptureMovieFileOutput *output = [[AVCaptureMovieFileOutput alloc] init];
    if ( output )
    {
        if ( [aSession canAddOutput:output] )
        {
            [aSession addOutput:output];
            _movieFileOutput = output;
        }
        else
        {
            // TODO: handle error
        }
    }
}

- (void)installAVObjects
{
    if ( _captureSession )
        return;
    
    _captureSession = [[AVCaptureSession alloc] init];
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
    {
        if ( device.position == AVCaptureDevicePositionBack )
        {
            _backCamera = device;
            continue;
        }
        if ( device.position == AVCaptureDevicePositionFront )
        {
            _frontCamera = device;
            continue;
        }
    }
    
    [_captureSession beginConfiguration];
    [_captureSession setSessionPreset:self.videoResolutionPreset];
    AVCaptureDevice *currentCamera = [self currentCamera];
    NSError *error = nil;
    AVCaptureDeviceInput *currentCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:currentCamera error:&error];
    if ( !currentCameraInput )
    {
        // TODO: handle error
    }
    else
    {
        if ( [_captureSession canAddInput:currentCameraInput] )
        {
            [_captureSession addInput:currentCameraInput];
        }
        else
        {
            // TODO: handle error
        }
        
        if ( [_captureSession canAddOutput:self.movieFileOutput] )
        {
            [_captureSession addOutput:self.movieFileOutput];
        }
        else
        {
            // TODO: handle error
        }
    }
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_captureSession commitConfiguration];
    [self fitDeviceOrientation];
    [_captureSession startRunning];
}

- (void)installAVCaptureObjects
{
    if ( _captureSession )
        return;
    
    _captureSession = [[AVCaptureSession alloc] init];
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    [_captureSession beginConfiguration];
    [_captureSession setSessionPreset:self.videoResolutionPreset];
    [self installAVCaptureDeviceWithSession:_captureSession];
    [self installAVCaptureMovieFileOutputWithSession:_captureSession];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_captureSession commitConfiguration];
    
    [self fitDeviceOrientation];
    [_captureSession startRunning];
}

- (NSURL *)newRecordingMovieFileOutputURL
{
    NSDate *currentDate = [NSDate date];
    NSString *movieFileOuputName = [NSString stringWithFormat:@"%@.mov", [CarDVRPathHelper stringFromDate:currentDate]];
    NSString *movieFileOuputPath = [self.pathHelper.recentsFolderPath stringByAppendingPathComponent:movieFileOuputName];
    NSURL *movieFileOuputURL = [NSURL fileURLWithPath:movieFileOuputPath];
    return movieFileOuputURL;
}

- (void)setOrientation:(UIInterfaceOrientation)anOrientation
    forMovieFileOutput:(AVCaptureMovieFileOutput *)aMovieFileOutput
{
    NSArray *movieFileOutputConnections = aMovieFileOutput.connections;
    for ( AVCaptureConnection *movieFileOutputConnection in movieFileOutputConnections )
    {
        AVCaptureConnection *videoOuputConnection = nil;
        for ( AVCaptureInputPort *port in movieFileOutputConnection.inputPorts )
        {
            if ( [port.mediaType isEqual:AVMediaTypeVideo] )
            {
                videoOuputConnection = movieFileOutputConnection;
                break;
            }
        }
        if ( videoOuputConnection )
        {
            if ( [videoOuputConnection isVideoOrientationSupported] )
            {
                switch ( anOrientation )
                {
                    case UIInterfaceOrientationPortrait:
                        [videoOuputConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                        break;
                    case UIInterfaceOrientationLandscapeLeft:
                        [videoOuputConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
                        break;
                    case UIInterfaceOrientationLandscapeRight:
                        [videoOuputConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                        break;
                    case UIInterfaceOrientationPortraitUpsideDown:
                    default:
                        [videoOuputConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
                        break;
                }
            }
            break;
        }
    }
}

- (void)handleAVCaptureSessionRuntimeErrorNotification:(NSNotification *)aNotification
{
    // TODO: complete
}

- (void)handleUIApplicationDidBecomeActiveNotification
{
    if ( ![_captureSession isRunning] )
    {
        [_captureSession startRunning];
    }
}

- (void)handleUIApplicationDidEnterBackgroundNotification
{
    if ( self.isRunning )
    {
        [self stop];
    }
}

- (void)handleRecordingLoopTimer:(NSTimer *)aTimer
{
#ifdef DEBUG
    NSDate *currentDate = [NSDate date];
    NSLog( @"\nrecording loop timer: %@", currentDate );
#endif
#pragma unused( aTimer )
    if ( self.isRunning )
    {
//        NSURL *movieFileOuputURL = [self newRecordingMovieFileOutputURL];
//        [self.movieFileOutput stopRecording];
//        [self.movieFileOutput startRecordingToOutputFileURL:movieFileOuputURL recordingDelegate:self];
    }
    else
    {
        [self.recordingLoopTimer invalidate];
    }
}

@end
