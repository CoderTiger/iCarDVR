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
    kCarDVRVideoResolutionHigh,
    kCarDVRVideoResolutionMiddle,
    kCarDVRVideoResolutionLow,
    kCarDVRVideoResolution352x288,
    kCarDVRVideoResolution640x480,
    kCarDVRVideoResolution1280x720,
    kCarDVRVideoResolution1920x1080,
    kCarDVRVideoResolutioniFrame960x540,
    kCarDVRVideoResolutioniFrame1280x720
}
CarDVRVideoResolution;

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

FOUNDATION_EXPORT NSString *const kCarDVRVideoCapturerDidStartRecordingNotification;
FOUNDATION_EXPORT NSString *const kCarDVRVideoCapturerDidStopRecordingNotification;
FOUNDATION_EXPORT NSString *const kCarDVRVideoCapturerUpdateSubtitlesNotification;
FOUNDATION_EXPORT NSString *const kCarDVRVideoCapturerDidStartCapturingImageNotification;
FOUNDATION_EXPORT NSString *const kCarDVRVideoCapturerDidStopCapturingImageNotification;
FOUNDATION_EXPORT NSString *const kCarDVRErrorKey;
FOUNDATION_EXPORT NSString *const kCarDVRClipURLListKey;

#endif
