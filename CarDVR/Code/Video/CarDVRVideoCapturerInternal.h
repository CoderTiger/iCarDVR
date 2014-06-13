//
//  CarDVRVideoCapturerInterval.h
//  CarDVR
//
//  Created by yxd on 13-10-28.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CarDVRVideoCapturerConstants.h"

@class CarDVRPathHelper;
@class CarDVRSettings;
@interface CarDVRVideoCapturerInternal : NSObject

@property (weak, nonatomic) UIView *previewerView;
@property (readonly, getter = isRecording, nonatomic) BOOL recording;
@property (readonly) BOOL hasBackCamera;
@property (readonly) BOOL hasFrontCamera;
@property (assign, nonatomic) CarDVRCameraFlashMode cameraFlashMode;

- (id)initWithCapturer:(id)aCapturer
            pathHelper:(CarDVRPathHelper *)aPathHelper
              settings:(CarDVRSettings *)aSettings;
- (void)startRecording;
- (void)stopRecording;
- (void)captureStillImage;
- (void)fitDeviceOrientation;
- (void)focus;
- (void)didUpdateToLocation:(CLLocation *)aLocation;

@end
