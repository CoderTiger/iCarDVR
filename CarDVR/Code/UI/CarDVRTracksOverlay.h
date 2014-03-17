//
//  CarDVRTracksOverlay.h
//  CarDVR
//
//  Created by yxd on 14-3-17.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class CarDVRVideoItem;

@interface CarDVRTracksOverlay : NSObject<MKOverlay>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) MKMapRect boundingMapRect;

- (id)initWithVideoItem:(CarDVRVideoItem *)videoItem;

@end
