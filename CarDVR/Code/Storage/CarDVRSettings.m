//
//  CarDVRSettings.m
//  CarDVR
//
//  Created by yxd on 13-10-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRSettings.h"
#import "CarDVRPathHelper.h"

static NSString *const kKeyMaxRecordingDuration = @"maxRecordingDuration";
static NSString *const kKeyOverlappedRecordingDuration = @"overlappedRecordingDuration";
static NSString *const kKeyMaxCountOfRecordingClips = @"maxCountOfRecordingClips";

static NSNumber *defaultMaxRecordingDuration;// 2 minutes
static NSNumber *defaultOverlappedRecordingDuration;// 1 second
static NSNumber *defaultMaxCountOfRecordingClips;// 2 clips

@interface CarDVRSettings ()

@property (weak, nonatomic) CarDVRPathHelper *pathHelper;
@property (strong, nonatomic) NSMutableDictionary *settings;

@end

@implementation CarDVRSettings

+ (void)initialize
{
    defaultMaxRecordingDuration = @5.0f;// 5 seconds, TODO: set appropriate value
    defaultOverlappedRecordingDuration = @1.0f;// 1 second
    defaultMaxCountOfRecordingClips = @2;// 2 clips
    if ( !defaultMaxRecordingDuration
        || !defaultOverlappedRecordingDuration
        || !defaultMaxCountOfRecordingClips )
    {
        NSException *exception = [NSException exceptionWithName:NSMallocException
                                                         reason:@"Fault on CarDVRSettings::initialize due to out of memory"
                                                       userInfo:nil];
        @throw exception;
    }
}

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

- (NSNumber *)maxRecordingDuration
{
    NSNumber *maxRecordingDuration = [_settings valueForKey:kKeyMaxRecordingDuration];
    if ( !maxRecordingDuration )
    {
        maxRecordingDuration = defaultMaxRecordingDuration;
        if ( maxRecordingDuration )
        {
            [_settings setValue:maxRecordingDuration forKey:kKeyMaxRecordingDuration];
        }
    }
    return maxRecordingDuration;
}

- (void)setMaxRecordingDuration:(NSNumber *)maxRecordingDuration
{
    if ( !maxRecordingDuration )
    {
        return;
    }
    if ( [maxRecordingDuration compare:defaultMaxRecordingDuration] == NSOrderedAscending )
    {
        maxRecordingDuration = defaultMaxRecordingDuration;
    }
    [_settings setValue:maxRecordingDuration forKey:kKeyMaxRecordingDuration];
}

- (NSNumber *)overlappedRecordingDuration
{
    NSNumber *overlappedRecordingDuration = [_settings valueForKey:kKeyOverlappedRecordingDuration];
    if ( !overlappedRecordingDuration )
    {
        overlappedRecordingDuration = defaultOverlappedRecordingDuration;
        if ( overlappedRecordingDuration )
        {
            [_settings setValue:overlappedRecordingDuration forKey:kKeyOverlappedRecordingDuration];
        }
    }
    return overlappedRecordingDuration;
}

- (void)setOverlappedRecordingDuration:(NSNumber *)overlappedRecordingDuration
{
    if ( !overlappedRecordingDuration )
    {
        return;
    }
    NSComparisonResult result = [overlappedRecordingDuration compare:self.maxRecordingDuration];
    if ( ( [overlappedRecordingDuration compare:@0.0f] == NSOrderedAscending )
        || ( result == NSOrderedDescending )
        || ( result == NSOrderedSame ) )
    {
        overlappedRecordingDuration = defaultOverlappedRecordingDuration;
    }
    [_settings setValue:overlappedRecordingDuration forKey:kKeyOverlappedRecordingDuration];
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
