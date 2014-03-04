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
#import "CarDVRAssetWriter.h"
#import "CarDVRVideoClipURLs.h"

static const NSUInteger kCountOfDuoRecordingClips = 2;
static const char kVideoCaptureQueueName[] = "com.iAutoD.videoCaptureQueue";
static const char kAudioCaptureQueueName[] = "com.iAutoD.audioCaptureQueue";
static const char kClipWriterQueueName[] = "com.iAutoD.clipWriterQueue";
static const NSTimeInterval kSubtitlesUpdatingInterval = 1.0f;// 1 second

@interface CarDVRVideoCapturerInterval ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{
    dispatch_queue_t _clipWriterQueue;
    AVCaptureSession *_captureSession;
    AVCaptureConnection *_audioConnection;
	AVCaptureConnection *_videoConnection;
    
    // Only accessed on movie writing queue (including self.recording)
    // duo asset writers
    NSMutableArray *_duoAssetWriter;// CarDVRAssetWriter
    NSMutableArray *_recentRecordedClipURLs;// NSURL
    BOOL _readyToRecordAudio;
    BOOL _readyToRecordVideo;
	BOOL _recordingWillBeStarted;
	BOOL _recordingWillBeStopped;
    BOOL _isStarred;
    
    CLLocation *_location;
}

#pragma mark - redeclared public properties as readwrite
@property (readwrite, getter = isRecording, nonatomic) BOOL recording;

#pragma mark - private properties
@property (weak, nonatomic) id capturer;
@property (weak, nonatomic) CarDVRPathHelper *pathHelper;
@property (weak, nonatomic) CarDVRSettings *settings;
@property (readonly, copy, nonatomic) NSString *const videoResolutionPreset;

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@property (assign, nonatomic, getter = isBatchConfiguration) BOOL batchConfiguration;

#pragma mark - private methods
- (void)configAVCaptureSession;
- (void)configCamera;
- (void)installAVCaptureDeviceWithSession:(AVCaptureSession *)aSession;
- (void)installAVCaptureObjects;
- (void)setOrientation:(UIInterfaceOrientation)anOrientation
    forMovieFileOutput:(AVCaptureMovieFileOutput *)aMovieFileOutput;
- (NSURL *)newRecordingClipURL;
- (NSString *)newRecordingClipName;
- (void)handleAVCaptureSessionRuntimeErrorNotification:(NSNotification *)aNotification;
- (void)handleAVCaptureSessionDidStopRunningNotification:(NSNotification *)aNotification;
- (void)handleUIApplicationDidBecomeActiveNotification;
- (void)handleUIApplicationDidEnterBackgroundNotification;
- (void)handleCarDVRSettingsCommitEditingNotification:(NSNotification *)aNotification;
- (void)handleStarredChangedNotification;
- (void)startDuoAssetWriterLoop;
- (void)stopDuoAssetWriterLoop;
- (void)startNextAssetWriter;
- (BOOL)stopAssetWriter:(CarDVRAssetWriter *)anAssetWriter;
- (void)stopOldestAssetWriter;
- (void)updateSubtitles;

- (AVCaptureDevice *)videoDeviceWithPosition:(CarDVRCameraPosition)aPosition;
- (AVCaptureDevice *)audioDevice;
- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation;
- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation;
- (BOOL)setupVideoInputForAssetWriter:(CarDVRAssetWriter *)anAssetWriter
                    formatDescription:(CMFormatDescriptionRef)currentFormatDescription;
- (BOOL)setupAudioInputForAssetWriter:(CarDVRAssetWriter *)anAssetWriter
                    formatDescription:(CMFormatDescriptionRef)currentFormatDescription;
- (void)stopRecordingOfAssetWriter:(CarDVRAssetWriter *)anAssetWriter
             withCompletionHandler:(void (^)(NSException *aException)) aBlock;

#pragma mark - methods processing video
- (void)processVideoSample:(CMSampleBufferRef)aSampleBuffer withFormat:(CMFormatDescriptionRef)aFormatDescription;

@end

@implementation CarDVRVideoCapturerInterval

@synthesize hasBackCamera = _hasBackCamera;
@synthesize hasFrontCamera = _hasFrontCamera;
@synthesize recording = _recording;

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

