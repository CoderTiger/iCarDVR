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

- (id)initWithURL:(NSURL *)anURL
{
    NSAssert( anURL != nil, @"anURL should NOT be nil" );
    self = [super init];
    if ( self )
    {
        _fileURL = anURL;
        AVAsset *asset = [AVAsset assetWithURL:_fileURL];
        if ( !asset )
        {
            NSLog( @"[Error] Cannot create video item with invalid video file" );
            return nil;
        }
        _fileName = [_fileURL lastPathComponent];
        if ( !_fileName )
        {
            NSLog( @"[Error] Failed to create CarDVRVideoItem with nil file name(%pt)", _fileName );
            return nil;
        }
        NSError *error;
        NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_fileURL.path error:&error];
        if ( !fileAttributes )
        {
            NSLog( @"[Error] Failed to get file attributes on creating CarDVRVideoItem due to error: \"%@\"", error.description );
            return nil;
        }
        _fileSize = [fileAttributes fileSize];
        _creationDate = asset.creationDate.dateValue;
        if ( !_creationDate )
        {
            _creationDate = [fileAttributes fileCreationDate];
        }
        _duration = asset.duration.value / asset.duration.timescale;
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if ( !videoTracks.count )
        {
            NSLog( @"[Error] No video tracks found on creating CarDVRVideoItem." );
            return nil;
        }
        AVAssetTrack *videoTrack = videoTracks[0];
        _frameRate = videoTrack.nominalFrameRate;
        _dimension = videoTrack.naturalSize;
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
            @synchronized( self )
            {
                _thumbnail = [[UIImage alloc] initWithCGImage:imageRef];
                if ( aCompletionHandler )
                {
                    aCompletionHandler( _thumbnail );
                }
            }
            CFRelease( imageRef );
        }
    });
}

@end
