//
//  CarDVRMapAnnotationView.h
//  CarDVR
//
//  Created by yxd on 14-3-13.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import <MapKit/MapKit.h>

@class CarDVRVideoItem;

@interface CarDVRMapAnnotationView : MKAnnotationView

- (id)initWithMapView:(MKMapView *)mapView videoItem:(CarDVRVideoItem *)videoItem;

@end