- (void)setRecording:(BOOL)recording
{
    @synchronized( self )
    {
        if ( _recording == recording )
            return;
        _recording = recording;
        dispatch_async( dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:
             _recording?kCarDVRVideoCapturerDidStartRecordingNotification:kCarDVRVideoCapturerDidStopRecordingNotification
                                                                object:self.capturer];
        } );
    }
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
        _batchConfiguration = NO;
        _recording = NO;
        _isStarred = _settings.isStarred.boolValue;
        
        [self installAVCaptureObjects];
        
        NSNotificationCenter *defaultNC = [NSNotificationCenter defaultCenter];
        [defaultNC addObserver:self
                      selector:@selector(handleAVCaptureSessionRuntimeErrorNotification:)
                          name:AVCaptureSessionRuntimeErrorNotification
                        object:_captureSession];
        [defaultNC addObserver:self
                      selector:@selector(handleAVCaptureSessionDidStopRunningNotification:)
                          name:AVCaptureSessionDidStopRunningNotification
                        object:_captureSession];
        [defaultNC addObserver:self
                      selector:@selector(handleUIApplicationDidBecomeActiveNotification)
                          name:UIApplicationDidBecomeActiveNotification
                        object:nil];
        [defaultNC addObserver:self
                      selector:@selector(handleUIApplicationDidEnterBackgroundNotification)
                          name:UIApplicationDidEnterBackgroundNotification
                        object:nil];
        
        [_settings addCommitEditingObserver:self selector:@selector(handleCarDVRSettingsCommitEditingNotification:)];
        [_settings addObserver:self
                      selector:@selector(handleStarredChangedNotification)
                        forKey:kCarDVRSettingsKeyStarred];
    }
    return self;
}

- (void)dealloc
{
    [self.settings removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_captureSession stopRunning];
}

- (void)startRecording
{
    dispatch_async( _clipWriterQueue, ^{
        if ( _recordingWillBeStarted || self.isRecording )
            return;
        _recordingWillBeStarted = YES;
        //
        // Remove the recent recorded clips.
        //
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *recentRecordedClips = [fileManager contentsOfDirectoryAtURL:self.pathHelper.recentsFolderURL
                                                  includingPropertiesForKeys:nil
                                                                     options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                                       error:nil];
        if ( recentRecordedClips )
        {
            for ( NSURL *clipFileURL in recentRecordedClips )
            {
                [fileManager removeItemAtURL:clipFileURL error:nil];
            }
        }
        
        //
        // Prepare recent recoreded clips
        //
        _recentRecordedClipURLs = [NSMutableArray arrayWithCapacity:self.settings.maxCountOfRecordingClips.unsignedIntegerValue];
        
        [self startDuoAssetWriterLoop];
    });
}

