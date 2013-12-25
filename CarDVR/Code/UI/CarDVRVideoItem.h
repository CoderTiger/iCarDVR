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
@property (strong, readonly, nonatomic) NSURL *fileURL;
@property (strong, readonly, nonatomic) NSDate *creationDate;
@property (readonly, nonatomic) NSTimeInterval duration;// seconds
@property (readonly, nonatomic) float frameRate;// fps
@property (readonly, nonatomic) CGSize dimension;
@property (readonly, nonatomic) unsigned long long fileSize;
@property (strong, readonly, nonatomic) UIImage *thumbnail;

- (id)initWithURL:(NSURL *)anURL;
- (void)generateThumbnailAsynchronouslyWithSize:(CGSize)aSize completionHandler:(void (^)(UIImage *thumbnail)) aCompletionHandler;

@end
