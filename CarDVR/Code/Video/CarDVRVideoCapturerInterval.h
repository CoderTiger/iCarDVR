//
//  CarDVRVideoCapturerInterval.h
//  CarDVR
//
//  Created by yxd on 13-10-28.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CarDVRVideoCapturerConstants.h"

@class CarDVRPathHelper;
@class CarDVRSettings;
@interface CarDVRVideoCapturerInterval : NSObject

@property (weak, nonatomic) UIView *previewerView;
@property (readonly, nonatomic, getter = isRecording) BOOL recording;
@property (readonly, nonatomic) BOOL hasBackCamera;
@property (readonly, nonatomic) BOOL hasFrontCamera;
@property (assign, nonatomic) CarDVRCameraFlashMode cameraFlashMode;
@property (assign, nonatomic) BOOL starred;

- (id)initWithCapturer:(id)aCapturer
            pathHelper:(CarDVRPathHelper *)aPathHelper
              settings:(CarDVRSettings *)aSettings;
- (void)startRecording;
- (void)stopRecording;
- (void)fitDeviceOrientation;
- (void)focus;

@end
