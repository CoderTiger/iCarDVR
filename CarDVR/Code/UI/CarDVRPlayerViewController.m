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

@property (strong, nonatomic) MPMoviePlayerController *playerController;
@property (weak, nonatomic) IBOutlet UIView *playerProtraitPaneView;

#pragma mark - private methods
- (void)installPlayerControllerWithContentURL:(NSURL *)aURL;
- (void)layoutSubviews;

- (void)handleMPMoviePlayerDidExitFullscreenNotification;

@end

@implementation CarDVRPlayerViewController

- (void)setVideoItem:(CarDVRVideoItem *)videoItem
{
    _videoItem = videoItem;
    if ( _videoItem )
    {
        self.title = [NSString stringWithFormat:NSLocalizedString( @"playerViewTitleFormat", nil ), _videoItem.fileName];
        [self installPlayerControllerWithContentURL:_videoItem.fileURL];
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
    [UIView animateWithDuration:duration animations:^{
        if ( UIInterfaceOrientationIsLandscape( toInterfaceOrientation ) )
        {
            CGSize size = [UIScreen mainScreen].bounds.size;
            size = CGSizeMake( size.height, size.width );
            UIApplication *application = [UIApplication sharedApplication];
       
            if ( application.statusBarHidden == NO )
            {
                size.height -= MIN( application.statusBarFrame.size.width, application.statusBarFrame.size.height );
            }
            
            CGRect bounds = self.view.bounds;
            self.playerController.view.frame = CGRectMake( bounds.origin.x,
                                                          bounds.origin.y,
                                                          size.width,
                                                          size.height );
        }
        else
        {
            self.playerController.view.frame = self.playerProtraitPaneView.frame;
        }
    }];
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
    [_playerController prepareToPlay];
    [_playerController.view setFrame:self.playerProtraitPaneView.frame];
    [self.view addSubview:_playerController.view];
    
    NSNotificationCenter *defaultNC = [NSNotificationCenter defaultCenter];
    [defaultNC addObserver:self
                  selector:@selector(handleMPMoviePlayerDidExitFullscreenNotification)
                      name:MPMoviePlayerDidExitFullscreenNotification
                    object:_playerController];
}

- (void)layoutSubviews
{
    UIInterfaceOrientation statusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if ( UIInterfaceOrientationIsLandscape( statusBarOrientation ) )
    {
        self.playerController.view.frame = self.view.bounds;
    }
    else
    {
        self.playerController.view.frame = self.playerProtraitPaneView.frame;
    }
}

- (void)handleMPMoviePlayerDidExitFullscreenNotification
{
    [self layoutSubviews];
}

@end
