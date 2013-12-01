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

- (void)setRecording:(BOOL)recording
{
    if ( recording == _recording )
        return;
    _recording = recording;
}

- (id)initWithURL:(NSURL *)anURL settings:(CarDVRSettings *)aSettings error:(NSError *__autoreleasing *)anOutError
{
    self = [super init];
    if ( self )
    {
#ifdef DEBUG
        NSLog( @"CarDVRAssetWriter %pt: %@", self, anURL );
#endif// DEBUG
        _writer = [[AVAssetWriter alloc] initWithURL:anURL fileType:AVFileTypeQuickTimeMovie error:anOutError];
        if ( !_writer )
        {
            NSLog( @"[Error] Failed to create AVAssetWriter object with error: domain(%@), code(%d), \"%@\"",
                  (*anOutError).domain, (*anOutError).code, (*anOutError).description );
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
            NSLog( @"[Error-sample.step1] %pt, %@", self, _writer.error );
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
                    NSLog( @"[Error-sample.step2] %pt %@", self, _writer.error );
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
                    NSLog( @"[Error-sample.step3] %pt, %@", self, _writer.error );
				}
			}
		}
	}
}

@end
