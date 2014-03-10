//
//  CarDVRVideoItem.h
//  CarDVR
//
//  Created by yxd on 13-11-3.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CarDVRVideoClipURLs.h"

@interface CarDVRVideoItem : NSObject

@property (retain, readonly, nonatomic) NSString *videoFileName;
@property (strong, readonly, nonatomic) CarDVRVideoClipURLs *videoClipURLs;
@property (strong, readonly, nonatomic) NSDate *creationDate;
@property (readonly, nonatomic) NSTimeInterval duration;// seconds
@property (readonly, nonatomic) float frameRate;// fps
@property (readonly, nonatomic) CGSize dimension;
@property (readonly, nonatomic) unsigned long long videoFileSize;
@property (strong, readonly, nonatomic) UIImage *thumbnail;
@property (strong, readonly, nonatomic) NSArray *locations;

- (id)initWithVideoClipURLs:(CarDVRVideoClipURLs *)aVideoClipURLs;
- (void)generateThumbnailAsynchronouslyWithSize:(CGSize)aSize completionHandler:(void (^)(UIImage *thumbnail)) aCompletionHandler;

@end
