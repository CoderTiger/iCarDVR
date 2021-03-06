//
//  CarDVRVideoTableViewCell.m
//  CarDVR
//
//  Created by yxd on 13-11-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRVideoTableViewCell.h"
#import "CarDVRVideoItem.h"

static const CGFloat kThumbnailWidth2x = 140.00f;
static const CGFloat kThumbnailHeight2x = 100.00f;
//static const CGFloat kThumbnailCornerRadius = 12.5f;//2.0f;//2.5f;
static const CGFloat kThumbnailBorderWidth = 0.5f;
static UIColor *thumbnailBorderColor;
static NSDateFormatter *dateFormatter;

@interface CarDVRVideoTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *frameRateResolutionLabel;

@end

@implementation CarDVRVideoTableViewCell

@synthesize videoItem = _videoItem;

+ (void)initialize
{
    thumbnailBorderColor = [UIColor lightGrayColor];
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    [dateFormatter setDateFormat:NSLocalizedString( @"videoCreationDateFormat", nil )];
}

- (void)setVideoItem:(CarDVRVideoItem *)videoItem
{
    if ( _videoItem == videoItem )
        return;
    _videoItem = videoItem;
    //
    // set self.thumbanailImageView.image
    //
    if ( _videoItem.thumbnail )
    {
        _thumbnailImageView.layer.borderWidth = kThumbnailBorderWidth;
        _thumbnailImageView.layer.borderColor = thumbnailBorderColor.CGColor;
        _thumbnailImageView.image = _videoItem.thumbnail;
    }
    else
    {
        [_videoItem generateThumbnailAsynchronouslyWithSize:CGSizeMake( kThumbnailWidth2x, kThumbnailHeight2x )
                                          completionHandler:^(UIImage *thumbnail) {
                                              dispatch_async( dispatch_get_main_queue(), ^{
                                                  _thumbnailImageView.layer.borderWidth = kThumbnailBorderWidth;
                                                  _thumbnailImageView.layer.borderColor = thumbnailBorderColor.CGColor;
//                                                  _thumbnailImageView.layer.cornerRadius = kThumbnailCornerRadius;
                                                  self.thumbnailImageView.image = thumbnail;
                                              });
                                          }];
    }
    //
    // set self.dateLabel.text
    //
    self.dateLabel.text = [dateFormatter stringFromDate:videoItem.creationDate];
    
    // 
    // set self.durationSizeLabel.text
    //
    NSString *durationText;
    NSUInteger durationSeconds = videoItem.duration;
    if ( durationSeconds < 60 )// < 1 minute
    {
        durationText = [NSString stringWithFormat:NSLocalizedString( @"videoSecondsDurationFormat", nil ),
                    durationSeconds];
    }
    else
    {
        durationText = [NSString stringWithFormat:NSLocalizedString( @"videoMinutesSecondsDurationFormat", nil ),
                    durationSeconds / 60, durationSeconds % 60];
    }
    NSString *fileSizeText;
    if ( videoItem.videoFileSize < 1024 )// < 1KB
    {
        fileSizeText = [NSString stringWithFormat:NSLocalizedString( @"videoSizeByteFormat", nil ),
                    videoItem.videoFileSize];
    }
    else if ( videoItem.videoFileSize < 1024 * 1024 )// < 1MB
    {
        fileSizeText = [NSString stringWithFormat:NSLocalizedString( @"videoSizeKByteFormat", nil ),
                    videoItem.videoFileSize / 1024.0];
    }
    else if ( videoItem.videoFileSize < 1024 * 1024 * 1024 )// < 1GB
    {
        fileSizeText = [NSString stringWithFormat:NSLocalizedString( @"videoSizeMByteFormat", nil ),
                    videoItem.videoFileSize / ( 1024.0 * 1024.0 )];
    }
    else
    {
        fileSizeText = [NSString stringWithFormat:NSLocalizedString( @"videoSizeGByteFormat", nil ),
                    videoItem.videoFileSize / ( 1024.0 * 1024.0 * 1024.0 )];
    }
    self.durationSizeLabel.text = [NSString stringWithFormat:NSLocalizedString( @"videoDurationSizeFormat", nil ),
                                   durationText, fileSizeText];
    
    //
    // set self.frameRateResolutionLabel.text
    //
    self.frameRateResolutionLabel.text = [NSString stringWithFormat:NSLocalizedString( @"videoFrameRateDimensionFormat", nil),
                                          videoItem.frameRate, videoItem.dimension.width, videoItem.dimension.height];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
