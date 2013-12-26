//
//  CarDVRLocationDetector.m
//  CarDVR
//
//  Created by yxd on 13-12-26.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRLocationDetector.h"
#import <CoreLocation/CoreLocation.h>

@interface CarDVRLocationDetector ()<CLLocationManagerDelegate>
{
    CLLocationManager *_locationManager;
}

#pragma mark - Private methods
- (void)installLocationManager;

@end

@implementation CarDVRLocationDetector

- (id)init
{
    return [self initWithDelegate:nil];
}

- (id)initWithDelegate:(id<CarDVRLocationDetectorDelegate>)aDelegate
{
    self = [super init];
    if ( self )
    {
        _delegate = aDelegate;
        [self installLocationManager];
    }
    return self;
}

- (void)start
{
    if ( ![CLLocationManager locationServicesEnabled] )
    {
        NSLog( @"[Error] location services NOT enabled" );
        return;
    }
    [_locationManager startUpdatingLocation];
    // todo: complete
}

- (void)stop
{
    if ( ![CLLocationManager locationServicesEnabled] )
    {
        NSLog( @"[Error] location services NOT enabled" );
        return;
    }
    [_locationManager stopUpdatingLocation];
    // todo: complete
}

#pragma mark - from CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // todo: complete
    NSLog( @"%s", __PRETTY_FUNCTION__ );
}


#pragma mark - Private methods
- (void)installLocationManager
{
    if ( _locationManager )
        return;
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
}

@end
