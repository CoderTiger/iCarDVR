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

@interface CarDVRVideoCapturer ()
{
    dispatch_queue_t _workQueue;
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

- (BOOL)isRunning
{
    return _interval.isRunning;
}

- (BOOL)hasBackCamera
{
    return _interval.hasBackCamera;
}

- (BOOL)hasFrontCamera
{
    return _interval.hasFrontCamera;
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

- (id)initWithPathHelper:(CarDVRPathHelper *)aPathHelper
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
        _workQueue = dispatch_queue_create( "CarDVRVideoCapturerWorkQueue", NULL );
        _interval = [[CarDVRVideoCapturerInterval alloc] initWithQueue:_workQueue pathHelper:aPathHelper];
    }
    return self;
}

- (void)start
{
    [_interval start];
}

- (void)stop
{
    [_interval stop];
}

- (void)fitDeviceOrientation
{
    [_interval fitDeviceOrientation];
}

- (void)focus
{
    [_interval focus];
}

@end
