//
//  CarDVRStorageInfo.m
//  CarDVR
//
//  Created by yxd on 13-12-23.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRStorageInfo.h"

@interface CarDVRStorageInfo ()
{
    NSFileManager *_fileManager;
}

@end

@implementation CarDVRStorageInfo

- (id)init
{
    self = [super init];
    if ( self )
    {
        _fileManager = [[NSFileManager alloc] init];
    }
    return self;
}

@end
