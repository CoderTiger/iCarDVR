//
//  CarDVRLocationDetector.h
//  CarDVR
//
//  Created by yxd on 13-12-26.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class CarDVRLocationDetector;
@protocol CarDVRLocationDetectorDelegate <NSObject>

@optional
- (void)detector:(CarDVRLocationDetector *)aDetector didUpdateToLocation:(CLLocation *)aLocation;

@end

@interface CarDVRLocationDetector : NSObject

@property (weak, nonatomic) id<CarDVRLocationDetectorDelegate> delegate;

- (id)initWithDelegate:(id<CarDVRLocationDetectorDelegate>) aDelegate;
- (void)start;
- (void)stop;

@end
