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

@property (assign, nonatomic) NSNumber *maxRecordingDuration;// second, NSTimeInterval
@property (assign, nonatomic) NSNumber *overlappedRecordingDuration;// second, NSTimeInterval

- (id)initWithPathHelper:(CarDVRPathHelper *)aPathHelper;

- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;

@end
