//
//  CarDVRVideoItem.m
//  CarDVR
//
//  Created by yxd on 13-11-3.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRVideoItem.h"
#import "CarDVRPathHelper.h"
#import <AVFoundation/AVFoundation.h>

static const CGFloat kThumbnailWidth = 60.00f;
static const CGFloat kThumbnailHeight = 60.00f;

@implementation CarDVRVideoItem

@synthesize thumbnail = _thumbnail;

- (void)setThumbnail:(UIImage *)thumbnail
{
    @synchronized( self )
    {
        _thumbnail = thumbnail;
    }
}

- (UIImage *)thumbnail
{
    @synchronized( self )
    {
        return _thumbnail;
    }
}

- (id)initWithPath:(NSString *)aPath
{
    NSAssert( aPath != nil, @"aPath should NOT be nil" );
    self = [super init];
    if ( self )
    {
        _filePath = aPath;
        _fileName = [aPath lastPathComponent];
        _createdDate = [CarDVRPathHelper dateFromString:[_fileName stringByDeletingPathExtension]];
        if ( !_fileName || !_createdDate )
        {
            return nil;
        }
        NSURL *videoURL = [NSURL fileURLWithPath:_filePath];
        AVAsset *asset = [AVAsset assetWithURL:videoURL];
        if ( !asset )
        {
            return nil;
        }
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        imageGenerator.maximumSize = CGSizeMake( kThumbnailWidth, kThumbnailHeight );
        
        // TODO: get thumbnail when displaying it in cell view
#if GENERATE_VIDEO_THUMBNAIL_ASYNC
        NSValue *timeValue = [NSValue valueWithCMTime:CMTimeMake( 1, 60 )];
        dispatch_queue_t current_queue = dispatch_get_current_queue();
        [imageGenerator generateCGImagesAsynchronouslyForTimes:@[timeValue]
                                             completionHandler:^(CMTime requestedTime,
                                                                 CGImageRef image,
                                                                 CMTime actualTime,
                                                                 AVAssetImageGeneratorResult result,
                                                                 NSError *error)
         {
             if ( result == AVAssetImageGeneratorSucceeded )
             {
                 dispatch_async( dispatch_get_main_queue(), ^{
                     self.thumbnail = [UIImage imageWithCGImage:image];
                     CFRelease( image );
                 });
             }
         }];
#else// !GENERATE_VIDEO_THUMBNAIL_ASYNC
        CMTime time = CMTimeMake( 1, 60 );
        CMTime actualTime;
        NSError *error = nil;
        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
        if ( NULL == imageRef )
        {
            return nil;
        }
        _thumbnail = [[UIImage alloc] initWithCGImage:imageRef];
        CFRelease( imageRef );
#endif// #if GENERATE_VIDEO_THUMBNAIL_ASYNC
    }
    return self;
}

@end
