//
//  CarDVRPlayerViewController.m
//  CarDVR
//
//  Created by yxd on 13-11-3.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRVideoDetailViewController.h"
#import "CarDVRVideoItem.h"
#import <MediaPlayer/MediaPlayer.h>

@interface CarDVRVideoDetailViewController ()

@property (strong, nonatomic) MPMoviePlayerController *playerController;
@property (weak, nonatomic) IBOutlet UIView *playerPaneView;
@property (weak, nonatomic) IBOutlet UIView *playerCellView;

#pragma mark - private methods
- (void)installPlayerControllerWithContentURL:(NSURL *)aURL;
- (void)layoutSubviews;

- (void)handleMPMoviePlayerDidExitFullscreenNotification;

@end

@implementation CarDVRVideoDetailViewController

- (void)setVideoItem:(CarDVRVideoItem *)videoItem
{
    _videoItem = videoItem;
    if ( _videoItem )
    {
        self.title = [NSString stringWithFormat:NSLocalizedString( @"playerViewTitleFormat", nil ), _videoItem.fileName];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Prevent sub views from being covered by navigation bar
    self.navigationController.navigationBar.translucent = NO;
    if ( [self respondsToSelector:@selector( edgesForExtendedLayout )] )
        self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
    
    [self installPlayerControllerWithContentURL:self.videoItem.fileURL];
}

- (void)viewWillAppear:(BOOL)animated
{
#pragma unused( animated )
    [self layoutSubviews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
#pragma unused(toInterfaceOrientation, duration)
    self.playerController.view.frame = self.playerPaneView.frame;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
#pragma unused( fromInterfaceOrientation )
    [self layoutSubviews];
}

#pragma mark - private methods
- (void)installPlayerControllerWithContentURL:(NSURL *)aURL
{
    if ( _playerController )
    {
        return;
    }
    _playerController = [[MPMoviePlayerController alloc] initWithContentURL:aURL];
    _playerController.controlStyle = MPMovieControlStyleEmbedded;
    _playerController.shouldAutoplay = NO;
    _playerController.view.hidden = NO;
    _playerController.scalingMode = MPMovieScalingModeAspectFit;
    [_playerController prepareToPlay];
    [_playerController.view setFrame:self.playerPaneView.frame];
    [self.playerCellView addSubview:_playerController.view];
    
    NSNotificationCenter *defaultNC = [NSNotificationCenter defaultCenter];
    [defaultNC addObserver:self
                  selector:@selector(handleMPMoviePlayerDidExitFullscreenNotification)
                      name:MPMoviePlayerDidExitFullscreenNotification
                    object:_playerController];
}

- (void)layoutSubviews
{
    self.playerController.view.frame = self.playerPaneView.frame;
}

- (void)handleMPMoviePlayerDidExitFullscreenNotification
{
    [self layoutSubviews];
}

@end
