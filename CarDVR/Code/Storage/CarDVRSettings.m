//
//  CarDVRSettings.m
//  CarDVR
//
//  Created by yxd on 13-10-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRSettings.h"
#import "CarDVRPathHelper.h"

static const NSTimeInterval kDefaultMaxRecordingDuration = 180.0f;// 3 minutes
static NSString *const kKeyMaxRecordingDuration = @"maxRecordingDuration";
static const NSTimeInterval kDefaultOverlappedRecordingDuration = 1.0f;// 1 second
static NSString *const kKeyOverlappedRecordingDuration = @"overlappedRecordingDuration";

@interface CarDVRSettings ()

@property (weak, nonatomic) CarDVRPathHelper *pathHelper;
@property (strong, nonatomic) NSMutableDictionary *settings;

@end

@implementation CarDVRSettings

- (id)init
{
    NSException *exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@""
                                                   userInfo:nil];
    @throw exception;
}

- (id)initWithPathHelper:(CarDVRPathHelper *)aPathHelper
{
    self = [super init];
    if ( self )
    {
        _pathHelper = aPathHelper;
        _settings = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSTimeInterval)maxRecordingDuration
{
    NSNumber *maxRecordingDuration = [_settings valueForKey:kKeyMaxRecordingDuration];
    if ( !maxRecordingDuration )
    {
        maxRecordingDuration = [NSNumber numberWithDouble:kDefaultMaxRecordingDuration];
        if ( maxRecordingDuration )
        {
            [_settings setValue:maxRecordingDuration forKey:kKeyMaxRecordingDuration];
        }
        return kDefaultMaxRecordingDuration;
    }
    return maxRecordingDuration.doubleValue;
}

- (void)setMaxRecordingDuration:(NSTimeInterval)maxRecordingDuration
{
    if ( maxRecordingDuration < kDefaultMaxRecordingDuration )
    {
        maxRecordingDuration = kDefaultMaxRecordingDuration;
    }
    NSNumber *value = [NSNumber numberWithDouble:maxRecordingDuration];
    if ( value )
    {
        [_settings setValue:value forKey:kKeyMaxRecordingDuration];
    }
}

- (NSTimeInterval)overlappedRecordingDuration
{
    NSNumber *overlappedRecordingDuration = [_settings valueForKey:kKeyOverlappedRecordingDuration];
    if ( !overlappedRecordingDuration )
    {
        overlappedRecordingDuration = [NSNumber numberWithDouble:kDefaultOverlappedRecordingDuration];
        if ( overlappedRecordingDuration )
        {
            [_settings setValue:overlappedRecordingDuration forKey:kKeyOverlappedRecordingDuration];
        }
        return kDefaultOverlappedRecordingDuration;
    }
    return overlappedRecordingDuration.doubleValue;
}

- (void)setOverlappedRecordingDuration:(NSTimeInterval)overlappedRecordingDuration
{
    if ( overlappedRecordingDuration < 0 )
    {
        overlappedRecordingDuration = 0.0f;
    }
    NSNumber *value = [NSNumber numberWithDouble:overlappedRecordingDuration];
    if ( value )
    {
        [_settings setValue:value forKey:kKeyOverlappedRecordingDuration];
    }
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    [_settings setValue:value forKey:key];
}

- (id)valueForKey:(NSString *)key
{
    return [_settings valueForKey:key];
}

@end
