//
//  CarDVRAnnotation.m
//  CarDVR
//
//  Created by yxd on 14-3-13.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import "CarDVRAnnotation.h"
#import "CarDVRLocation.h"

@implementation CarDVRAnnotation

@synthesize coordinate = _coordinate;
@synthesize title = _title;

- (id)initWithLocation:(CarDVRLocation *)location title:(NSString *)title
{
    self = [super init];
    if ( self )
    {
        _coordinate.latitude = location.latitude;
        _coordinate.longitude = location.longitude;
        _title = title;
    }
    return self;
}

@end
