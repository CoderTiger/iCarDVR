//
//  CarDVRSettings.m
//  CarDVR
//
//  Created by yxd on 13-10-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRSettings.h"
#import "CarDVRVideoCapturerConstants.h"
#import "CarDVRPathHelper.h"
#import "CarDVRStorageInfo.h"

static NSString *const kCarDVRSettingsCommitEditingNotification = @"kCarDVRSettingsCommitEditingNotification";
NSString *const kCarDVRSettingsCommitEditingChangedKeys=@"kCarDVRSettingsCommitEditingChangedKeys";

NSString *const kCarDVRSettingsKeyMaxRecordingDuration = @"maxRecordingDuration";
NSString *const kCarDVRSettingsKeyOverlappedRecordingDuration = @"overlappedRecordingDuration";
NSString *const kCarDVRSettingsKeyMaxCountOfRecordingClips = @"maxCountOfRecordingClips";
NSString *const kCarDVRSettingsKeyCameraPosition = @"cameraPosition";
NSString *const kCarDVRSettingsKeyVideoResolution = @"videoResolution";
NSString *const kCarDVRSettingsKeyVideoFrameRate = @"videoFrameRate";
NSString *const kCarDVRSettingsKeyStarred = @"isStarred";
NSString *const kCarDVRSettingsKeyTracksMapType = @"tracksMapType";

static NSNumber *defaultMaxRecordingDurationPerClip;// 30 seconds
static NSNumber *defaultOverlappedRecordingDuration;// 1 second
static NSNumber *defaultMaxCountOfRecordingClips;// 2 clips
static NSNumber *maxVideoFrameRate ;// 30 fps
static NSNumber *minVideoFrameRate;// 5 fps
static NSNumber *defaultStarredValue;// NO
static NSNumber *defaultTracksMapType; // kCarDVRMapTypeStandard

@interface CarDVRSettings ()
{
    NSNotificationCenter *_notificationCenter;
}

@property (weak, nonatomic) CarDVRPathHelper *pathHelper;
@property (assign, nonatomic, getter = isEditing) BOOL editing;
@property (strong, nonatomic) NSMutableDictionary *settings;
@property (strong, nonatomic) NSMutableDictionary *editedSettings;
@property (strong, nonatomic) NSMutableSet *removedSettings;
@property (strong, nonatomic) CarDVRStorageInfo *storageInfo;

#pragma mark - Private methods
- (void)setSettingValue:(id)aValue forKey:(NSString *)aKey;
- (void)setSettingValue:(id)aValue forKey:(NSString *)aKey mutely:(BOOL)aMutely;
- (id)settingValueForKey:(NSString *)aKey;

- (void)reloadSettings;
- (void)saveSettings;

@end

@implementation CarDVRSettings

+ (void)initialize
{
#if USE_DEBUG_SETTINGS
    defaultMaxRecordingDurationPerClip = @5.0f;// 5 seconds
#else// !USE_DEBUG_SETTINGS
    defaultMaxRecordingDurationPerClip = @60.0f;// 60 seconds
#endif// USE_DEBUG_SETTINGS
    defaultOverlappedRecordingDuration = @1.0f;// 1 second
    defaultMaxCountOfRecordingClips = @3;// 2 clips
    maxVideoFrameRate = @30;// 30 fps
    minVideoFrameRate = @5;// 10 fps
    defaultStarredValue = @NO;
    defaultTracksMapType = [NSNumber numberWithInteger:kCarDVRMapTypeStandard];
    if ( !defaultMaxRecordingDurationPerClip
        || !defaultOverlappedRecordingDuration
        || !defaultMaxCountOfRecordingClips
        || !maxVideoFrameRate
        || !minVideoFrameRate
        || !defaultStarredValue
        || !defaultTracksMapType )
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
        _editing = NO;
        _storageInfo = [[CarDVRStorageInfo alloc] initWithPathHelper:aPathHelper];
        [self reloadSettings];
    }
    return self;
}

