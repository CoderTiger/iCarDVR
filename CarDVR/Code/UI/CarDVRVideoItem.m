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

- (id)initWithURL:(NSURL *)anURL
{
    NSAssert( anURL != nil, @"anURL should NOT be nil" );
    self = [super init];
    if ( self )
    {
        _fileURL = anURL;
        _fileName = [_fileURL lastPathComponent];
        _createdDate = [CarDVRPathHelper dateFromString:[_fileName stringByDeletingPathExtension]];
        if ( !_fileName || !_createdDate )
        {
            NSLog( @"[Error] Failed to create CarDVRVideoItem with nil file name(%pt) or nil created date(%pt)",
                  _fileName, _createdDate );
            return nil;
        }
    }
    return self;
}

- (void)generateThumbnailAsynchronouslyWithSize:(CGSize)aSize completionHandler:(void (^)(UIImage *))aCompletionHandler
{
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0 ), ^{
        AVAsset *asset = [AVAsset assetWithURL:self.fileURL];
        if ( !asset )
        {
            NSLog( @"[Error] Failed to create CarDVRVideoItem with nil AVAsset object." );
            return;
        }
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        imageGenerator.maximumSize = CGSizeMake( aSize.width, aSize.height );
        
        CMTime time = CMTimeMake( 1, 60 );
        CMTime actualTime;
        NSError *error = nil;
        CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
        if ( NULL == imageRef )
        {
            NSLog( @"[Error] Failed to create CarDVRVideoItem with nil CGImageRef object" );
        }
        else
        {
            _thumbnail = [[UIImage alloc] initWithCGImage:imageRef];
            if ( aCompletionHandler )
            {
                aCompletionHandler( _thumbnail );
            }
            CFRelease( imageRef );
        }
    });
}

@end
