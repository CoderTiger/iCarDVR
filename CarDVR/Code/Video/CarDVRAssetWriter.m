//
//  CarDVRAssetWriter.m
//  CarDVR
//
//  Created by yxd on 13-11-21.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRAssetWriter.h"
#import "CarDVRSettings.h"

static NSString *const kSrtRecordFormat = @"%u\r\n%2d:%2d:%2d,%3d --> %2d:%2d:%2d,%3d\r\n%@\r\n\r\n";

static NSDateFormatter *subtitleDateFormatter;

@interface CarDVRAssetWriter ()
{
    NSUInteger _subtitlesSequenceId;
    NSDate *_creationTime;
    NSString *_previousSubtitle;
    NSDate *_previousSubtitleTime;
}

@property (weak, nonatomic, readonly) CarDVRSettings *settings;
@property (strong, nonatomic) NSFileHandle *srtFileHandle;
@property (strong, nonatomic) NSFileHandle *gpxFileHandle;

#pragma mark - Private methods
- (void)writePreviousSubtitle;

@end

@implementation CarDVRAssetWriter

+ (void)initialize
{
    subtitleDateFormatter = [[NSDateFormatter alloc] init];
    [subtitleDateFormatter setDateStyle:NSDateFormatterNoStyle];
    [subtitleDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
}

- (void)setRecording:(BOOL)recording
{
    if ( recording == _recording )
        return;
    _recording = recording;
}

- (id)initWithFolderPath:(NSString *)aFolderPath
                clipName:(NSString *)aClipName
                settings:(CarDVRSettings *)aSettings
                   error:(NSError *__autoreleasing *)anOutError
{
    self = [super init];
    if ( self )
    {
        _subtitlesSequenceId = 1;
        _creationTime = [NSDate date];
        NSString *videoFileName = [aClipName stringByAppendingPathExtension:@"mov"];
        NSString *srtFileName = [aClipName stringByAppendingPathExtension:@"srt"];
        NSString *gpxFileName = [aClipName stringByAppendingPathExtension:@"gpx"];
        NSURL *videoFileURL = [NSURL fileURLWithPath:[aFolderPath stringByAppendingPathComponent:videoFileName] isDirectory:NO];
        NSURL *srtFileURL = [NSURL fileURLWithPath:[aFolderPath stringByAppendingPathComponent:srtFileName] isDirectory:NO];
        NSURL *gpxFileURL = [NSURL fileURLWithPath:[aFolderPath stringByAppendingPathComponent:gpxFileName] isDirectory:NO];
        _writer = [[AVAssetWriter alloc] initWithURL:videoFileURL fileType:AVFileTypeQuickTimeMovie error:anOutError];
        if ( !_writer )
        {
            NSLog( @"[Error] Failed to create AVAssetWriter object with error: \"%@\"", (*anOutError).description );
            return nil;
        }
        [[NSFileManager defaultManager] createFileAtPath:srtFileURL.path contents:nil attributes:nil];
        _srtFileHandle = [NSFileHandle fileHandleForWritingToURL:srtFileURL error:anOutError];
//        _srtFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:NULL closeOnDealloc:YES];
        if ( !_srtFileHandle )
        {
            NSLog( @"[Error] Failed to create subtitles file with error: \"%@\"", (*anOutError) ? (*anOutError).description : @"" );
            return nil;
        }
        // todo: complete
        
        _settings = aSettings;
    }
    return self;
}

- (BOOL)finishWriting
{
    BOOL finished = [self.writer finishWriting];
    if ( finished )
    {
        [self writePreviousSubtitle];
        _srtFileHandle = nil;
        _gpxFileHandle = nil;
    }
    return finished;
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

- (void)addSubtitle:(NSString *)aSubtitle
{
    [self writePreviousSubtitle];
    _previousSubtitle = aSubtitle;
}

#pragma mark - Private methods
- (void)writePreviousSubtitle
{
    if ( _previousSubtitle )
    {
        NSTimeInterval previousSubtitleBeginTimeInterval = [_previousSubtitleTime timeIntervalSinceDate:_creationTime];
        NSDate *previousSubtitleEndTime = [NSDate date];
        NSTimeInterval previousSubtitleEndTimeInterval = [previousSubtitleEndTime timeIntervalSinceDate:_creationTime];
        
        div_t beginHour = div( previousSubtitleBeginTimeInterval, 3600 );
        div_t beginMinitue = div( beginHour.rem, 60 );
        div_t beginSecond = div( beginMinitue.rem, 60 );
        div_t beginMillisecond = div( beginSecond.rem, 1000 );
        
        div_t endHour = div( previousSubtitleEndTimeInterval, 3600 );
        div_t endMinitue = div( endHour.rem, 60 );
        div_t endSecond = div( endMinitue.rem, 60 );
        div_t endMillisecond = div( endSecond.rem, 60 );
        
        NSString *srtRecord = [NSString stringWithFormat:kSrtRecordFormat,
                               _subtitlesSequenceId,
                               beginHour.quot, beginMinitue.quot, beginSecond.quot, beginMillisecond.quot,
                               endHour.quot, endMinitue.quot, endSecond.quot, endMillisecond.quot,
                               _previousSubtitle ];
        [self.srtFileHandle writeData:[srtRecord dataUsingEncoding:NSUTF8StringEncoding]];
        _previousSubtitle = nil;
        _previousSubtitleTime = previousSubtitleEndTime;
    }
}

@end
