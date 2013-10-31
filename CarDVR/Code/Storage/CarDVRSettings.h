//
//  CarDVRSettings.h
//  CarDVR
//
//  Created by yxd on 13-10-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CarDVRSettings : NSObject

@property (assign, nonatomic) NSTimeInterval maxRecordingDuration;// second

- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKey:(NSString *)key;

@end
