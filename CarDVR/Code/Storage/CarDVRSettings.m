//
//  CarDVRSettings.m
//  CarDVR
//
//  Created by yxd on 13-10-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRSettings.h"

static const NSTimeInterval kDefaultMaxRecordingDuration = 180.00;// 3 minutes
static NSString *const kKeyMaxRecordingDuration = @"maxRecordingDuration";

@interface CarDVRSettings ()

@property (strong, nonatomic) NSMutableDictionary *settings;

@end

@implementation CarDVRSettings

- (NSTimeInterval)maxRecordingDuration
{
    NSNumber *maxRecordingDuration = [_settings valueForKey:kKeyMaxRecordingDuration];
    if ( !maxRecordingDuration )
    {
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
    [_settings setValue:[NSNumber numberWithDouble:maxRecordingDuration]
                 forKey:kKeyMaxRecordingDuration];
}

- (id)init
{
    self = [super init];
    if ( self )
    {
        _settings = [NSMutableDictionary dictionary];
    }
    return self;
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
