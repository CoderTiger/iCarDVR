//
//  CarDVRAnnotation.h
//  CarDVR
//
//  Created by yxd on 14-3-13.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class CarDVRLocation;

@interface CarDVRAnnotation : NSObject<MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;

- (id)initWithLocation:(CarDVRLocation *)location title:(NSString *)title;

@end
