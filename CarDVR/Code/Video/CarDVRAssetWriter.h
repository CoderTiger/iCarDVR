//
//  CarDVRAssetWriter.h
//  CarDVR
//
//  Created by yxd on 13-11-21.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>

@class CarDVRSettings;

@interface CarDVRAssetWriter : NSObject

@property (strong, readonly, nonatomic) AVAssetWriter *writer;
@property (strong, nonatomic) AVAssetWriterInput *videoInput;
@property (strong, nonatomic) AVAssetWriterInput *audioInput;

@property (assign) BOOL readyToRecordAudio;
@property (assign) BOOL readyToRecordVideo;
@property (assign) BOOL recordingWillBeStarted;
@property (assign) BOOL recordingWillBeStopped;
@property (assign, getter = isRecording, nonatomic) BOOL recording;

- (id)initWithFolderPath:(NSString *)aFolderPath
                clipName:(NSString *)aClipName
                settings:(CarDVRSettings *)aSettings
                   error:(NSError *__autoreleasing *)anOutError;
- (BOOL)finishWriting;
- (void)writeSampleBuffer:(CMSampleBufferRef)aSampleBuffer ofType:(NSString *)aMediaType;
- (void)addSubtitle:(NSString *)aSubtitle;

@end
