//
//  CarDVRSettings.m
//  CarDVR
//
//  Created by yxd on 13-10-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRSettings.h"
#import "CarDVRPathHelper.h"
#import "CarDVRVideoCapturerConstants.h"

static NSString *const kKeyMaxRecordingDuration = @"maxRecordingDuration";
static NSString *const kKeyOverlappedRecordingDuration = @"overlappedRecordingDuration";
static NSString *const kKeyMaxCountOfRecordingClips = @"maxCountOfRecordingClips";
static NSString *const kKeyCameraPosition = @"cameraPosition";
static NSString *const kKeyVideoQuality = @"videoQuality";

static NSNumber *defaultMaxRecordingDurationPerClip;// 30 seconds
static NSNumber *defaultOverlappedRecordingDuration;// 1 second
static NSNumber *defaultMaxCountOfRecordingClips;// 2 clips

@interface CarDVRSettings ()
{
    NSNotificationCenter *_notificationCenter;
}

@property (weak, nonatomic) CarDVRPathHelper *pathHelper;
@property (strong, nonatomic) NSMutableDictionary *settings;

#pragma mark - Private methods
- (void)setSettingValue:(id)aValue forKey:(NSString *)aKey;

@end

@implementation CarDVRSettings

+ (void)initialize
{
    defaultMaxRecordingDurationPerClip = @30.0f;// 30 seconds
    defaultOverlappedRecordingDuration = @1.0f;// 1 second
    defaultMaxCountOfRecordingClips = @2;// 2 clips
    if ( !defaultMaxRecordingDurationPerClip
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
        _notificationCenter = [[NSNotificationCenter alloc] init];
        _pathHelper = aPathHelper;
        _settings = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSNumber *)maxRecordingDurationPerClip
{
    NSNumber *maxRecordingDurationPerClip = [_settings valueForKey:kKeyMaxRecordingDuration];
    if ( !maxRecordingDurationPerClip )
    {
        maxRecordingDurationPerClip = defaultMaxRecordingDurationPerClip;
        if ( maxRecordingDurationPerClip )
        {
            [_settings setValue:maxRecordingDurationPerClip forKey:kKeyMaxRecordingDuration];
        }
    }
    return maxRecordingDurationPerClip;
}

- (void)setMaxRecordingDurationPerClip:(NSNumber *)maxRecordingDurationPerClip
{
    if ( !maxRecordingDurationPerClip )
    {
        return;
    }
    if ( [maxRecordingDurationPerClip compare:defaultMaxRecordingDurationPerClip] == NSOrderedAscending )
    {
        maxRecordingDurationPerClip = defaultMaxRecordingDurationPerClip;
    }
    [self setSettingValue:maxRecordingDurationPerClip forKey:kKeyMaxRecordingDuration];
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
    NSComparisonResult result = [overlappedRecordingDuration compare:self.maxRecordingDurationPerClip];
    if ( ( [overlappedRecordingDuration compare:@0.0f] == NSOrderedAscending )
        || ( result == NSOrderedDescending )
        || ( result == NSOrderedSame ) )
    {
        overlappedRecordingDuration = defaultOverlappedRecordingDuration;
    }
    [self setSettingValue:overlappedRecordingDuration forKey:kKeyOverlappedRecordingDuration];
}

- (NSNumber *)maxCountOfRecordingClips
{
    NSNumber *maxCountOfRecordingClips = [_settings valueForKey:kKeyMaxCountOfRecordingClips];
    if ( !maxCountOfRecordingClips )
    {
        maxCountOfRecordingClips = defaultMaxCountOfRecordingClips;
        if ( maxCountOfRecordingClips )
        {
            [_settings setValue:maxCountOfRecordingClips forKey:kKeyMaxCountOfRecordingClips];
        }
    }
    return maxCountOfRecordingClips;
}

- (void)setMaxCountOfRecordingClips:(NSNumber *)maxCountOfRecordingClips
{
    if ( !maxCountOfRecordingClips )
    {
        return;
    }
    if ( [maxCountOfRecordingClips compare:defaultMaxCountOfRecordingClips] == NSOrderedAscending )
    {
        maxCountOfRecordingClips = defaultMaxCountOfRecordingClips;
    }
    [self setSettingValue:maxCountOfRecordingClips forKey:kKeyMaxCountOfRecordingClips];
}

- (NSNumber *)cameraPosition
{
    NSNumber *cameraPosition = [_settings valueForKey:kKeyCameraPosition];
    if ( !cameraPosition )
    {
        cameraPosition = [NSNumber numberWithInteger:kCarDVRCameraPositionBack];
        if ( cameraPosition )
        {
            [_settings setValue:cameraPosition forKey:kKeyCameraPosition];
        }
    }
    return cameraPosition;
}

- (NSNumber *)videoQuality
{
    NSNumber *videoQuality = [_settings valueForKey:kKeyVideoQuality];
    if ( !videoQuality )
    {
        videoQuality = [NSNumber numberWithInteger:kCarDVRVideoQualityHigh];
        if ( videoQuality )
        {
            [_settings setValue:videoQuality forKey:kKeyVideoQuality];
        }
    }
    return videoQuality;
}

- (void)addObserver:(id)anObserver selector:(SEL)aSelector forKey:(NSString *)aKey
{
    NSAssert( aKey, @"aKey should NOT be nil" );
    if ( !aKey )
        return;
    [_notificationCenter addObserver:anObserver selector:aSelector name:aKey object:self];
}

- (void)removeObserver:(id)anObserver forKey:(NSString *)aKey
{
    NSAssert( aKey, @"aKey should NOT be nil" );
    if ( !aKey )
        return;
    [_notificationCenter removeObserver:anObserver name:aKey object:self];
}

- (void)removeObserver:(id)anObserver
{
    [_notificationCenter removeObserver:anObserver];
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    [self setSettingValue:value forKey:key];
}

- (id)valueForKey:(NSString *)key
{
    return [_settings valueForKey:key];
}

#pragma mark - Private methods
- (void)setSettingValue:(id)aValue forKey:(NSString *)aKey
{
    NSAssert( aKey, @"aKey should NOT be nil" );
    if ( !aKey )
        return;
    [_settings setValue:aValue forKey:aKey];
    [_notificationCenter postNotificationName:aKey object:self];
}

@end
