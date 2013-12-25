//
//  CarDVRStorageInfo.m
//  CarDVR
//
//  Created by yxd on 13-12-23.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRStorageInfo.h"
#import "CarDVRPathHelper.h"

@interface CarDVRStorageInfo ()
{
    NSFileManager *_fileManager;
}

@property (weak, nonatomic) CarDVRPathHelper *pathHelper;

@end

@implementation CarDVRStorageInfo

- (id)initWithPathHelper:(CarDVRPathHelper *)aPathHelper
{
    self = [super init];
    if ( self )
    {
        _fileManager = [[NSFileManager alloc] init];
        _pathHelper = aPathHelper;
    }
    return self;
}

- (void)getStorageUsageUsingBlock:(void (^)(NSNumber *totalSpace, NSNumber *freeSpace))aBlock
{
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0 ), ^{
        if ( !aBlock )
            return;
        NSError *error;
        NSDictionary *attributes = [_fileManager attributesOfFileSystemForPath:self.pathHelper.storageFolderURL.path error:&error];
        if ( !attributes )
        {
            NSLog( @"[Error]Failed to get storage usage due to: \"%@\"", error.description );
        }
        else
        {
            NSNumber *fileSystemSize = [attributes valueForKey:NSFileSystemSize];
            NSNumber *fileSystemFreeSize = [attributes valueForKey:NSFileSystemFreeSize];
            aBlock( fileSystemSize, fileSystemFreeSize );
        }
    });
}

@end
