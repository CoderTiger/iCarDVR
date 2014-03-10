//
//  CarDVRLocation.m
//  CarDVR
//
//  Created by yxd on 14-3-10.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import "CarDVRLocation.h"

@implementation CarDVRLocation

+ (CarDVRLocation *)locationWithLatitude:(CGFloat)latitude
                               longitude:(CGFloat)longitude
                                altitude:(CGFloat)altitude
                               timestamp:(NSDate *)timestamp
{
    CarDVRLocation *location = [CarDVRLocation new];
    location.latitude = latitude;
    location.longitude = longitude;
    location.altitude = altitude;
    location.timestamp = timestamp;
    return location;
}

@end
