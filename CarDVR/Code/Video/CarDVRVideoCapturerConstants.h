//
//  CarDVRVideoCapturerConstants.h
//  CarDVR
//
//  Created by yxd on 13-11-5.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#ifndef CarDVR_CarDVRVideoCapturerConstants_h
#define CarDVR_CarDVRVideoCapturerConstants_h

typedef enum
{
    CarDVRVideoQualityHigh,
    CarDVRVideoQualityMiddle,
    CarDVRVideoQualityLow
}
CarDVRVideoQuality;

typedef enum
{
    CarDVRCameraPositionBack,
    CarDVRCameraPositionFront
}
CarDVRCameraPosition;

typedef enum
{
    CarDVRCameraFlashModeOff,
    CarDVRCameraFlashModeOn,
    CarDVRCameraFlashModeAuto
}CarDVRCameraFlashMode;

FOUNDATION_EXTERN NSString *const kCarDVRVideoCapturerDidStartRecordingNotification;
FOUNDATION_EXTERN NSString *const kCarDVRVideoCapturerDidStopRecordingNotification;

#endif
