//
//  CarDVRLocation.h
//  CarDVR
//
//  Created by yxd on 14-3-10.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CarDVRLocation : NSObject

@property (assign, nonatomic) CGFloat latitude;
@property (assign, nonatomic) CGFloat longitude;
@property (assign, nonatomic) CGFloat altitude;
@property (assign, nonatomic) CGFloat speed;
@property (strong, nonatomic) NSDate *timestamp;
@property (strong, nonatomic) NSString *name;

+ (CarDVRLocation *)locationWithLatitude:(CGFloat)latitude
                               longitude:(CGFloat)longitude
                                altitude:(CGFloat)altitude
                               timestamp:(NSDate *)timestamp;

@end
