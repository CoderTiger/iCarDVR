//
//  CarDVRPathHelpler.h
//  CarDVR
//
//  Created by yxd on 13-10-15.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CarDVRPathHelper : NSObject

@property (readonly, copy, nonatomic) NSString *storageFolderPath;
@property (readonly, copy, nonatomic) NSString *recentsFolderPath;
@property (readonly, copy, nonatomic) NSString *starredFolderPath;

@property (readonly, copy, nonatomic) NSString *appSupportFolderPath;
@property (readonly, copy, nonatomic) NSString *settingsPath;

+ (NSString *)stringFromDate:(NSDate *)aDate;
+ (NSDate *)dateFromString:(NSString *)aString;

@end
