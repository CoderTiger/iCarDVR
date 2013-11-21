//
//  CarDVRAssetWriter.m
//  CarDVR
//
//  Created by yxd on 13-11-21.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRAssetWriter.h"
#import "CarDVRSettings.h"

@interface CarDVRAssetWriter ()

@property (weak, nonatomic, readonly) CarDVRSettings *settings;

@end

@implementation CarDVRAssetWriter

- (id)initWithURL:(NSURL *)anURL settings:(CarDVRSettings *)aSettings error:(NSError *__autoreleasing *)anOutError
{
    self = [super init];
    if ( self )
    {
        _writer = [[AVAssetWriter alloc] initWithURL:anURL fileType:AVFileTypeQuickTimeMovie error:anOutError];
        if ( !_writer )
        {
            NSLog( @"[Error] %@", *anOutError );
            return nil;
        }
        _settings = aSettings;
    }
    return self;
}

- (void)writeSampleBuffer:(CMSampleBufferRef)aSampleBuffer ofType:(NSString *)aMediaType
{
    if ( _writer.status == AVAssetWriterStatusUnknown )
    {
        if ( [_writer startWriting] )
        {
			[_writer startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp( aSampleBuffer )];
		}
		else
        {
            // TODO: handle error
            NSLog( @"[Error] %@", _writer.error );
		}
	}
	
	if ( _writer.status == AVAssetWriterStatusWriting )
    {
        if ( aMediaType == AVMediaTypeVideo )
        {
			if ( _videoInput.readyForMoreMediaData )
            {
				if ( ![_videoInput appendSampleBuffer:aSampleBuffer] )
                {
					// TODO: handle error
                    NSLog( @"[Error] %@", _writer.error );
				}
			}
		}
		else if ( aMediaType == AVMediaTypeAudio )
        {
			if ( _audioInput.readyForMoreMediaData )
            {
				if ( ![_audioInput appendSampleBuffer:aSampleBuffer] )
                {
                    // TODO: handle error
                    NSLog( @"[Error] %@", _writer.error );
				}
			}
		}
	}
}

@end
