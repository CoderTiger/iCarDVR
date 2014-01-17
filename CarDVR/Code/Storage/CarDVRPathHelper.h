//
//  CarDVRPathHelpler.h
//  CarDVR
//
//  Created by yxd on 13-10-15.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CarDVRPathHelper : NSObject

@property (readonly, nonatomic) NSURL *storageFolderURL;
@property (readonly, nonatomic) NSURL *recentsFolderURL;
@property (readonly, nonatomic) NSURL *starredFolderURL;

@property (readonly, nonatomic) NSURL *appSupportFolderURL;
@property (readonly, nonatomic) NSURL *settingsURL;

+ (NSString *)fileNameFromDate:(NSDate *)aDate;

@end
