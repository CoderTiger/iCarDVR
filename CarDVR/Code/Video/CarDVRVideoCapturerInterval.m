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

static const NSUInteger kCountOfDuoRecordingClips = 2;
static const char kVideoCaptureQueueName[] = "com.iAutoD.videoCaptureQueue";
static const char kAudioCaptureQueueName[] = "com.iAutoD.audioCaptureQueue";
static const char kClipWriterQueueName[] = "com.iAutoD.clipWriterQueue";

@interface CarDVRVideoCapturerInterval ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{
    BOOL _willStopRecording;
    
    dispatch_queue_t _clipWriterQueue;
    AVCaptureSession *_captureSession;
    AVCaptureConnection *_audioConnection;
	AVCaptureConnection *_videoConnection;
    
//    AVAssetWriter *assetWriter;
//    AVAssetWriterInput *assetWriterVideoInput;
//    AVAssetWriterInput *assetWriterAudioInput;
    
    // Only accessed on movie writing queue
    NSMutableArray *_duoAssetWriter;// CarDVRAssetWriter
    NSMutableArray *_recentRecordedClipURLs;// NSURL
    BOOL _readyToRecordAudio;
    BOOL _readyToRecordVideo;
	BOOL _recordingWillBeStarted;
	BOOL _recordingWillBeStopped;
}

#pragma mark - redeclared public properties as readwrite
@property (readwrite, getter = isRecording) BOOL recording;

#pragma mark - private properties
@property (weak, nonatomic) id capturer;
@property (weak, nonatomic) CarDVRPathHelper *pathHelper;
@property (weak, nonatomic) CarDVRSettings *settings;
@property (readonly, copy, nonatomic) NSString *const videoResolutionPreset;

@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@property (strong, nonatomic) NSMutableArray *duoRecordingLoopTimer;// NSTimer

@property (assign, nonatomic, getter = isBatchConfiguration) BOOL batchConfiguration;

#pragma mark - private methods
- (void)installAVCaptureDeviceWithSession:(AVCaptureSession *)aSession;
- (void)installAVCaptureObjects;
- (void)setOrientation:(UIInterfaceOrientation)anOrientation
    forMovieFileOutput:(AVCaptureMovieFileOutput *)aMovieFileOutput;
- (NSURL *)newRecordingClipURL;
- (void)handleAVCaptureSessionRuntimeErrorNotification:(NSNotification *)aNotification;
- (void)handleAVCaptureSessionDidStopRunningNotification:(NSNotification *)aNotification;
- (void)handleUIApplicationDidBecomeActiveNotification;
- (void)handleUIApplicationDidEnterBackgroundNotification;
- (void)handleRecordingLoopTimer:(NSTimer *)aTimer;

- (AVCaptureDevice *)videoDeviceWithPosition:(CarDVRCameraPosition)aPosition;
- (AVCaptureDevice *)audioDevice;
- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation;
- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation;
- (BOOL)setupVideoInputForAssetWriter:(CarDVRAssetWriter *)anAssetWriter
                    formatDescription:(CMFormatDescriptionRef)currentFormatDescription;
- (BOOL)setupAudioInputForAssetWriter:(CarDVRAssetWriter *)anAssetWriter
                    formatDescription:(CMFormatDescriptionRef)currentFormatDescription;

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
    AVCaptureDevice *backCamera = [self videoDeviceWithPosition:kCarDVRCameraPositionBack];
    return ( backCamera != nil );
}

