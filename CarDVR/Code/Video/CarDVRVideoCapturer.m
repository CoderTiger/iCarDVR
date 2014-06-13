//
//  CarDVRVideoCapturer.m
//  CarDVR
//
//  Created by yxd on 13-10-15.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRVideoCapturer.h"
#import <AVFoundation/AVFoundation.h>
#import "CarDVRVideoCapturerInternal.h"

NSString *const kCarDVRVideoCapturerDidStartRecordingNotification = @"kCarDVRVideoCapturerDidStartRecordingNotification";
NSString *const kCarDVRVideoCapturerDidStopRecordingNotification = @"kCarDVRVideoCapturerDidStopRecordingNotification";
NSString *const kCarDVRVideoCapturerUpdateSubtitlesNotification = @"kCarDVRVideoCapturerUpdateSubtitlesNotification";
NSString *const kCarDVRVideoCapturerDidStartCapturingImageNotification = @"kCarDVRVideoCapturerDidStartCapturingImageNotification";
NSString *const kCarDVRVideoCapturerDidStopCapturingImageNotification = @"kCarDVRVideoCapturerDidStopCapturingImageNotification";
NSString *const kCarDVRErrorKey = @"kCarDVRErrorKey";
NSString *const kCarDVRClipURLListKey = @"kCarDVRClipURLListKey";

@interface CarDVRVideoCapturer ()
{
    CarDVRVideoCapturerInternal *_internal;
}
@end

@implementation CarDVRVideoCapturer

- (void)setPreviewerView:(UIView *)previewerView
{
    [_internal setPreviewerView:previewerView];
}

- (UIView *)previewerView
{
    return _internal.previewerView;
}

- (BOOL)isRecording
{
    return _internal.isRecording;
}

- (BOOL)hasBackCamera
{
    return _internal.hasBackCamera;
}

- (BOOL)hasFrontCamera
{
    return _internal.hasFrontCamera;
}

- (void)setCameraFlashMode:(CarDVRCameraFlashMode)cameraFlashMode
{
    [_internal setCameraFlashMode:cameraFlashMode];
}

- (CarDVRCameraFlashMode)cameraFlashMode
{
    return _internal.cameraFlashMode;
}

- (id)init
{
    NSException *exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@"CarDVRVideoCapturer::init is not supported."
                                                   userInfo:nil];
    @throw exception;
}

- (id)initWithPathHelper:(CarDVRPathHelper *)aPathHelper settings:(CarDVRSettings *)aSettings
{
    self = [super init];
    if ( self )
    {
        if ( !aPathHelper )
        {
            NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                             reason:@"aPathHelper is nil"
                                                           userInfo:nil];
            @throw exception;
        }
        if ( !aSettings )
        {
            NSException *exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                             reason:@"aSettings is nil"
                                                           userInfo:nil];
            @throw exception;
        }
        _internal = [[CarDVRVideoCapturerInternal alloc] initWithCapturer:self
                                                               pathHelper:aPathHelper
                                                                 settings:aSettings];
    }
    return self;
}

- (void)startRecording
{
    [_internal startRecording];
}

- (void)stopRecording
{
    [_internal stopRecording];
}

- (void)captureStillImage
{
    [_internal captureStillImage];
}

- (void)fitDeviceOrientation
{
    [_internal fitDeviceOrientation];
}

- (void)focus
{
    [_internal focus];
}

- (void)didUpdateToLocation:(CLLocation *)aLocation
{
    [_internal didUpdateToLocation:aLocation];
}

@end
