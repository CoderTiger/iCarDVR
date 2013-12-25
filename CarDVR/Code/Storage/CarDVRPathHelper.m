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
- (void)constructFolderAtURL:(NSURL *)anURL withFileManager:(NSFileManager *)aFileManager;
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
- (void)constructFolderAtURL:(NSURL *)anURL withFileManager:(NSFileManager *)aFileManager
{
    if ( ![aFileManager fileExistsAtPath:anURL.path] )
    {
        NSError *error;
        [aFileManager createDirectoryAtURL:anURL
               withIntermediateDirectories:NO
                                attributes:nil
                                     error:&error];
        if ( error )
        {
            NSLog( @"[Error] Failed to create folder at \"%@\" with error: %@",
                  anURL, error.description );
        }
    }
}

- (void)constructFolders
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *documentDirectoryPath = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES ) objectAtIndex:0];
    _storageFolderURL = [NSURL fileURLWithPath:documentDirectoryPath isDirectory:YES];
    _recentsFolderURL = [NSURL fileURLWithPath:[documentDirectoryPath stringByAppendingPathComponent:kRecentsFolderName]
                                   isDirectory:YES];
    _starredFolderURL = [NSURL fileURLWithPath:[documentDirectoryPath stringByAppendingPathComponent:kStarredFolderName]
                                   isDirectory:YES];
    
    [self constructFolderAtURL:_recentsFolderURL withFileManager:fileManager];
    [self constructFolderAtURL:_starredFolderURL withFileManager:fileManager];
    
    NSString *applicationSupportDirectoryPath =
        [NSSearchPathForDirectoriesInDomains( NSApplicationSupportDirectory, NSUserDomainMask, YES ) objectAtIndex:0];
    NSURL *applicationSupportDirectoryURL = [NSURL fileURLWithPath:applicationSupportDirectoryPath isDirectory:YES];
    [self constructFolderAtURL:applicationSupportDirectoryURL withFileManager:fileManager];
    _appSupportFolderURL = [NSURL fileURLWithPath:[applicationSupportDirectoryPath stringByAppendingPathComponent:
                                                   [[NSBundle mainBundle] bundleIdentifier]]
                                      isDirectory:YES];
    [self constructFolderAtURL:_appSupportFolderURL withFileManager:fileManager];
    _settingsURL = [NSURL fileURLWithPath:[_appSupportFolderURL.path stringByAppendingPathComponent:kSettingsFileName]
                              isDirectory:NO];
}

@end
