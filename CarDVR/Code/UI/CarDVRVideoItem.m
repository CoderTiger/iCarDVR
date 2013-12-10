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

static const CGFloat kThumbnailWidth = 140.00f;
static const CGFloat kThumbnailHeight = 140.00f;

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
            NSLog( @"[Error] Failed to create CarDVRVideoItem with nil file name(%pt) or nil created date(%pt)",
                  _fileName, _createdDate );
            return nil;
        }
        NSURL *videoURL = [NSURL fileURLWithPath:_filePath];
        AVAsset *asset = [AVAsset assetWithURL:videoURL];
        if ( !asset )
        {
            NSLog( @"[Error] Failed to create CarDVRVideoItem with nil AVAsset object." );
            return nil;
        }
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        imageGenerator.appliesPreferredTrackTransform = YES;
        imageGenerator.maximumSize = CGSizeMake( kThumbnailWidth, kThumbnailHeight );
        
        // TODO: get thumbnail when displaying it in cell view
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
            CFRelease( imageRef );
        }
    }
    return self;
}

@end
