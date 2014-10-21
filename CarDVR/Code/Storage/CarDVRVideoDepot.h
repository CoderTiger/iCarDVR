//
//  CarDVRVideoDepot.h
//  CarDVR
//
//  Created by YANG Xiaodong on 14/10/21.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CarDVRPathHelper;

@interface CarDVRVideoDepot : NSObject

@property (assign, nonatomic) BOOL needCleanTruncatedVideo;
@property (strong, readonly) NSArray *recentVideos;
@property (strong, readonly) NSArray *starredVideos;

- (id)initWithPathHelper:(CarDVRPathHelper *)aPathHelper;

@end
