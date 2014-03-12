//
//  CarDVRVideoItem.m
//  CarDVR
//
//  Created by yxd on 13-11-3.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRVideoItem.h"
#import <AVFoundation/AVFoundation.h>
#import <GPX/GPX.h>
#import "CarDVRPathHelper.h"
#import "CarDVRLocation.h"

@implementation CarDVRVideoItem

@synthesize locations=_locations;

- (NSArray *)locations
{
    if ( !_locations )
    {
        GPXRoot *gpxRoot = [GPXParser parseGPXAtURL:self.videoClipURLs.gpxFileURL];
        if ( gpxRoot && gpxRoot.tracks.count > 0 )
        {
            GPXTrack *gpxTrack = [gpxRoot.tracks objectAtIndex:0];
            if ( gpxTrack && gpxTrack.tracksegments.count > 0 )
            {
                GPXTrackSegment *gpxTrackSegment = [gpxTrack.tracksegments objectAtIndex:0];
                if ( gpxTrackSegment && gpxTrackSegment.trackpoints.count > 0 )
                {
                    NSMutableArray *newLocations = [NSMutableArray arrayWithCapacity:gpxTrackSegment.trackpoints.count];
                    for ( GPXTrackPoint *gpxTrackPoint in gpxTrackSegment.trackpoints )
                    {
                        CarDVRLocation *location = [CarDVRLocation locationWithLatitude:gpxTrackPoint.latitude
                                                                              longitude:gpxTrackPoint.longitude
                                                                               altitude:gpxTrackPoint.elevation
                                                                              timestamp:gpxTrackPoint.time];
                        [newLocations addObject:location];
                    }
                    _locations = newLocations;
                }
            }
        }
    }
    return _locations;
}

- (id)initWithVideoClipURLs:(CarDVRVideoClipURLs *)aVideoClipURLs
{
    NSAssert( aVideoClipURLs, @"aVideoClipURLs should NOT be nil." );
    self = [super init];
    if ( self )
    {
        _videoClipURLs = aVideoClipURLs;
        NSURL *videoFileURL = _videoClipURLs.videoFileURL;
        AVAsset *asset = [AVAsset assetWithURL:videoFileURL];
        if ( !asset )
        {
            NSLog( @"[Error] Cannot create video item with invalid video file" );
            return nil;
        }
        _videoFileName = [videoFileURL lastPathComponent];
        if ( !_videoFileName )
        {
            NSLog( @"[Error] Failed to create CarDVRVideoItem with nil file name(%pt)", _videoFileName );
            return nil;
        }
        NSError *error;
        NSDictionary *videoFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:videoFileURL.path error:&error];
        if ( !videoFileAttributes )
        {
            NSLog( @"[Error] Failed to get file attributes on creating CarDVRVideoItem due to error: \"%@\"", error.description );
            return nil;
        }
        _videoFileSize = [videoFileAttributes fileSize];
        _creationDate = asset.creationDate.dateValue;
        if ( !_creationDate )
        {
            _creationDate = [videoFileAttributes fileCreationDate];
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
        AVAsset *asset = [AVAsset assetWithURL:self.videoClipURLs.videoFileURL];
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