- (void)stopRecording
{
#ifdef DEBUG
    NSLog( @"[Debug][+]%s", __PRETTY_FUNCTION__ );
#endif// DEBUG
    dispatch_async( _clipWriterQueue, ^{
        if ( _recordingWillBeStopped || !self.isRecording )
            return;
        _recordingWillBeStopped = YES;
        [self stopDuoAssetWriterLoop];
    });
#ifdef DEBUG
    NSLog( @"[Debug][-]%s", __PRETTY_FUNCTION__ );
#endif// DEBUG
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
            _previewLayer.orientation = (AVCaptureVideoOrientation)statusBarOrientation;
        }
    }
    else
    {
        if ( _previewLayer.connection.isVideoOrientationSupported )
        {
            _previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
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

- (void)didUpdateToLocation:(CLLocation *)aLocation
{
    dispatch_async( _clipWriterQueue, ^{
#ifdef DEBUG
        NSLog( @"[Debug]%.4f° %@, %.4f° %@",
              fabs( aLocation.coordinate.latitude ),
              aLocation.coordinate.latitude < 0 ? @"S" : @"N",
              fabs( aLocation.coordinate.longitude ),
              aLocation.coordinate.longitude < 0 ? @"W" : @"E" );
#endif// DEBUG
        _location = aLocation;
    });
}

#pragma mark - from AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    //
    // Get video info for preview
    //
	if ( connection == _videoConnection )
    {
        [self processVideoSample:sampleBuffer withFormat:formatDescription];
	}
    
    //
    // Write sample
    //
    CFRetain( sampleBuffer );
    CFRetain( formatDescription );
    dispatch_async( _clipWriterQueue, ^{
        for ( CarDVRAssetWriter *assetWriter in _duoAssetWriter )
        {
            if ( ![assetWriter isKindOfClass:[CarDVRAssetWriter class]] )
            {
                continue;
            }
            if ( connection == _videoConnection )
            {
                if ( !assetWriter.readyToRecordVideo )
                {
                    assetWriter.readyToRecordVideo = [self setupVideoInputForAssetWriter:assetWriter
                                                                       formatDescription:formatDescription];
                }
                if ( !_readyToRecordVideo )
                {
                    _readyToRecordVideo = assetWriter.readyToRecordVideo;
                }
                
                if ( assetWriter.readyToRecordVideo && assetWriter.readyToRecordAudio )
                {
                    [assetWriter writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo];
                }
            }
            else if ( connection == _audioConnection )
            {
                if ( !assetWriter.readyToRecordAudio )
                {
                    assetWriter.readyToRecordAudio = [self setupAudioInputForAssetWriter:assetWriter
                                                                       formatDescription:formatDescription];
                }
                if ( !_readyToRecordAudio )
                {
                    _readyToRecordAudio = assetWriter.readyToRecordAudio;
                }
                
                if ( assetWriter.readyToRecordAudio && assetWriter.readyToRecordVideo )
                {
                    [assetWriter writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio];
                }
            }
            BOOL isReadyToRecord = ( assetWriter.readyToRecordAudio && assetWriter.readyToRecordVideo );
			if ( !assetWriter.isRecording && isReadyToRecord )
            {
                assetWriter.recording = YES;
                assetWriter.recordingWillBeStarted = NO;
                if ( !self.isRecording )
                {
                    _recordingWillBeStarted = NO;
                    self.recording = YES;
                }
			}
        }
        CFRelease( formatDescription );
        CFRelease( sampleBuffer );
    });
}

#pragma mark - private methods
- (void)configAVCaptureSession
{
    [_captureSession beginConfiguration];
    if ( [_captureSession canSetSessionPreset:self.videoResolutionPreset] )
    {
        [_captureSession setSessionPreset:self.videoResolutionPreset];
    }
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_captureSession commitConfiguration];
}

- (void)configCamera
{
    AVCaptureDevice *currentCamera = [self videoDeviceWithPosition:self.settings.cameraPosition.integerValue];
    NSError *error = nil;
    [currentCamera lockForConfiguration:&error];
    if ( !error )
    {
        @try
        {
            CMTime frameDuration = CMTimeMake( 1, self.settings.videoFrameRate.integerValue );
            [currentCamera setActiveVideoMaxFrameDuration:frameDuration];
            [currentCamera setActiveVideoMinFrameDuration:frameDuration];
        }
        @catch ( NSException *exception )
        {
            // TODO: handle exception
            NSLog( @"[Error]failed to config current camera due to: %@", exception.description );
        }
        @finally
        {
            [currentCamera unlockForConfiguration];
        }
    }
}

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
    if ( [aSession canAddOutput:audioOutput] )
    {
        [aSession addOutput:audioOutput];
    }
    else
    {
        // TODO: handle error
    }
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
    if ( [aSession canAddOutput:videoOutput] )
    {
        [aSession addOutput:videoOutput];
    }
    else
    {
        // TODO: handle error
    }
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
    // Config, start
    //
    [self configCamera];
    [self configAVCaptureSession];
    [self installAVCaptureDeviceWithSession:_captureSession];
    
    [self fitDeviceOrientation];
    [_captureSession startRunning];
}

- (NSURL *)newRecordingClipURL
{
    NSDate *currentDate = [NSDate date];
    NSString *clipName = [NSString stringWithFormat:@"%@.MOV", [CarDVRPathHelper fileNameFromDate:currentDate]];
    NSURL *clipURL =  [NSURL fileURLWithPath:[self.pathHelper.recentsFolderURL.path stringByAppendingPathComponent:clipName]
                                 isDirectory:NO];
    return clipURL;
}

