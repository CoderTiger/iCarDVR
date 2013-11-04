//
//  CarDVRPlayerViewController.m
//  CarDVR
//
//  Created by yxd on 13-11-3.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRPlayerViewController.h"
#import "CarDVRVideoItem.h"
#import <MediaPlayer/MediaPlayer.h>

@interface CarDVRPlayerViewController ()

@property (weak, nonatomic) CarDVRVideoItem *videoItem;
@property (strong, nonatomic) MPMoviePlayerController *playerController;
@property (weak, nonatomic) IBOutlet UIView *playerProtraitPaneView;

#pragma mark - private methods
- (void)installPlayerControllerWithContentURL:(NSURL *)aURL;

@end

@implementation CarDVRPlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
            videoItem:(CarDVRVideoItem *)aVideoItem
{
    NSAssert( aVideoItem != nil, @"aVideoItem should NOT be nil" );
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _videoItem = aVideoItem;
        self.title = [NSString stringWithFormat:NSLocalizedString( @"playerViewTitleFormat", nil ), _videoItem.fileName];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSURL *videoURL = [NSURL fileURLWithPath:_videoItem.filePath];
    [self installPlayerControllerWithContentURL:videoURL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)installPlayerControllerWithContentURL:(NSURL *)aURL
{
    if ( _playerController )
    {
        return;
    }
    _playerController = [[MPMoviePlayerController alloc] initWithContentURL:aURL];
    _playerController.controlStyle = MPMovieControlStyleEmbedded;
    _playerController.shouldAutoplay = NO;
    [_playerController prepareToPlay];
    CGRect viewBounds = self.view.bounds;
    CGRect playerPortraitFrame = self.playerProtraitPaneView.frame;
    CGRect playerFrame = CGRectMake( viewBounds.origin.x,
                                    viewBounds.origin.y,
                                    playerPortraitFrame.size.width,
                                    playerPortraitFrame.size.height );
    [_playerController.view setFrame:playerFrame];
    [self.view addSubview:_playerController.view];
}

@end
