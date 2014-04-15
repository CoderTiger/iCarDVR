//
//  CarDVRVideoClipURLs.h
//  CarDVR
//
//  Created by yxd on 14-1-15.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CarDVRVideoClipURLs : NSObject

@property (readonly, nonatomic) NSURL *videoFileURL;
@property (readonly, nonatomic) NSURL *srtFileURL;
@property (readonly, nonatomic) NSURL *gpxFileURL;

@property (strong, nonatomic) NSURL *folderURL;
@property (strong, nonatomic) NSString *clipName;

+ (BOOL)isValidVideoPathExtension:(NSString *)aExtension;

- (id)initWithFolderURL:(NSURL *)aFolderURL clipName:(NSString *)aClipName;

@end
