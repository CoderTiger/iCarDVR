//
//  CarDVRVideoItem.h
//  CarDVR
//
//  Created by yxd on 13-11-3.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CarDVRVideoItem : NSObject

@property (retain, readonly, nonatomic) NSString *fileName;
@property (retain, readonly, nonatomic) NSString *filePath;
@property (strong, readonly, nonatomic) NSDate *createdDate;
@property (strong, readonly, nonatomic) UIImage *thumbnail;

- (id)initWithPath:(NSString *)aPath;

@end
