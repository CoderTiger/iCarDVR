//
//  CarDVRStorageInfo.h
//  CarDVR
//
//  Created by yxd on 13-12-23.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CarDVRPathHelper;

@interface CarDVRStorageInfo : NSObject

- (id)initWithPathHelper:(CarDVRPathHelper *)aPathHelper;
- (void)getStorageUsageUsingBlock:(void (^)(NSNumber *totalSpace, NSNumber *freeSpace))aBlock;

@end
