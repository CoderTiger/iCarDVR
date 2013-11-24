//
//  CarDVRSettings.h
//  CarDVR
//
//  Created by yxd on 13-10-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CarDVRPathHelper;
@interface CarDVRSettings : NSObject

@property (copy, nonatomic) NSNumber *maxRecordingDurationPerClip;// second, NSTimeInterval
@property (copy, nonatomic) NSNumber *overlappedRecordingDuration;// second, NSTimeInterval
@property (copy, nonatomic) NSNumber *maxCountOfRecordingClips;
@property (copy, nonatomic) NSNumber *cameraPosition;// CarDVRCameraPosition
@property (copy, nonatomic) NSNumber *videoQuality;// CarDVRVideoQuality

- (id)initWithPathHelper:(CarDVRPathHelper *)aPathHelper;

- (void)addObserver:(id)anObserver selector:(SEL)aSelector forKey:(NSString *)aKey;
- (void)removeObserver:(id)anObserver forKey:(NSString *)aKey;
- (void)removeObserver:(id)anObserver;
- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;

@end
