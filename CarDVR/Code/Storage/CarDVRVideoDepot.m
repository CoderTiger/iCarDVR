//
//  CarDVRVideoDepot.m
//  CarDVR
//
//  Created by YANG Xiaodong on 14/10/21.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import "CarDVRVideoDepot.h"
#import "CarDVRPathHelper.h"
#import "CarDVRVideoItem.h"

typedef enum
{
    kCarDVRVideoCategoryUnkown,
    kCarDVRVideoCategoryRecents,
    kCarDVRVideoCategoryStarred
} CarDVRVideoCategory;

@interface CarDVRVideoDepot ()

@property (weak, nonatomic) CarDVRPathHelper *pathHelper;

- (NSArray *)videosByCategory:(CarDVRVideoCategory)category;

@end

@implementation CarDVRVideoDepot

- (NSArray *)recentVideos
{
    return [self videosByCategory:kCarDVRVideoCategoryRecents];
}

- (NSArray *)starredVideos
{
    return [self videosByCategory:kCarDVRVideoCategoryStarred];
}

- (id)initWithPathHelper:(CarDVRPathHelper *)aPathHelper
{
    self = [super init];
    if ( self )
    {
        _needCleanTruncatedVideo = NO;
        _pathHelper = aPathHelper;
    }
    return self;
}

- (NSArray *)videosByCategory:(CarDVRVideoCategory)category
{
    NSMutableArray *videos = [NSMutableArray array];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSURL *videoFolderURL;
    switch ( category )
    {
        case kCarDVRVideoCategoryRecents:
            videoFolderURL = self.pathHelper.recentsFolderURL;
            break;
        case kCarDVRVideoCategoryStarred:
            videoFolderURL = self.pathHelper.starredFolderURL;
            break;
        default:
            break;
    }
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtURL:videoFolderURL
                                       includingPropertiesForKeys:@[NSURLCreationDateKey]
                                                          options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                     errorHandler:^BOOL(NSURL *url, NSError *error) {
                                                         NSLog( @"[Error] %@, %@", url, error.description );
                                                         return YES;
                                                     }];//[fileManager enumeratorAtPath:videoFolderURL.path];
    
    NSMutableDictionary *fileURLWithDateDict = [NSMutableDictionary dictionary];
    for ( NSURL *fileURL in dirEnum )
    {
        NSDate *creationgDate;
        if ( [fileURL getResourceValue:&creationgDate forKey:NSURLCreationDateKey error:nil] )
        {
            [fileURLWithDateDict setObject:creationgDate forKey:fileURL];
        }
    }
    
    NSDate *prevFileEndDate;
    NSMutableArray *videoGroup;
    for ( NSURL *fileURL in [fileURLWithDateDict keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }])
    {
        if ( ![CarDVRVideoClipURLs isValidVideoPathExtension:fileURL.pathExtension] )
        {
            continue;
        }
        NSString *videoClipName = [fileURL.lastPathComponent stringByDeletingPathExtension];
        CarDVRVideoClipURLs *videoClipURLs = [[CarDVRVideoClipURLs alloc] initWithFolderURL:videoFolderURL
                                                                                   clipName:videoClipName];
        CarDVRVideoItem *videoItem = [[CarDVRVideoItem alloc] initWithVideoClipURLs:videoClipURLs];
        if ( !videoItem )
        {
            if ( self.needCleanTruncatedVideo )
            {
                // remove truncated or invalid video files
                NSFileManager *defaultFileManager = [NSFileManager defaultManager];
                [defaultFileManager removeItemAtURL:videoClipURLs.videoFileURL error:nil];
                [defaultFileManager removeItemAtURL:videoClipURLs.srtFileURL error:nil];
                [defaultFileManager removeItemAtURL:videoClipURLs.gpxFileURL error:nil];
            }
            continue;
        }
        
        if ( prevFileEndDate )
        {
            NSComparisonResult comparisonResult = [videoItem.creationDate compare:prevFileEndDate];
            if ( comparisonResult == NSOrderedDescending )// later than prevFileEndDate
            {
                videoGroup = [NSMutableArray array];
                [videos insertObject:videoGroup atIndex:0];
            }
        }
        else
        {
            videoGroup = [NSMutableArray array];
            [videos insertObject:videoGroup atIndex:0];
        }
        [videoGroup addObject:videoItem];
        prevFileEndDate = [NSDate dateWithTimeInterval:videoItem.duration sinceDate:videoItem.creationDate];
    }
    return ( videos.count > 0 ? videos : nil );
}

@end
