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

static const NSUInteger kCountOfDuoRecordingClips = 2;
static const char kVideoCaptureQueueName[] = "com.iAutoD.videoCaptureQueue";
static const char kAudioCaptureQueueName[] = "com.iAutoD.audioCaptureQueue";
static const char kClipWriterQueueName[] = "com.iAutoD.clipWriterQueue";

@interface CarDVRVideoCapturerInterval ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{
    dispatch_queue_t _workQueue;
    BOOL _willStopRecording;
    
    dispatch_queue_t _clipWriterQueue;
    AVCaptureSession *_captureSession;
    AVCaptureConnection *_audioConnection;
	AVCaptureConnection *_videoConnection;
}

@property (weak, nonatomic) id capturer;
@property (weak, nonatomic) CarDVRPathHelper *pathHelper;
@property (weak, nonatomic) CarDVRSettings *settings;
@property (readonly, copy, nonatomic) NSString *const videoResolutionPreset;

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@property (strong, nonatomic) NSMutableArray *duoRecordingClips;// AVCaptureMovieFileOutput
@property (strong, nonatomic) NSMutableArray *duoRecordingWriter;// AVAssetWriter
@property (strong, nonatomic) NSMutableArray *duoRecordingLoopTimers;// NSTimer
@property (readonly, nonatomic) NSUInteger nextRecordingClip;
@property (strong, nonatomic) NSMutableArray *recentRecordedClipURLs;// NSURL

@property (assign, nonatomic, getter = isBatchConfiguration) BOOL batchConfiguration;

#pragma mark - private methods
- (void)installAVCaptureDeviceWithSession:(AVCaptureSession *)aSession;
- (void)installAVCaptureObjects;
- (void)setOrientation:(UIInterfaceOrientation)anOrientation
    forMovieFileOutput:(AVCaptureMovieFileOutput *)aMovieFileOutput;
- (NSURL *)newRecordingClipURL;
- (void)handleAVCaptureSessionRuntimeErrorNotification:(NSNotification *)aNotification;
- (void)handleUIApplicationDidBecomeActiveNotification;
- (void)handleUIApplicationDidEnterBackgroundNotification;
- (void)handleRecordingLoopTimer:(NSTimer *)aTimer;

- (AVCaptureDevice *)videoDeviceWithPosition:(CarDVRCameraPosition)aPosition;
- (AVCaptureDevice *)audioDevice;

@end

@implementation CarDVRVideoCapturerInterval

@synthesize hasBackCamera = _hasBackCamera;
@synthesize hasFrontCamera = _hasFrontCamera;
@synthesize nextRecordingClip = _nextRecordingClip;

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
    AVCaptureDevice *backCamera = [self videoDeviceWithPosition:kCarDVRCameraPositionBack];
    return ( backCamera != nil );
}

- (BOOL)hasFrontCamera
{
    AVCaptureDevice *frontCamera = [self videoDeviceWithPosition:kCarDVRCameraPositionFront];
    return ( frontCamera != nil );
}

- (NSUInteger)nextRecordingClip
{
    NSUInteger clip = _nextRecordingClip;
    if ( clip >= kCountOfDuoRecordingClips )
    {
        clip = 0;
    }
    _nextRecordingClip = ( clip + 1 ) % kCountOfDuoRecordingClips;
    return clip;
}

