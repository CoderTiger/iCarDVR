//
//  CarDVRTracksMapView.h
//  CarDVR
//
//  Created by yxd on 14-3-17.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class CarDVRVideoItem;

@interface CarDVRTracksLayerView : MKAnnotationView

@property (weak, nonatomic) MKMapView *mapView;
@property (weak, nonatomic) CarDVRVideoItem *videoItem;

- (id)initWithMapView:(MKMapView *)mapView videoItem:(CarDVRVideoItem *)videoItem;

@end
