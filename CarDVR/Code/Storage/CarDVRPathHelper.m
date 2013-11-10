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
    if ( ![aFileManager fileExistsAtPath:_recentsFolderPath] )
    {
        NSError *error = nil;
        [aFileManager createDirectoryAtPath:_recentsFolderPath
                withIntermediateDirectories:NO
                                 attributes:nil
                                      error:&error];
        if ( error )
        {
            NSLog( @"[Error] failed to create %@ folder with error: %@", _recentsFolderPath, error );
        }
    }
}

- (void)constructFolders
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    _storageFolderPath = [documentDirectories objectAtIndex:0];
    _recentsFolderPath = [_storageFolderPath stringByAppendingPathComponent:kRecentsFolderName];
    _starredFolderPath = [_storageFolderPath stringByAppendingPathComponent:kStarredFolderName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [self constructFolderAtPath:_recentsFolderPath withFileManager:fileManager];
    [self constructFolderAtPath:_starredFolderPath withFileManager:fileManager];
}

@end
