//
//  CarDVRVideoItem.m
//  CarDVR
//
//  Created by yxd on 13-11-3.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRVideoItem.h"
#import "CarDVRPathHelper.h"

@implementation CarDVRVideoItem

- (id)initWithPath:(NSString *)aPath
{
    self = [super init];
    if ( self )
    {
        _filePath = aPath;
        _fileName = [aPath lastPathComponent];
        _createdDate = [CarDVRPathHelper dateFromString:[_fileName stringByDeletingPathExtension]];
        // TODO: validate the file and return nil if it's invalid.
    }
    return self;
}

@end
