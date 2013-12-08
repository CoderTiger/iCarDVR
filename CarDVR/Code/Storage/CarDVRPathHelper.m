//
//  CarDVRPathHelpler.m
//  CarDVR
//
//  Created by yxd on 13-10-15.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRPathHelper.h"

static CarDVRPathHelper *singleton;
static NSDateFormatter *dateFormatter;

static NSString *const kRecentsFolderName = @"Recents";
static NSString *const kStarredFolderName = @"Starred";
static NSString *const kSettingsFileName = @"Settings.plist";

@interface CarDVRPathHelper ()
{
    NSDateFormatter *_dateFormatter;
}

#pragma mark - private methods
- (void)constructFolderAtPath:(NSString *)aPath withFileManager:(NSFileManager *)aFileManager;
- (void)constructFolders;

@end

@implementation CarDVRPathHelper

+ (void)initialize
{
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
}

- (id)init
{
    self = [super init];
    if ( self )
    {
        [self constructFolders];
    }
    return self;
}

+ (NSString *)stringFromDate:(NSDate *)aDate
{
    return [dateFormatter stringFromDate:aDate];
}

+ (NSDate *)dateFromString:(NSString *)aString
{
    return [dateFormatter dateFromString:aString];
}

#pragma mark - private methods
- (void)constructFolderAtPath:(NSString *)aPath withFileManager:(NSFileManager *)aFileManager
{
    if ( ![aFileManager fileExistsAtPath:aPath] )
    {
        NSError *error = nil;
        [aFileManager createDirectoryAtPath:aPath
                withIntermediateDirectories:NO
                                 attributes:nil
                                      error:&error];
        if ( error )
        {
            NSLog( @"[Error] Failed to create %@ folder with error: domain(%@), code(%d), \"%@\"",
                  _recentsFolderPath, error.domain, error.code, error.description );
        }
    }
}

- (void)constructFolders
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *documentDirectory = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES ) objectAtIndex:0];
    _storageFolderPath = documentDirectory;
    _recentsFolderPath = [_storageFolderPath stringByAppendingPathComponent:kRecentsFolderName];
    _starredFolderPath = [_storageFolderPath stringByAppendingPathComponent:kStarredFolderName];
    [self constructFolderAtPath:_recentsFolderPath withFileManager:fileManager];
    [self constructFolderAtPath:_starredFolderPath withFileManager:fileManager];
    
    NSString *applicationSupportDirectory =
        [NSSearchPathForDirectoriesInDomains( NSApplicationSupportDirectory, NSUserDomainMask, YES ) objectAtIndex:0];
    [self constructFolderAtPath:applicationSupportDirectory withFileManager:fileManager];
    _appSupportFolderPath = [applicationSupportDirectory stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
    [self constructFolderAtPath:_appSupportFolderPath withFileManager:fileManager];
    _settingsPath = [_appSupportFolderPath stringByAppendingPathComponent:kSettingsFileName];
}

@end
