//
//  CarDVRVideoCapturer.h
//  CarDVR
//
//  Created by yxd on 13-10-15.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CarDVRVideoCapturerConstants.h"

@class CarDVRPathHelper;
@class CarDVRSettings;
@interface CarDVRVideoCapturer : NSObject

@property (weak, nonatomic) UIView *previewerView;
@property (readonly, nonatomic, getter = isRecording) BOOL recording;
@property (readonly, nonatomic) BOOL hasBackCamera;
@property (readonly, nonatomic) BOOL hasFrontCamera;
@property (assign, nonatomic) CarDVRCameraFlashMode cameraFlashMode;

- (id)initWithPathHelper:(CarDVRPathHelper *)aPathHelper settings:(CarDVRSettings *)aSettings;

- (void)startRecording;
- (void)stopRecording;
- (void)captureStillImage;
- (void)fitDeviceOrientation;
- (void)focus;
- (void)didUpdateToLocation:(CLLocation *)aLocation;

@end
