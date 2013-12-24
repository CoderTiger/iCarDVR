//
//  CarDVRVideoTableViewCell.m
//  CarDVR
//
//  Created by yxd on 13-11-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRVideoTableViewCell.h"
#import "CarDVRVideoItem.h"

static const CGFloat kThumbnailWidth = 140.00f;
static const CGFloat kThumbnailHeight = 140.00f;

@interface CarDVRVideoTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *frameRateResolutionLabel;

@end

@implementation CarDVRVideoTableViewCell

@synthesize videoItem = _videoItem;

- (void)setVideoItem:(CarDVRVideoItem *)videoItem
{
    if ( videoItem.thumbnail )
    {
        _thumbnailImageView.image = videoItem.thumbnail;
    }
    else
    {
        [videoItem generateThumbnailAsynchronouslyWithSize:CGSizeMake( kThumbnailWidth, kThumbnailHeight )
                                         completionHandler:^(UIImage *thumbnail) {
                                             dispatch_async( dispatch_get_main_queue(), ^{
                                                 self.thumbnailImageView.image = thumbnail;
                                             });
                                         }];
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
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
