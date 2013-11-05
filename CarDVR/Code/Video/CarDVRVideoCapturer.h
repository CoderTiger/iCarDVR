//
//  CarDVRVideoCapturer.h
//  CarDVR
//
//  Created by yxd on 13-10-15.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CarDVRPathHelper.h"
#import "CarDVRVideoCapturerConstants.h"

@interface CarDVRVideoCapturer : NSObject

@property (weak, nonatomic) UIView *previewerView;
@property (readonly, nonatomic, getter = isRunning) BOOL running;
@property (readonly, nonatomic) BOOL hasBackCamera;
@property (readonly, nonatomic) BOOL hasFrontCamera;
@property (assign, nonatomic) CarDVRCameraFlashMode cameraFlashMode;
@property (assign, nonatomic) BOOL starred;

#pragma mark - config properties
@property (assign, nonatomic) CarDVRVideoQuality videoQuality;
@property (assign, nonatomic) CarDVRCameraPosition cameraPosition;

- (id)initWithPathHelper:(CarDVRPathHelper *)aPathHelper;

- (void)start;
- (void)stop;
- (void)fitDeviceOrientation;
- (void)focus;

#pragma mark - config methods
//- (void)beginConfiguration;
//- (void)commitConfiguration;
//- (void)cancelConfig;

@end