- (NSString *)newRecordingClipName
{
    NSDate *currentDate = [NSDate date];
    NSString *clipName = [CarDVRPathHelper fileNameFromDate:currentDate];
    return clipName;
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
    NSError *error = [aNotification.userInfo valueForKey:AVCaptureSessionErrorKey];
    NSLog( @"[Error] AVCaptureSession runtime error: domain(%@), code(%d), \"%@\"",
          error.domain, error.code, error.description );
    // TODO: handle error
}

- (void)handleAVCaptureSessionDidStopRunningNotification:(NSNotification *)aNotification
{
    dispatch_async( _clipWriterQueue, ^{
        if ( self.isRecording )
        {
            [self stopRecording];
        }
    });
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

- (void)handleCarDVRSettingsCommitEditingNotification:(NSNotification *)aNotification
{
    NSMutableSet *changedKeys = [aNotification.userInfo objectForKey:kCarDVRSettingsCommitEditingChangedKeys];
    if ( [changedKeys containsObject:kCarDVRSettingsKeyVideoQuality] )
    {
        [self configAVCaptureSession];
    }
    if ( [changedKeys containsObject:kCarDVRSettingsKeyVideoFrameRate] )
    {
        [self configCamera];
    }
}

- (void)handleStarredChangedNotification
{
    BOOL isStarred = self.settings.isStarred.boolValue;
    dispatch_async( _clipWriterQueue, ^{
        _isStarred = isStarred;
    });
}

- (void)startDuoAssetWriterLoop
{
    if ( !_duoAssetWriter )
    {
        _duoAssetWriter = [NSMutableArray arrayWithCapacity:kCountOfDuoRecordingClips];
    }
    [self startNextAssetWriter];
    [self updateSubtitles];
}

- (void)stopDuoAssetWriterLoop
{
    dispatch_async( dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    });
    NSUInteger didStopAssetWriterCount = 0;
    NSUInteger assetWriterCount = _duoAssetWriter.count;// It should alway be 2.
    for ( NSUInteger i = 0; ( i < assetWriterCount ) && ( didStopAssetWriterCount < assetWriterCount ) ; didStopAssetWriterCount++ )
    {
        if ( [self stopAssetWriter:[_duoAssetWriter objectAtIndex:i]] )
        {
            [_duoAssetWriter removeObjectAtIndex:i];
            continue;
        }
        i++;
    }
    if ( !_duoAssetWriter.count )
    {
        _readyToRecordAudio = NO;
        _readyToRecordVideo = NO;
        _recordingWillBeStarted = NO;
        _recordingWillBeStopped = NO;
        self.recording = NO;
    }
}

- (void)startNextAssetWriter
{
#ifdef DEBUG
    NSLog( @"[Debug][+]%s", __PRETTY_FUNCTION__ );
#endif// DEBUG
    dispatch_async( _clipWriterQueue, ^{
        NSURL *clipWriteFolderURL = _isStarred ? self.pathHelper.starredFolderURL : self.pathHelper.recentsFolderURL;
        CarDVRAssetWriter *assetWriter = [[CarDVRAssetWriter alloc] initWithFolderPath:clipWriteFolderURL.path
                                                                              clipName:[self newRecordingClipName]
                                                                              settings:self.settings
                                                                                 error:nil];
        [_duoAssetWriter addObject:assetWriter];
        assetWriter.recordingWillBeStarted = YES;
        [_recentRecordedClipURLs addObject:assetWriter.writer.outputURL];
        if ( _recentRecordedClipURLs.count > _settings.maxCountOfRecordingClips.unsignedIntegerValue )
        {
            NSURL *oldestClipURL = [_recentRecordedClipURLs objectAtIndex:0];
#ifdef DEBUG
            NSLog( @"[Debug] removing clip: %@", oldestClipURL );
#endif// DEBUG
            [[NSFileManager defaultManager] removeItemAtURL:oldestClipURL error:nil];
            [_recentRecordedClipURLs removeObjectAtIndex:0];
        }
        
        dispatch_async( dispatch_get_main_queue(), ^{
            NSTimeInterval startNextAssetWriterInterval =
                self.settings.maxRecordingDurationPerClip.doubleValue - self.settings.overlappedRecordingDuration.doubleValue;
            NSTimeInterval stopOldestAssetWriterInterval = self.settings.maxRecordingDurationPerClip.doubleValue;
            [self performSelector:@selector(stopOldestAssetWriter) withObject:nil afterDelay:stopOldestAssetWriterInterval];
            [self performSelector:@selector(startNextAssetWriter) withObject:nil afterDelay:startNextAssetWriterInterval];
        });
    });
#ifdef DEBUG
    NSLog( @"[Debug][-]%s", __PRETTY_FUNCTION__ );
#endif// DEBUG
}

