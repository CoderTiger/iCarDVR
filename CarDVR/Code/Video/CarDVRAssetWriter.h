//
//  CarDVRAssetWriter.h
//  CarDVR
//
//  Created by yxd on 13-11-21.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class CarDVRSettings;

@interface CarDVRAssetWriter : NSObject

@property (strong, readonly, nonatomic) AVAssetWriter *writer;
@property (strong, nonatomic) AVAssetWriterInput *videoInput;
@property (strong, nonatomic) AVAssetWriterInput *audioInput;

@property (assign) BOOL readyToRecordAudio;
@property (assign) BOOL readyToRecordVideo;
@property (assign) BOOL recordingWillBeStarted;
@property (assign) BOOL recordingWillBeStopped;

- (id)initWithURL:(NSURL *)anURL settings:(CarDVRSettings *)aSettings error:(NSError *__autoreleasing *)anOutError;
- (void)writeSampleBuffer:(CMSampleBufferRef)aSampleBuffer ofType:(NSString *)aMediaType;

@end
