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

@interface CarDVRPathHelper ()
{
    NSDateFormatter *_dateFormatter;
}

#pragma mark - private methods
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
- (void)constructFolders
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
    _storageFolderPath = [documentDirectories objectAtIndex:0];
    _recordingFolderPath = [_storageFolderPath copy];
    _starredFolderPath = [_storageFolderPath copy];
}

@end
