//
//  CarDVRVideoCapturerInterval.h
//  CarDVR
//
//  Created by yxd on 13-10-28.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CarDVRVideoCapturer.h"

@interface CarDVRVideoCapturerInterval : NSObject

@property (weak, nonatomic) UIView *previewerView;
@property (readonly, nonatomic, getter = isRunning) BOOL running;
@property (readonly, nonatomic) BOOL hasBackCamera;
@property (readonly, nonatomic) BOOL hasFrontCamera;
@property (assign, nonatomic) CarDVRCameraFlashMode cameraFlashMode;
@property (assign, nonatomic) BOOL starred;

#pragma mark - config properties
@property (assign, nonatomic) CarDVRVideoQuality videoQuality;
@property (assign, nonatomic) CarDVRCameraPosition cameraPosition;

- (id)initWithQueue:(dispatch_queue_t)aQueue pathHelper:(CarDVRPathHelper *)aPathHelper;
- (void)start;
- (void)stop;
- (void)fitDeviceOrientation;
- (void)focus;

@end
