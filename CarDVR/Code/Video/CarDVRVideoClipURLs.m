//
//  CarDVRVideoClipURLs.m
//  CarDVR
//
//  Created by yxd on 14-1-15.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import "CarDVRVideoClipURLs.h"

@interface CarDVRVideoClipURLs ()

@property (strong, nonatomic) NSURL *folderURL;
@property (strong, nonatomic) NSString *clipName;

#pragma mark - Private methods
- (NSURL *)fileURLWithExtension:(NSString *)anExtension;

@end

@implementation CarDVRVideoClipURLs

+ (BOOL)isValidVideoPathExtension:(NSString *)aExtension
{
    if ( aExtension )
    {
        if ( [aExtension compare:@"mov" options:NSCaseInsensitiveSearch] == NSOrderedSame )
        {
            return YES;
        }
    }
    return NO;
}

- (id)initWithFolderURL:(NSURL *)aFolderURL clipName:(NSString *)aClipName
{
    if ( !aFolderURL || !aClipName )
    {
        return nil;
    }
    self = [super init];
    if ( self )
    {
        _folderURL = aFolderURL;
        _clipName = aClipName;
    }
    return self;
}

- (NSURL *)videoFileURL
{
    return [self fileURLWithExtension:@"mov"];
}

- (NSURL *)srtFileURL
{
    return [self fileURLWithExtension:@"srt"];
}

- (NSURL *)gpxFileURL
{
    return [self fileURLWithExtension:@"gpx"];
}

#pragma mark - Private methods
- (NSURL *)fileURLWithExtension:(NSString *)anExtension
{
    NSAssert( anExtension, @"anExtension should NOT be nil." );
    if ( !anExtension )
    {
        return nil;
    }
    NSString *clipPath = [_folderURL.path stringByAppendingPathComponent:_clipName];
    NSURL *fileURL = [NSURL fileURLWithPath:[clipPath stringByAppendingPathExtension:anExtension]];
    return fileURL;
}

@end