- (void)setCameraFlashMode:(CarDVRCameraFlashMode)cameraFlashMode
{
    AVCaptureDevice *currentCamera = [self videoDeviceWithPosition:self.settings.cameraPosition.integerValue];
    if ( currentCamera.hasFlash && currentCamera.hasTorch )
    {
        AVCaptureFlashMode flashMode = AVCaptureFlashModeOff;
        AVCaptureTorchMode torchMode = AVCaptureTorchModeOff;
        switch ( cameraFlashMode )
        {
            case kCarDVRCameraFlashModeOn:
                flashMode = AVCaptureFlashModeOn;
                torchMode = AVCaptureTorchModeOn;
                break;
            case kCarDVRCameraFlashModeAuto:
                flashMode = AVCaptureFlashModeAuto;
                torchMode = AVCaptureTorchModeAuto;
                break;
            case kCarDVRCameraFlashModeOff:
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
                if ( cameraFlashMode != kCarDVRCameraFlashModeOff )
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
        _cameraFlashMode = kCarDVRCameraFlashModeOff;
    }
}

- (NSString *const)videoResolutionPreset
{
    switch ( _settings.videoQuality.integerValue )
    {
        case kCarDVRVideoQualityHigh:
            return AVCaptureSessionPresetHigh;
        case kCarDVRVideoQualityMiddle:
            return AVCaptureSessionPresetMedium;
        case kCarDVRVideoQualityLow:
            return AVCaptureSessionPresetLow;
        default:
            NSAssert1( NO, @"Unsupported video quality: %@", _settings.videoQuality );
            break;
    }
    return AVCaptureSessionPresetHigh;// return AVCaptureSessionPresetHigh by default.
}

- (id)initWithCapturer:(id)aCapturer
            pathHelper:(CarDVRPathHelper *)aPathHelper
              settings:(CarDVRSettings *)aSettings
{
    self = [super init];
    if ( self )
    {
        _capturer = aCapturer;
        _pathHelper = aPathHelper;
        _settings = aSettings;
        _cameraFlashMode = kCarDVRCameraFlashModeOff;
        _starred = NO;
        _batchConfiguration = NO;
        _recording = NO;
        _willStopRecording = NO;
        
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

- (void)startRecording
{
    if ( _recording || _willStopRecording )
        return;
    _recording = YES;
    _willStopRecording = NO;
    
    // Remove the recent recorded clips.
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
    
    // Prepare recent recoreded clips
    _recentRecordedClipURLs = [NSMutableArray arrayWithCapacity:self.settings.maxCountOfRecordingClips.unsignedIntegerValue];
    
    // Start recording timer
    _nextRecordingClip = 0;
    if ( !self.duoRecordingLoopTimers )
    {
        self.duoRecordingLoopTimers = [NSMutableArray arrayWithCapacity:kCountOfDuoRecordingClips];
        for ( NSUInteger i = 0; i < kCountOfDuoRecordingClips; i++ )
        {
            NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.settings.maxRecordingDuration.doubleValue
                                                              target:self
                                                            selector:@selector(handleRecordingLoopTimer:)
                                                            userInfo:nil
                                                             repeats:YES];
            [self.duoRecordingLoopTimers addObject:timer];
        }
        NSDate *firstRecordingDate = [NSDate date];
        NSDate *secondRecordingDate = [NSDate dateWithTimeInterval:(self.settings.maxRecordingDuration.doubleValue
                                                                    - self.settings.overlappedRecordingDuration.doubleValue)
                                                         sinceDate:firstRecordingDate];
        [self.duoRecordingLoopTimers[0] setFireDate:firstRecordingDate];
        [self.duoRecordingLoopTimers[1] setFireDate:secondRecordingDate];
    }
    else
    {
        NSAssert1( self.duoRecordingLoopTimers.count == kCountOfDuoRecordingClips,
                  @"Wrong count of recording loop timers: %u", self.duoRecordingLoopTimers.count );
        NSDate *firstRecordingDate = [NSDate date];
        NSDate *secondRecordingDate = [NSDate dateWithTimeInterval:(self.settings.maxRecordingDuration.doubleValue
                                                                    - self.settings.overlappedRecordingDuration.doubleValue)
                                                         sinceDate:firstRecordingDate];
        [self.duoRecordingLoopTimers[0] setFireDate:firstRecordingDate];
        [self.duoRecordingLoopTimers[1] setFireDate:secondRecordingDate];
    }
}

- (void)stopRecording
{
    if ( !_recording )
        return;
    _willStopRecording = YES;
    
    BOOL delaySettingRecordingFlag = NO;
    for ( NSUInteger i = 0; i < kCountOfDuoRecordingClips; i++ )
    {
        [self.duoRecordingLoopTimers[i] invalidate];
        AVCaptureMovieFileOutput *clip = self.duoRecordingClips[i];
        if ( clip.isRecording )
        {
            [clip stopRecording];
            delaySettingRecordingFlag = YES;
        }
    }
    if ( !delaySettingRecordingFlag )
    {
        _recording = NO;
        _willStopRecording = NO;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kCarDVRVideoCapturerDidStopRecordingNotification
                                                            object:self.capturer];
    }
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
    // TODO:
//    [self setOrientation:statusBarOrientation forMovieFileOutput:self.movieFileOutput];
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
#ifdef DEBUG
    NSLog( @"Recording clip: \n%@", captureOutput.outputFileURL );
#endif// DEBUG
    [self.recentRecordedClipURLs addObject:captureOutput.outputFileURL];
    if ( self.recentRecordedClipURLs.count > self.settings.maxCountOfRecordingClips.unsignedIntegerValue )
    {
        NSURL *oldestClipURL = self.recentRecordedClipURLs[0];
        [self.recentRecordedClipURLs removeObjectAtIndex:0];
        dispatch_async( _workQueue, ^{
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtURL:oldestClipURL error:&error];
            if ( error )
            {
                NSLog( @"[Error] %@", error );
            }
        });
    }
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
#ifndef USE_DUO_MOVIE_FILE_OUTPUTS
    if ( !self.isRecording )
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kCarDVRVideoCapturerDidStopRecordingNotification
                                                            object:self.capturer];
    }