- (BOOL)hasFrontCamera
{
    AVCaptureDevice *frontCamera = [self videoDeviceWithPosition:kCarDVRCameraPositionFront];
    return ( frontCamera != nil );
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
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_async( _clipWriterQueue, ^{
        
        if ( _recordingWillBeStarted || self.isRecording )
            return;
        _recordingWillBeStarted = YES;
        
        //
        // Init asset writer
        //
        _duoAssetWriter = [NSMutableArray arrayWithCapacity:kCountOfDuoRecordingClips];
        
        //
        // Remove the recent recorded clips.
        //
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *recentRecordedClips = [fileManager contentsOfDirectoryAtPath:self.pathHelper.recentsFolderPath
                                                                        error:nil];
        if ( recentRecordedClips )
        {
            for ( NSString *clipFileName in recentRecordedClips )
            {
                [fileManager removeItemAtPath:[self.pathHelper.recentsFolderPath stringByAppendingPathComponent:clipFileName]
                                        error:nil];
            }
        }
        
        //
        // Prepare recent recoreded clips
        //
        _recentRecordedClipURLs = [NSMutableArray arrayWithCapacity:self.settings.maxCountOfRecordingClips.unsignedIntegerValue];
        
        //
        // Start recording timer
        //
        dispatch_async( currentQueue, ^{
            if ( !self.duoRecordingLoopTimer )
            {
                self.duoRecordingLoopTimer = [NSMutableArray arrayWithCapacity:kCountOfDuoRecordingClips];
                for ( NSUInteger i = 0; i < kCountOfDuoRecordingClips; i++ )
                {
                    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.settings.maxRecordingDuration.doubleValue
                                                                      target:self
                                                                    selector:@selector(handleRecordingLoopTimer:)
                                                                    userInfo:nil
                                                                     repeats:YES];
                    [self.duoRecordingLoopTimer addObject:timer];
                }
                NSDate *firstRecordingDate = [NSDate date];
                NSDate *secondRecordingDate = [NSDate dateWithTimeInterval:(self.settings.maxRecordingDuration.doubleValue
                                                                            - self.settings.overlappedRecordingDuration.doubleValue)
                                                                 sinceDate:firstRecordingDate];
                [self.duoRecordingLoopTimer[0] setFireDate:firstRecordingDate];
                [self.duoRecordingLoopTimer[1] setFireDate:secondRecordingDate];
            }
            else
            {
                NSAssert1( self.duoRecordingLoopTimer.count == kCountOfDuoRecordingClips,
                          @"Wrong count of recording loop timers: %u", self.duoRecordingLoopTimer.count );
                NSDate *firstRecordingDate = [NSDate date];
                NSDate *secondRecordingDate = [NSDate dateWithTimeInterval:(self.settings.maxRecordingDuration.doubleValue
                                                                            - self.settings.overlappedRecordingDuration.doubleValue)
                                                                 sinceDate:firstRecordingDate];
                [self.duoRecordingLoopTimer[0] setFireDate:firstRecordingDate];
                [self.duoRecordingLoopTimer[1] setFireDate:secondRecordingDate];
            }
        });
    });
}

- (void)stopRecording
{
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
    dispatch_async( _clipWriterQueue, ^{
        
        if ( _recordingWillBeStopped || !self.isRecording )
            return;
        _recordingWillBeStopped = YES;
        
        //
        // Stop recording loop timer
        //
        dispatch_async( currentQueue, ^{
            for ( NSTimer *timer in self.duoRecordingLoopTimer )
            {
                [timer invalidate];
            }
        });
        
        //
        // Stop asset writer
        //
        __block NSUInteger didStopRecordingCount = 0;
        for ( CarDVRAssetWriter *assetWriter in _duoAssetWriter )
        {
            [assetWriter.writer finishWritingWithCompletionHandler:^{
                if ( assetWriter.writer.error )
                {
                    NSLog( @"[Error] %@", assetWriter.writer.error );
                }
                else
                {
                    didStopRecordingCount++;
                    if ( didStopRecordingCount == _duoAssetWriter.count )
                    {
                        [[NSNotificationCenter defaultCenter] postNotificationName:kCarDVRVideoCapturerDidStopRecordingNotification
                                                                            object:self.capturer];
                    }
                }
            }];
        }
    });
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
		/*
		// Get framerate
		CMTime timestamp = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );
		[self calculateFramerateAtTimestamp:timestamp];
        
		// Get frame dimensions (for onscreen display)
		if (self.videoDimensions.width == 0 && self.videoDimensions.height == 0)
			self.videoDimensions = CMVideoFormatDescriptionGetDimensions( formatDescription );
		
		// Get buffer type
		if ( self.videoType == 0 )
			self.videoType = CMFormatDescriptionGetMediaSubType( formatDescription );
        
		CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
		
		// Synchronously process the pixel buffer to de-green it.
		[self processPixelBuffer:pixelBuffer];
		
		// Enqueue it for preview.  This is a shallow queue, so if image processing is taking too long,
		// we'll drop this frame for preview (this keeps preview latency low).
		OSStatus err = CMBufferQueueEnqueue(previewBufferQueue, sampleBuffer);
		if ( !err ) {
			dispatch_async(dispatch_get_main_queue(), ^{
				CMSampleBufferRef sbuf = (CMSampleBufferRef)CMBufferQueueDequeueAndRetain(previewBufferQueue);
				if (sbuf) {
					CVImageBufferRef pixBuf = CMSampleBufferGetImageBuffer(sbuf);
					[self.delegate pixelBufferReadyForDisplay:pixBuf];
					CFRelease(sbuf);
				}
			});
		}
        */
	}
    
    //
    // Write sample
    //
    CFRetain( sampleBuffer );
	CFRetain( formatDescription );
    dispatch_async( _clipWriterQueue, ^{
        
        for ( CarDVRAssetWriter *assetWriter in _duoAssetWriter )
        {
            BOOL wasReadyToRecord = ( assetWriter.readyToRecordVideo && assetWriter.readyToRecordVideo );
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
			if ( !wasReadyToRecord && isReadyToRecord )
            {
                assetWriter.recordingWillBeStarted = NO;
                if ( !self.isRecording )
                {
                    _recordingWillBeStarted = NO;
                    self.recording = YES;
                    [[NSNotificationCenter defaultCenter] postNotificationName:kCarDVRVideoCapturerDidStartRecordingNotification
                                                                        object:self.capturer];
                }
			}
        }
        
        CFRelease( formatDescription );
        CFRelease( sampleBuffer );
    });
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
    NSString *clipName = [NSString stringWithFormat:@"%@.MOV", [CarDVRPathHelper stringFromDate:currentDate]];
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
    NSError *error = [aNotification.userInfo valueForKey:AVCaptureSessionErrorKey];
    NSLog( @"[Error] %@", error );
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

