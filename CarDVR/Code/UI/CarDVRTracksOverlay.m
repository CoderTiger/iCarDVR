//
//  CarDVRTracksOverlay.m
//  CarDVR
//
//  Created by yxd on 14-3-17.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import "CarDVRTracksOverlay.h"
#import "CarDVRVideoItem.h"
#import "CarDVRLocation.h"

@implementation CarDVRTracksOverlay

@synthesize coordinate = _coordinate;
@synthesize boundingMapRect = _boundingMapRect;

- (id)initWithVideoItem:(CarDVRVideoItem *)videoItem
{
    self = [super init];
    if ( self )
    {
        if ( !videoItem.locations || !videoItem.locations.count )
        {
            return nil;
        }
        
        CLLocationDegrees maxLat = -90.0f;
        CLLocationDegrees minLat = 90.0f;
        CLLocationDegrees maxLon = -180.0f;
        CLLocationDegrees minLon = 180.0f;
        for ( CarDVRLocation *location in videoItem.locations )
        {
            if ( location.latitude > maxLat )
                maxLat = location.latitude;
            if ( location.latitude < minLat )
                minLat = location.latitude;
            if ( location.longitude > maxLon )
                maxLon = location.longitude;
            if ( location.longitude < minLon )
                minLon = location.longitude;
        }
        
        _coordinate = CLLocationCoordinate2DMake( ( maxLat + minLat ) / 2, ( maxLon + minLon ) / 2 );
        _boundingMapRect = MKMapRectMake( maxLat, maxLon, minLat - maxLat, minLon - maxLon );
    }
    return self;
}

@end
