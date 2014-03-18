//
//  CarDVRLocationDetector.m
//  CarDVR
//
//  Created by yxd on 13-12-26.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRLocationDetector.h"

@interface CarDVRLocationDetector ()<CLLocationManagerDelegate>
{
    CLLocationManager *_locationManager;
}

#pragma mark - Private methods
- (void)installLocationManager;
- (void)didUpdateToLocation:(CLLocation *)aLocation;

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
    [self installLocationManager];
    
    [_locationManager startUpdatingLocation];
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
// for iOS 6 and above
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    if ( locations.count )
    {
        [self didUpdateToLocation:[locations lastObject]];
    }
}

// for iOS 5 and below
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
#pragma unused( newLocation )
    [self didUpdateToLocation:newLocation];
}


#pragma mark - Private methods
- (void)installLocationManager
{
    if ( _locationManager )
        return;
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
}

- (void)didUpdateToLocation:(CLLocation *)aLocation
{
    const NSTimeInterval kMaxLocationAge = 3.0f;// MARK: the threshold value (3.0f) might need to be adjusted by testing.
    NSTimeInterval locationAge = -[aLocation.timestamp timeIntervalSinceNow];
    if ( ( locationAge < kMaxLocationAge ) && ( self.delegate ) )
    {
        [self.delegate detector:self didUpdateToLocation:aLocation];
    }
}

@end
