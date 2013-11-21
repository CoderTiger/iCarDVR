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
@property (readonly, getter = isRecording) BOOL recording;
@property (readonly) BOOL hasBackCamera;
@property (readonly) BOOL hasFrontCamera;
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
