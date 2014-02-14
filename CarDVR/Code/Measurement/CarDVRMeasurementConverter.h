//
//  CarDVRMeasurementConverter.h
//  CarDVR
//
//  Created by yxd on 14-1-26.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CarDVRMeasurementConverter : NSObject

@property (strong, nonatomic) NSLocale *locale;

- (id)init;
- (id)initWithLocale:(NSLocale *)aLocale;

- (NSString *)localStringFromMetricLocation:(CLLocation *)aLocation;

@end