- (NSNumber *)maxRecordingDurationPerClip
{
    NSNumber *maxRecordingDurationPerClip = [self settingValueForKey:kCarDVRSettingsKeyMaxRecordingDuration];
    if ( !maxRecordingDurationPerClip )
    {
        maxRecordingDurationPerClip = defaultMaxRecordingDurationPerClip;
        if ( maxRecordingDurationPerClip )
        {
            [self setSettingValue:maxRecordingDurationPerClip forKey:kCarDVRSettingsKeyMaxRecordingDuration mutely:YES];
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
    NSNumber *overlappedRecordingDuration = [self settingValueForKey:kCarDVRSettingsKeyOverlappedRecordingDuration];
    if ( !overlappedRecordingDuration )
    {
        overlappedRecordingDuration = defaultOverlappedRecordingDuration;
        if ( overlappedRecordingDuration )
        {
            [self setSettingValue:overlappedRecordingDuration forKey:kCarDVRSettingsKeyOverlappedRecordingDuration mutely:YES];
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
    NSNumber *maxCountOfRecordingClips = [self settingValueForKey:kCarDVRSettingsKeyMaxCountOfRecordingClips];
    if ( !maxCountOfRecordingClips )
    {
        maxCountOfRecordingClips = defaultMaxCountOfRecordingClips;
        if ( maxCountOfRecordingClips )
        {
            [self setSettingValue:maxCountOfRecordingClips forKey:kCarDVRSettingsKeyMaxCountOfRecordingClips mutely:YES];
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
    NSNumber *cameraPosition = [self settingValueForKey:kCarDVRSettingsKeyCameraPosition];
    if ( !cameraPosition )
    {
        cameraPosition = [NSNumber numberWithInteger:kCarDVRCameraPositionBack];
        if ( cameraPosition )
        {
            [self setSettingValue:cameraPosition forKey:kCarDVRSettingsKeyCameraPosition mutely:YES];
        }
    }
    return cameraPosition;
}

- (void)setCameraPosition:(NSNumber *)cameraPosition
{
    if ( !cameraPosition )
    {
        return;
    }
    NSInteger position = cameraPosition.integerValue;
    switch ( position )
    {
        case kCarDVRCameraPositionBack:
        case kCarDVRCameraPositionFront:
            [self setSettingValue:cameraPosition forKey:kCarDVRSettingsKeyCameraPosition];
            break;
        default:
            break;
    }
}

- (NSNumber *)videoResolution
{
    NSNumber *videoResolution = [self settingValueForKey:kCarDVRSettingsKeyVideoResolution];
    if ( !videoResolution )
    {
        videoResolution = [NSNumber numberWithInteger:kCarDVRVideoResolutionHigh];
        if ( videoResolution )
        {
            [self setSettingValue:videoResolution forKey:kCarDVRSettingsKeyVideoResolution mutely:YES];
        }
    }
    return videoResolution;
}

- (void)setVideoResolution:(NSNumber *)videoResolution
{
    NSInteger videoResolutionValue = videoResolution.integerValue;
    switch ( videoResolutionValue )
    {
        case kCarDVRVideoResolutionHigh:
        case kCarDVRVideoResolutionMiddle:
        case kCarDVRVideoResolutionLow:
        case kCarDVRVideoResolution352x288:
        case kCarDVRVideoResolution640x480:
        case kCarDVRVideoResolution1280x720:
        case kCarDVRVideoResolution1920x1080:
        case kCarDVRVideoResolutioniFrame960x540:
        case kCarDVRVideoResolutioniFrame1280x720:
            [self setSettingValue:videoResolution forKey:kCarDVRSettingsKeyVideoResolution];
            break;
        default:
            break;
    }
}

- (NSNumber *)videoFrameRate
{
    NSNumber *videoFrameRate = [self settingValueForKey:kCarDVRSettingsKeyVideoFrameRate];
    if ( !videoFrameRate )
    {
        videoFrameRate = maxVideoFrameRate;
        if ( videoFrameRate )
        {
            [self setSettingValue:videoFrameRate forKey:kCarDVRSettingsKeyVideoFrameRate mutely:YES];
        }
    }
    return videoFrameRate;
}

- (void)setVideoFrameRate:(NSNumber *)videoFrameRate
{
    if ( !videoFrameRate )
    {
        return;
    }
    if ( [videoFrameRate compare:minVideoFrameRate] == NSOrderedAscending )
    {
        [self setSettingValue:minVideoFrameRate forKey:kCarDVRSettingsKeyVideoFrameRate];
    }
    else if ( [videoFrameRate compare:maxVideoFrameRate] == NSOrderedDescending )
    {
        [self setSettingValue:maxVideoFrameRate forKey:kCarDVRSettingsKeyVideoFrameRate];
    }
    else
    {
        [self setSettingValue:videoFrameRate forKey:kCarDVRSettingsKeyVideoFrameRate];
    }
}

- (NSNumber *)isStarred
{
    NSNumber *starred = [self settingValueForKey:kCarDVRSettingsKeyStarred];
    if ( !starred )
    {
        starred = defaultStarredValue;
        if ( starred )
        {
            [self setSettingValue:starred forKey:kCarDVRSettingsKeyStarred mutely:YES];
        }
    }
    return starred;
}

- (void)setStarred:(NSNumber *)starred
{
    if ( !starred )
    {
        return;
    }
    [self setSettingValue:starred forKey:kCarDVRSettingsKeyStarred];
}

- (NSNumber *)tracksMapType
{
    NSNumber *tracksMapType = [self settingValueForKey:kCarDVRSettingsKeyTracksMapType];
    if ( !tracksMapType )
    {
        tracksMapType = defaultTracksMapType;
        if ( tracksMapType )
        {
            [self setSettingValue:tracksMapType forKey:kCarDVRSettingsKeyTracksMapType mutely:YES];
        }
    }
    return tracksMapType;
}

- (void)setTracksMapType:(NSNumber *)tracksMapType
{
    if ( !tracksMapType )
    {
        return;
    }
    NSInteger tracksMapTypeValue = tracksMapType.integerValue;
    switch ( tracksMapTypeValue )
    {
        case kCarDVRMapTypeStandard:
        case kCarDVRMapTypeSatellite:
        case kCarDVRMapTypeHybrid:
            [self setSettingValue:tracksMapType forKey:kCarDVRSettingsKeyTracksMapType];
            break;
        default:
            break;
    }
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
    return [self settingValueForKey:key];
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
        
        [self saveSettings];
        
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
    [self setSettingValue:aValue forKey:aKey mutely:NO];
}

- (void)setSettingValue:(id)aValue forKey:(NSString *)aKey mutely:(BOOL)aMutely
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
        if ( !aMutely )
        {
            [_notificationCenter postNotificationName:aKey object:self];
        }
        [self saveSettings];
    }
}

- (id)settingValueForKey:(NSString *)aKey
{
    NSAssert( aKey, @"aKey should NOT be nil" );
    if ( !aKey )
        return nil;
    id value;
    if ( self.isEditing )
    {
        if ( ![self.removedSettings containsObject:aKey] )
        {
            value = [self.editedSettings valueForKey:aKey];
            if ( !value )
            {
                value = [self.settings valueForKey:aKey];
            }
        }
    }
    else
    {
        value = [self.settings valueForKey:aKey];
    }
    return value;
}

- (void)reloadSettings
{
    _settings = [[NSMutableDictionary alloc] initWithContentsOfURL:self.pathHelper.settingsURL];
    if ( !_settings )
    {
        _settings = [NSMutableDictionary dictionary];
    }
}

- (void)saveSettings
{
    [self.settings writeToURL:self.pathHelper.settingsURL atomically:YES];
}

@end
