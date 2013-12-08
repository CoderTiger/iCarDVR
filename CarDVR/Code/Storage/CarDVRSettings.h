//
//  CarDVRSettings.h
//  CarDVR
//
//  Created by yxd on 13-10-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>

NSString *const kCarDVRSettingsCommitEditingChangedKeys;

NSString *const kCarDVRSettingsKeyMaxRecordingDuration;
NSString *const kCarDVRSettingsKeyOverlappedRecordingDuration;
NSString *const kCarDVRSettingsKeyMaxCountOfRecordingClips;
NSString *const kCarDVRSettingsKeyCameraPosition;
NSString *const kCarDVRSettingsKeyVideoQuality;

@class CarDVRPathHelper;
@interface CarDVRSettings : NSObject

@property (copy, nonatomic) NSNumber *maxRecordingDurationPerClip;// second, NSTimeInterval
@property (copy, nonatomic) NSNumber *overlappedRecordingDuration;// second, NSTimeInterval
@property (copy, nonatomic) NSNumber *maxCountOfRecordingClips;// NSUinteger [2, 10]
@property (copy, nonatomic) NSNumber *cameraPosition;// CarDVRCameraPosition
@property (copy, nonatomic) NSNumber *videoQuality;// CarDVRVideoQuality
@property (copy, nonatomic) NSNumber *videoFrameRate;// NSUinteger [10, 30]

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
