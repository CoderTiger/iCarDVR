//
//  CarDVRMeasurementConverter.m
//  CarDVR
//
//  Created by yxd on 14-1-26.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import "CarDVRMeasurementConverter.h"

@implementation CarDVRMeasurementConverter

- (id)init
{
    return [self initWithLocale:[NSLocale currentLocale]];
}

- (id)initWithLocale:(NSLocale *)aLocale
{
    self = [super init];
    if ( self )
    {
        _locale = aLocale;
    }
    return self;
}

- (NSString *)localStringFromMetricLocation:(CLLocation *)aLocation
{
    NSAssert( aLocation, @"aLocation should NOT be nil." );
    NSString *localString;
    BOOL usesMetricSystem = [[self.locale objectForKey:NSLocaleUsesMetricSystem] boolValue];
    if ( usesMetricSystem )
    {
        // TODO: complete
    }
    else// assume American measurement units
    {
//        aLocation.altitude;
        // TODO: complete
    }
    return localString;
}

@end
