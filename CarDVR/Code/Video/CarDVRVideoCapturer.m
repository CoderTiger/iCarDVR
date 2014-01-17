//
//  CarDVRVideoCapturer.m
//  CarDVR
//
//  Created by yxd on 13-10-15.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRVideoCapturer.h"
#import <AVFoundation/AVFoundation.h>
#import "CarDVRVideoCapturerInterval.h"

NSString *const kCarDVRVideoCapturerDidStartRecordingNotification = @"kCarDVRVideoCapturerDidStartRecordingNotification";
NSString *const kCarDVRVideoCapturerDidStopRecordingNotification = @"kCarDVRVideoCapturerDidStopRecordingNotification";

@interface CarDVRVideoCapturer ()
{
    CarDVRVideoCapturerInterval *_interval;
}
@end

@implementation CarDVRVideoCapturer

- (void)setPreviewerView:(UIView *)previewerView
{
    [_interval setPreviewerView:previewerView];
}

- (UIView *)previewerView
{
    return _interval.previewerView;
}

- (BOOL)isRecording
{
    return _interval.isRecording;
}

- (BOOL)hasBackCamera
{
    return _interval.hasBackCamera;
}

- (BOOL)hasFrontCamera
{
    return _interval.hasFrontCamera;
}

- (void)setCameraFlashMode:(CarDVRCameraFlashMode)cameraFlashMode
{
    [_interval setCameraFlashMode:cameraFlashMode];
}

- (CarDVRCameraFlashMode)cameraFlashMode
{
    return _interval.cameraFlashMode;
}

- (void)setStarred:(BOOL)starred
{
    [_interval setStarred:starred];
}

- (BOOL)starred
{
    return _interval.starred;
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
        _interval = [[CarDVRVideoCapturerInterval alloc] initWithCapturer:self
                                                               pathHelper:aPathHelper
                                                                 settings:aSettings];
    }
    return self;
}

- (void)startRecording
{
    [_interval startRecording];
}

- (void)stopRecording
{
    [_interval stopRecording];
}

- (void)fitDeviceOrientation
{
    [_interval fitDeviceOrientation];
}

- (void)focus
{
    [_interval focus];
}

- (void)didUpdateToLocation:(CLLocation *)aLocation
{
    [_interval didUpdateToLocation:aLocation];
}

@end
