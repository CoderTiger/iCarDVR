//
//  CarDVRSettings.h
//  CarDVR
//
//  Created by yxd on 13-10-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CarDVRStorageInfo.h"

FOUNDATION_EXPORT NSString *const kCarDVRSettingsCommitEditingChangedKeys;

FOUNDATION_EXPORT NSString *const kCarDVRSettingsKeyMaxRecordingDuration;
FOUNDATION_EXPORT NSString *const kCarDVRSettingsKeyOverlappedRecordingDuration;
FOUNDATION_EXPORT NSString *const kCarDVRSettingsKeyMaxCountOfRecordingClips;
FOUNDATION_EXPORT NSString *const kCarDVRSettingsKeyCameraPosition;
FOUNDATION_EXPORT NSString *const kCarDVRSettingsKeyVideoResolution;
FOUNDATION_EXPORT NSString *const kCarDVRSettingsKeyVideoFrameRate;
FOUNDATION_EXPORT NSString *const kCarDVRSettingsKeyStarred;
FOUNDATION_EXPORT NSString *const kCarDVRSettingsKeyTracksMapType;
FOUNDATION_EXPORT NSString *const kCarDVRSettingsKeyRemoveClipsInRecentsBeforeRecording;
FOUNDATION_EXPORT NSString *const kCarDVRSettingsKeyTrackLogOn;

typedef enum
{
    kCarDVRMapTypeStandard = 0,
    kCarDVRMapTypeSatellite,
    kCarDVRMapTypeHybrid
}CarDVRMapType;

@class CarDVRPathHelper;
@interface CarDVRSettings : NSObject

#pragma mark - static settings
@property (strong, readonly, nonatomic) CarDVRStorageInfo *storageInfo;

#pragma mark - dynamic settings
@property (copy, nonatomic) NSNumber *maxRecordingDurationPerClip;// second, NSTimeInterval
@property (copy, nonatomic) NSNumber *overlappedRecordingDuration;// second, NSTimeInterval
@property (copy, nonatomic) NSNumber *maxCountOfRecordingClips;// NSUinteger [2, 10]
@property (copy, nonatomic) NSNumber *cameraPosition;// CarDVRCameraPosition
@property (copy, nonatomic) NSNumber *videoResolution;// CarDVRVideoResolution
@property (copy, nonatomic) NSNumber *videoFrameRate;// NSUinteger [10, 30]
@property (copy, nonatomic, getter = isStarred) NSNumber *starred;// BOOL
@property (copy, nonatomic) NSNumber *tracksMapType;// CarDVRMapType
@property (copy, nonatomic) NSNumber *removeClipsInRecentsBeforeRecording;// BOOL
@property (copy, nonatomic, getter = isTrackLogOn) NSNumber *trackLogOn;// BOOL

- (id)initWithPathHelper:(CarDVRPathHelper *)aPathHelper;

- (void)addObserver:(id)anObserver selector:(SEL)aSelector forKey:(NSString *)aKey;
- (void)removeObserver:(id)anObserver forKey:(NSString *)aKey;
- (void)removeObserver:(id)anObserver;

- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;

- (void)beginEditing;
- (void)commitEditing;
- (void)addCommitEditingObserver:(id)anObserver selector:(SEL)aSelector;
- (void)cancelEditing;

@end
