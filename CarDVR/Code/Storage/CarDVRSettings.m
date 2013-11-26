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

static NSString *const kCarDVRSettingsCommitEditingNotification = @"kCarDVRSettingsCommitEditingNotification";

NSString *const kCarDVRSettingsKeyMaxRecordingDuration = @"maxRecordingDuration";
NSString *const kCarDVRSettingsKeyOverlappedRecordingDuration = @"overlappedRecordingDuration";
NSString *const kCarDVRSettingsKeyMaxCountOfRecordingClips = @"maxCountOfRecordingClips";
NSString *const kCarDVRSettingsKeyCameraPosition = @"cameraPosition";
NSString *const kCarDVRSettingsKeyVideoQuality = @"videoQuality";

static NSNumber *defaultMaxRecordingDurationPerClip;// 30 seconds
static NSNumber *defaultOverlappedRecordingDuration;// 1 second
static NSNumber *defaultMaxCountOfRecordingClips;// 2 clips

@interface CarDVRSettings ()
{
    NSNotificationCenter *_notificationCenter;
}

@property (weak, nonatomic) CarDVRPathHelper *pathHelper;
@property (assign, nonatomic, getter = isEditing) BOOL editing;
@property (strong, nonatomic) NSMutableDictionary *settings;
@property (strong, nonatomic) NSMutableDictionary *editedSettings;
@property (strong, nonatomic) NSMutableSet *removedSettings;

#pragma mark - Private methods
- (void)setSettingValue:(id)aValue forKey:(NSString *)aKey;

@end

@implementation CarDVRSettings

+ (void)initialize
{
#ifdef DEBUG
    defaultMaxRecordingDurationPerClip = @5.0f;// 5 seconds
#else// !DEBUG
    defaultMaxRecordingDurationPerClip = @30.0f;// 30 seconds
#endif// DEBUG
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
    NSNumber *maxRecordingDurationPerClip = [_settings valueForKey:kCarDVRSettingsKeyMaxRecordingDuration];
    if ( !maxRecordingDurationPerClip )
    {
        maxRecordingDurationPerClip = defaultMaxRecordingDurationPerClip;
        if ( maxRecordingDurationPerClip )
        {
            [_settings setValue:maxRecordingDurationPerClip forKey:kCarDVRSettingsKeyMaxRecordingDuration];
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
    [self setSettingValue:maxRecordingDurationPerClip forKey:kCarDVRSettingsKeyMaxRecordingDuration];
}

- (NSNumber *)overlappedRecordingDuration
{
    NSNumber *overlappedRecordingDuration = [_settings valueForKey:kCarDVRSettingsKeyOverlappedRecordingDuration];
    if ( !overlappedRecordingDuration )
    {
        overlappedRecordingDuration = defaultOverlappedRecordingDuration;
        if ( overlappedRecordingDuration )
        {
            [_settings setValue:overlappedRecordingDuration forKey:kCarDVRSettingsKeyOverlappedRecordingDuration];
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
    [self setSettingValue:overlappedRecordingDuration forKey:kCarDVRSettingsKeyOverlappedRecordingDuration];
}

- (NSNumber *)maxCountOfRecordingClips
{
    NSNumber *maxCountOfRecordingClips = [_settings valueForKey:kCarDVRSettingsKeyMaxCountOfRecordingClips];
    if ( !maxCountOfRecordingClips )
    {
        maxCountOfRecordingClips = defaultMaxCountOfRecordingClips;
        if ( maxCountOfRecordingClips )
        {
            [_settings setValue:maxCountOfRecordingClips forKey:kCarDVRSettingsKeyMaxCountOfRecordingClips];
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
    [self setSettingValue:maxCountOfRecordingClips forKey:kCarDVRSettingsKeyMaxCountOfRecordingClips];
}

- (NSNumber *)cameraPosition
{
    NSNumber *cameraPosition = [_settings valueForKey:kCarDVRSettingsKeyCameraPosition];
    if ( !cameraPosition )
    {
        cameraPosition = [NSNumber numberWithInteger:kCarDVRCameraPositionBack];
        if ( cameraPosition )
        {
            [_settings setValue:cameraPosition forKey:kCarDVRSettingsKeyCameraPosition];
        }
    }
    return cameraPosition;
}

- (NSNumber *)videoQuality
{
    NSNumber *videoQuality = [_settings valueForKey:kCarDVRSettingsKeyVideoQuality];
    if ( !videoQuality )
    {
        videoQuality = [NSNumber numberWithInteger:kCarDVRVideoQualityHigh];
        if ( videoQuality )
        {
            [_settings setValue:videoQuality forKey:kCarDVRSettingsKeyVideoQuality];
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

- (void)beginEditing
{
    self.editing = YES;
    self.editedSettings = [NSMutableDictionary dictionary];
    self.removedSettings = [NSMutableSet set];
}

- (void)commitEditing
{
    if ( self.editedSettings.count > 0 || self.removedSettings.count > 0 )
    {
        [_settings addEntriesFromDictionary:self.editedSettings];
        [_settings removeObjectsForKeys:self.removedSettings.allObjects];
        NSMutableSet *changedKeys = [NSMutableSet setWithCapacity:( self.removedSettings.count + self.editedSettings.count )];
        [changedKeys addObjectsFromArray:self.editedSettings.allKeys];
        [changedKeys addObjectsFromArray:self.removedSettings.allObjects];
        NSDictionary *userInfo = @{kCarDVRSettingsCommitEditingChangedKeys: changedKeys};
        [_notificationCenter postNotificationName:kCarDVRSettingsCommitEditingNotification
                                           object:self
                                         userInfo:userInfo];
    }
    self.editing = NO;
    self.removedSettings = nil;
    self.editedSettings = nil;
}

- (void)addCommitEditingObserver:(id)anObserver selector:(SEL)aSelector
{
    [_notificationCenter addObserver:anObserver selector:aSelector name:kCarDVRSettingsCommitEditingNotification object:self];
}

- (void)cancelEditing
{
    self.editing = NO;
    self.removedSettings = nil;
    self.editedSettings = nil;
}

#pragma mark - Private methods
- (void)setSettingValue:(id)aValue forKey:(NSString *)aKey
{
    NSAssert( aKey, @"aKey should NOT be nil" );
    if ( !aKey )
        return;
    if ( self.isEditing )
    {
        if ( aValue )
        {
            [self.editedSettings setValue:aValue forKey:aKey];
        }
        else
        {
            [self.removedSettings addObject:aKey];
        }
    }
    else
    {
        [self.settings setValue:aValue forKey:aKey];
        [_notificationCenter postNotificationName:aKey object:self];
    }
}

@end