- (void)handleRecordingLoopTimer:(NSTimer *)aTimer
{
#ifdef DEBUG
    NSLog( @"[Timer] %pt", aTimer );
#endif// DEBUG
    NSUInteger nextRecordingClipIndex = [self.duoRecordingLoopTimer indexOfObject:aTimer];
    if ( nextRecordingClipIndex == NSNotFound )
    {
        // TODO: handle error
        return;
    }
    dispatch_async( _clipWriterQueue, ^{
        CarDVRAssetWriter *assetWriter;
        if ( nextRecordingClipIndex < _duoAssetWriter.count )
        {
            assetWriter = [_duoAssetWriter objectAtIndex:nextRecordingClipIndex];
            
            NSInteger systemMainVersion = [[[UIDevice currentDevice] systemVersion] integerValue];
            @try
            {
                if ( systemMainVersion < 6 )
                {
                    if ( ![assetWriter.writer finishWriting] )
                    {
                        NSLog( @"[Error] failed on AVAssetWriter::finishWriting with status %d, and error: %@",
                              assetWriter.writer.status,
                              assetWriter.writer.error );
                        // TODO: handle error
                    }
                }
                else
                {
                    [assetWriter.writer finishWritingWithCompletionHandler:^{
                        if ( assetWriter.writer.error )
                        {
                            NSLog( @"[Error] failed on AVAssetWriter::finishWritingWithCompletionHandler with status %d, and error: %@",
                                  assetWriter.writer.status,
                                  assetWriter.writer.error );
                            // TODO: handle error
                        }
                    }];
                }
            }
            @catch ( NSException *exception )
            {
                NSLog( @"[Error] failed to cause AVAssetWriter to finish writing due to exception: %@", exception );
                // TODO: handle error
            }
            @finally
            {
                // do nothing
            }
        }
        else
        {
            assetWriter = [[CarDVRAssetWriter alloc] initWithURL:[self newRecordingClipURL]
                                                        settings:_settings
                                                           error:nil];
            if ( assetWriter )
            {
                assetWriter.recordingWillBeStarted = YES;
                
                [_duoAssetWriter addObject:assetWriter];
                [_recentRecordedClipURLs addObject:assetWriter.writer.outputURL];
                if ( _recentRecordedClipURLs.count >= _settings.maxCountOfRecordingClips.unsignedIntegerValue )
                {
                    NSURL *oldestClipURL = [_recentRecordedClipURLs objectAtIndex:0];
                    NSError *error;
                    [[NSFileManager defaultManager] removeItemAtURL:oldestClipURL error:&error];
                    if ( error )
                    {
                        // Just log the error.
                        NSLog( @"[Error] %@", error );
                    }
                    [_recentRecordedClipURLs removeObjectAtIndex:0];
                }
            }
        }
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
            videoInput.transform = [self transformFromCurrentVideoOrientationToOrientation:statusBarOrientation];
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

@end