#else// USE_DUO_MOVIE_FILE_OUTPUTS
    if ( self.isRecording )
    {
        if ( _willStopRecording )
        {
            BOOL isRecording = NO;
            for ( AVCaptureMovieFileOutput *clip in self.duoRecordingClips )
            {
                if ( clip.isRecording )
                {
                    isRecording = YES;
                }
            }
            if ( !isRecording )
            {
                _recording = NO;
                _willStopRecording = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:kCarDVRVideoCapturerDidStopRecordingNotification
                                                                    object:self.capturer];
            }
        }
        else
        {
            [captureOutput startRecordingToOutputFileURL:[self newRecordingClipURL] recordingDelegate:self];
        }
    }
#endif// USE_DUO_MOVIE_FILE_OUTPUTS
}

#pragma mark - from AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    // TODO: complete
}

#pragma mark - private methods
- (void)installAVCaptureDeviceWithSession:(AVCaptureSession *)aSession
{
    //
    // Create audio connection
    //
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:nil];
    if ( [aSession canAddInput:audioInput] )
    {
        [aSession addInput:audioInput];
    }
    else
    {
        // TODO: handle error
    }
    AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
	dispatch_queue_t audioCaptureQueue = dispatch_queue_create( kAudioCaptureQueueName, DISPATCH_QUEUE_SERIAL );
	[audioOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
    _audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];

    //
    // Create video connection
    //
    AVCaptureDeviceInput *videoInput =
        [[AVCaptureDeviceInput alloc] initWithDevice:[self videoDeviceWithPosition:_settings.cameraPosition.integerValue]
                                               error:nil];
    if ( [aSession canAddInput:videoInput] )
    {
        [aSession addInput:videoInput];
    }
    else
    {
        // TODO: handle error
    }
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    dispatch_queue_t videoCaptureQueue = dispatch_queue_create( kVideoCaptureQueueName, DISPATCH_QUEUE_SERIAL );
    [videoOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
    _videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
}

- (void)installAVCaptureObjects
{
    if ( _captureSession )
        return;
    
    //
    // Create queue for recording clip to local file
    //
    _clipWriterQueue = dispatch_queue_create( kClipWriterQueueName, DISPATCH_QUEUE_SERIAL );
    
    //
    // Create capture session
    //
    _captureSession = [[AVCaptureSession alloc] init];
    
    //
    // Create previewer
    //
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    
    
    //
    // Config & start capture session
    //
    [_captureSession beginConfiguration];
    [_captureSession setSessionPreset:self.videoResolutionPreset];
    [self installAVCaptureDeviceWithSession:_captureSession];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_captureSession commitConfiguration];
    
    [self fitDeviceOrientation];
    [_captureSession startRunning];
}

- (NSURL *)newRecordingClipURL
{
    NSDate *currentDate = [NSDate date];
    NSString *clipName = [NSString stringWithFormat:@"%@.mov", [CarDVRPathHelper stringFromDate:currentDate]];
    NSString *clipPath = [self.pathHelper.recentsFolderPath stringByAppendingPathComponent:clipName];
    NSURL *clipURL = [NSURL fileURLWithPath:clipPath];
    return clipURL;
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
    if ( self.isRecording )
    {
        [self stopRecording];
    }
}

- (void)handleRecordingLoopTimer:(NSTimer *)aTimer
{
#pragma unused( aTimer )
#ifdef DEBUG
    NSLog( @"[Timer] %pt", aTimer );
#endif// DEBUG
    NSUInteger nextRecordingClip = self.nextRecordingClip;
    AVCaptureMovieFileOutput *clip = self.duoRecordingClips[nextRecordingClip];
    if ( clip.isRecording )
    {
        [clip stopRecording];
    }
    else
    {
//        [clip startRecordingToOutputFileURL:[self newRecordingClipURL] recordingDelegate:self];
    }
}

- (AVCaptureDevice *)videoDeviceWithPosition:(CarDVRCameraPosition)aPostion
{
    AVCaptureDevicePosition devicePosition = AVCaptureDevicePositionBack;
    switch ( aPostion )
    {
        case kCarDVRCameraPositionFront:
            devicePosition = AVCaptureDevicePositionFront;
            break;
        default:
            break;
    }
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
    {
        if ( [device position] == devicePosition )
        {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *)audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ( [devices count] > 0 )
    {
        return [devices objectAtIndex:0];
    }
    return nil;
}

@end