- (BOOL)stopAssetWriter:(CarDVRAssetWriter *)anAssetWriter
{
#ifdef DEBUG
    NSLog( @"[Debug][+]%s", __PRETTY_FUNCTION__ );
#endif// DEBUG
    __block BOOL didStop = NO;
    [self stopRecordingOfAssetWriter:anAssetWriter withCompletionHandler:^(NSException *aException) {
        if ( anAssetWriter.writer.error )
        {
            // TODO: handle error
            NSLog( @"[Error] Failed to stop recording clip with status %d, and error: \"%@\"",
                  anAssetWriter.writer.status,
                  anAssetWriter.writer.error.description );
        }
        else
        {
            // ignore aException
#pragma unused( aException )
            didStop = YES;
        }
    }];
#ifdef DEBUG
    NSLog( @"[Debug][-]%s => returned %@", __PRETTY_FUNCTION__, didStop ? @"YES" : @"NO" );
#endif// DEBUG
    return didStop;
}

- (void)stopOldestAssetWriter
{
    dispatch_async( _clipWriterQueue, ^{
        if ( !_duoAssetWriter.count )
        {
            return;
        }
        
        CarDVRAssetWriter *oldestAssetWriter = [_duoAssetWriter objectAtIndex:0];
        if ( [self stopAssetWriter:oldestAssetWriter] )
        {
            [_duoAssetWriter removeObjectAtIndex:0];
        }
    });
}

- (void)updateSubtitles
{
    dispatch_async( _clipWriterQueue, ^{
        NSString *subtitle = [NSString stringWithFormat:@"%.4f° %@, %.4f° %@ | %.2f m",
              fabs( _location.coordinate.latitude ),
              _location.coordinate.latitude < 0 ? @"S" : @"N",
              fabs( _location.coordinate.longitude ),
              _location.coordinate.longitude < 0 ? @"W" : @"E",
                              _location.altitude];
        // todo: complete
        for ( CarDVRAssetWriter *assetWriter in _duoAssetWriter )
        {
            [assetWriter addSubtitle:subtitle];
        }
        dispatch_async( dispatch_get_main_queue(), ^{
            [self performSelector:@selector(updateSubtitles) withObject:nil afterDelay:kSubtitlesUpdatingInterval];
        });
    });
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

- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
	CGFloat angle = 0.0;
	
	switch (orientation)
    {
		case AVCaptureVideoOrientationPortrait:
			angle = 0.0;
			break;
		case AVCaptureVideoOrientationPortraitUpsideDown:
			angle = M_PI;
			break;
		case AVCaptureVideoOrientationLandscapeRight:
			angle = -M_PI_2;
			break;
		case AVCaptureVideoOrientationLandscapeLeft:
			angle = M_PI_2;
			break;
		default:
			break;
	}
    
	return angle;
}

- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
	CGAffineTransform transform = CGAffineTransformIdentity;
    
	// Calculate offsets from an arbitrary reference orientation (portrait)
	CGFloat orientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:orientation];
	CGFloat videoOrientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:_videoConnection.videoOrientation];
	
	// Find the difference in angle between the passed in orientation and the current video orientation
	CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
	transform = CGAffineTransformMakeRotation(angleOffset);
	
	return transform;
}

