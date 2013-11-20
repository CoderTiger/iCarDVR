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
    kCarDVRVideoQualityHigh,
    kCarDVRVideoQualityMiddle,
    kCarDVRVideoQualityLow
}
CarDVRVideoQuality;

typedef enum
{
    kCarDVRCameraPositionBack,
    kCarDVRCameraPositionFront
}
CarDVRCameraPosition;

typedef enum
{
    kCarDVRCameraFlashModeOff,
    kCarDVRCameraFlashModeOn,
    kCarDVRCameraFlashModeAuto
}CarDVRCameraFlashMode;

FOUNDATION_EXTERN NSString *const kCarDVRVideoCapturerDidStartRecordingNotification;
FOUNDATION_EXTERN NSString *const kCarDVRVideoCapturerDidStopRecordingNotification;

#endif
