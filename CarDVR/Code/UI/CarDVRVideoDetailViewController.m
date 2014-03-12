//
//  CarDVRPlayerViewController.m
//  CarDVR
//
//  Created by yxd on 13-11-3.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRVideoDetailViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "CarDVRVideoItem.h"
#import "CarDVRTracksViewController.h"

static NSString *const kShowTracksViewSegueId = @"kShowTracksViewSegueId";

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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = NSLocalizedString( @"playerViewTitle", nil );
    
    // Prevent sub views from being covered by navigation bar
    self.navigationController.navigationBar.translucent = NO;
    if ( [self respondsToSelector:@selector( edgesForExtendedLayout )] )
        self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
    
    self.navigationController.toolbar.translucent = NO;
    [self installPlayerControllerWithContentURL:self.videoItem.videoClipURLs.videoFileURL];
}

- (void)viewWillAppear:(BOOL)animated
{
#pragma unused( animated )
    [self layoutSubviews];
    self.navigationController.toolbarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
#pragma unused( animated )
    [self layoutSubviews];
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.toolbarHidden = YES;
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
#pragma unused( sender )
    if ( [segue.identifier isEqualToString:kShowTracksViewSegueId] )
    {
        CarDVRTracksViewController *tracksViewController = segue.destinationViewController;
        tracksViewController.settings = self.settings;
        tracksViewController.videoItem = self.videoItem;
    }
}

@end
