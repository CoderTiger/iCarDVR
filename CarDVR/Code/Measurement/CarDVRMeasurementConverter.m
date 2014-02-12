//
//  CarDVRMeasurementConverter.m
//  CarDVR
//
//  Created by yxd on 14-1-26.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import "CarDVRMeasurementConverter.h"

@implementation CarDVRMeasurementConverter

- (id)initWithLocale:(NSLocale *)aLocale
{
    self = [super init];
    if ( self )
    {
        BOOL usesMetricSystem = [[aLocale objectForKey:NSLocaleUsesMetricSystem] boolValue];
        // todo: complete
    }
    return self;
}

@end