- (BOOL)setupVideoInputForAssetWriter:(CarDVRAssetWriter *)anAssetWriter
                    formatDescription:(CMFormatDescriptionRef)currentFormatDescription
{
	float bitsPerPixel;
	CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
	int numPixels = dimensions.width * dimensions.height;
	int bitsPerSecond;
	
	// Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
	if ( numPixels < ( 640 * 480 ) )
		bitsPerPixel = 4.05;// This bitrate matches the quality produced by AVCaptureSessionPresetMedium or Low.
	else
		bitsPerPixel = 11.4;// This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
	
	bitsPerSecond = numPixels * bitsPerPixel;
	
	NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
											  AVVideoCodecH264, AVVideoCodecKey,
											  [NSNumber numberWithInteger:dimensions.width], AVVideoWidthKey,
											  [NSNumber numberWithInteger:dimensions.height], AVVideoHeightKey,
											  [NSDictionary dictionaryWithObjectsAndKeys:
											   [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
											   [NSNumber numberWithInteger:30], AVVideoMaxKeyFrameIntervalKey,
											   nil], AVVideoCompressionPropertiesKey,
											  nil];
	if ( [anAssetWriter.writer canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo] )
    {
        if ( !anAssetWriter.videoInput )
        {
            AVAssetWriterInput *videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo
                                                                            outputSettings:videoCompressionSettings];
            videoInput.expectsMediaDataInRealTime = YES;
            UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
            videoInput.transform =
                [self transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)statusBarOrientation];
            if ( [anAssetWriter.writer canAddInput:videoInput] )
            {
                anAssetWriter.videoInput = videoInput;
                [anAssetWriter.writer addInput:videoInput];
            }
            else
            {
                // TODO: handle error
                NSLog(@"[Error] Couldn't add asset writer video input.");
                return NO;
            }
        }
	}
	else {
        // TODO: handle error
		NSLog(@"[Error] Couldn't apply video output settings.");
        return NO;
	}
    
    return YES;
}

- (BOOL)setupAudioInputForAssetWriter:(CarDVRAssetWriter *)anAssetWriter
                    formatDescription:(CMFormatDescriptionRef)currentFormatDescription
{
    const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
    
	size_t aclSize = 0;
	const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
	NSData *currentChannelLayoutData = nil;
	
	// AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
	if ( currentChannelLayout && aclSize > 0 )
		currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
	else
		currentChannelLayoutData = [NSData data];
	
	NSDictionary *audioCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
											  [NSNumber numberWithInteger:kAudioFormatMPEG4AAC], AVFormatIDKey,
											  [NSNumber numberWithFloat:currentASBD->mSampleRate], AVSampleRateKey,
											  [NSNumber numberWithInt:64000], AVEncoderBitRatePerChannelKey,
											  [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame], AVNumberOfChannelsKey,
											  currentChannelLayoutData, AVChannelLayoutKey,
											  nil];
	if ( [anAssetWriter.writer canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio] )
    {
        if ( !anAssetWriter.audioInput )
        {
            AVAssetWriterInput *audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                                                            outputSettings:audioCompressionSettings];
            audioInput.expectsMediaDataInRealTime = YES;
            if ( [anAssetWriter.writer canAddInput:audioInput] )
            {
                anAssetWriter.audioInput = audioInput;
                [anAssetWriter.writer addInput:audioInput];
            }
            else
            {
                // TODO: handle error
                NSLog(@"Couldn't add asset writer audio input.");
                return NO;
            }
        }
	}
	else
    {
        // TODO: handle error
		NSLog(@"Couldn't apply audio output settings.");
        return NO;
	}
    
    return YES;
}

- (void)stopRecordingOfAssetWriter:(CarDVRAssetWriter *)anAssetWriter
             withCompletionHandler:(void (^)(NSException *aException))aBlock
{
    NSException *outException;
    @try
    {
#ifdef DEBUG
        BOOL finished =
#endif// DEBUG
        [anAssetWriter finishWriting];
#ifdef DEBUG
        NSLog( @"[Debug] asset writer = %pt, finished = %d", anAssetWriter, finished );
#endif// DEBUG
        /*
        if ( floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_6_0 )
        {
#ifdef DEBUG
            BOOL finished =
#endif// DEBUG
            [anAssetWriter.writer finishWriting];
#ifdef DEBUG
            NSLog( @"finished = %d", finished );
#endif// DEBUG
        }
        else
        {
            [anAssetWriter.writer finishWritingWithCompletionHandler:^{
            }];
        }
         */
    }
    @catch ( NSException *exception )
    {
        outException = exception;
    }
    @finally
    {
        aBlock( outException );
    }
}

#pragma mark - methods processing video
- (void)processVideoSample:(CMSampleBufferRef)aSampleBuffer withFormat:(CMFormatDescriptionRef)aFormatDescription
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer( aSampleBuffer );
    CVPixelBufferLockBaseAddress( imageBuffer, 0 );
    // TODO: complete
    
    CVPixelBufferUnlockBaseAddress( imageBuffer, 0 );
}

@end
