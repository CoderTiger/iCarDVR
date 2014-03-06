//
//  CarDVRAssetWriter.m
//  CarDVR
//
//  Created by yxd on 13-11-21.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRAssetWriter.h"
#import <GPX/GPX.h>
#import "CarDVRSettings.h"

static NSString *const kSrtRecordFormat = @"%u\r\n%02d:%02d:%02d,%03lld --> %02d:%02d:%02d,%03lld\r\n%@\r\n\r\n";

static NSDateFormatter *subtitleDateFormatter;

@interface CarDVRAssetWriter ()
{
    NSUInteger _subtitlesSequenceId;
    NSDate *_creationTime;
    NSString *_previousSubtitle;
    NSDate *_previousSubtitleTime;
    
    GPXRoot *_gpxRoot;
    GPXTrack *_gpxTrack;
    NSURL *_gpxFileURL;
}

@property (weak, nonatomic, readonly) CarDVRSettings *settings;
@property (strong, nonatomic) NSFileHandle *srtFileHandle;

#pragma mark - Private methods
- (void)constructGPXHarness;
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
        _gpxFileURL = [NSURL fileURLWithPath:[aFolderPath stringByAppendingPathComponent:gpxFileName] isDirectory:NO];
        _writer = [[AVAssetWriter alloc] initWithURL:videoFileURL fileType:AVFileTypeQuickTimeMovie error:anOutError];
        if ( !_writer )
        {
            NSLog( @"[Error] Failed to create AVAssetWriter object with error: \"%@\"", (*anOutError).description );
            return nil;
        }
        [[NSFileManager defaultManager] createFileAtPath:srtFileURL.path contents:nil attributes:nil];
        _srtFileHandle = [NSFileHandle fileHandleForWritingToURL:srtFileURL error:anOutError];
        if ( !_srtFileHandle )
        {
            NSLog( @"[Error] Failed to create subtitles file with error: \"%@\"",
                  (*anOutError) ? (*anOutError).description : @"Unknown reason" );
        }
        
        [self constructGPXHarness];
        
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
        NSError *error;
        [_gpxRoot.gpx writeToURL:_gpxFileURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if ( error )
        {
            NSLog( @"[Error]failed to write GPX file due to: %@", error.description );
        }
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

- (void)didUpdateToLocation:(CLLocation *)aLocation
{
    GPXTrackPoint *trackPoint = [_gpxTrack newTrackpointWithLatitude:(CGFloat)aLocation.coordinate.latitude
                                                           longitude:(CGFloat)aLocation.coordinate.longitude];
    trackPoint.time = [NSDate date];
    trackPoint.elevation = (CGFloat)aLocation.altitude;
}

#pragma mark - Private methods
- (void)constructGPXHarness
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *appName = [mainBundle objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleNameKey];
    
    _gpxRoot = [GPXRoot rootWithCreator:appName];
    
    GPXMetadata *metadata = [[GPXMetadata alloc] init];
    metadata.name = @"iCarDVR GPX File";
    metadata.copyright = [GPXCopyright copyroghtWithAuthor:@"iAutoD.com"];
    NSDateFormatter *yearFormatter = [[NSDateFormatter alloc] init];
    [yearFormatter setDateStyle:NSDateFormatterNoStyle];
    [yearFormatter setDateFormat:@"yyyy"];
    metadata.copyright.year = [yearFormatter dateFromString:@"2014"];
    metadata.link = [GPXLink linkWithHref:@"http://www.iAutoD.com/iCarDVR"];
    metadata.link.text = appName;
    metadata.time = [NSDate date];
    _gpxRoot.metadata = metadata;
    
    
    _gpxTrack = [_gpxRoot newTrack];
}

- (void)writePreviousSubtitle
{
    if ( _previousSubtitle )
    {
        NSTimeInterval previousSubtitleBeginTimeInterval = [_previousSubtitleTime timeIntervalSinceDate:_creationTime];
        NSDate *previousSubtitleEndTime = [NSDate date];
        NSTimeInterval previousSubtitleEndTimeInterval = [previousSubtitleEndTime timeIntervalSinceDate:_creationTime];
        
        div_t beginHour = div( previousSubtitleBeginTimeInterval, 3600 );
        div_t beginMinitue = div( beginHour.rem, 60 );
        lldiv_t beginMillisecond = lldiv( previousSubtitleBeginTimeInterval * 1000, 1000 );
        
        div_t endHour = div( previousSubtitleEndTimeInterval, 3600 );
        div_t endMinitue = div( endHour.rem, 60 );
        lldiv_t endMillisecond = lldiv( previousSubtitleEndTimeInterval * 1000, 1000 );
        
        NSString *srtRecord = [NSString stringWithFormat:kSrtRecordFormat,
                               _subtitlesSequenceId,
                               beginHour.quot, beginMinitue.quot, beginMinitue.rem, beginMillisecond.rem,
                               endHour.quot, endMinitue.quot, endMinitue.rem, endMillisecond.rem,
                               _previousSubtitle];
        _subtitlesSequenceId++;
        [self.srtFileHandle writeData:[srtRecord dataUsingEncoding:NSUTF8StringEncoding]];
        _previousSubtitle = nil;
        _previousSubtitleTime = previousSubtitleEndTime;
    }
}

@end
