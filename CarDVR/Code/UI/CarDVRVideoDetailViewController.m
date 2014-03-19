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

@property (weak, nonatomic) IBOutlet UIBarButtonItem *starButton;

@property (weak, nonatomic) IBOutlet UILabel *creationDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *creationDateValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *frameRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *frameRateValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *resolutionLabel;
@property (weak, nonatomic) IBOutlet UILabel *resolutionValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *filesLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoFileValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *srtFileValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *gpxFileValueLabel;

- (IBAction)starButtonTouched:(id)sender;

#pragma mark - private methods
- (void)installDetailsInfo;
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
    
    //
    // Set title.
    //
    self.title = NSLocalizedString( @"playerViewTitle", nil );
    
    //
    // enable/disable 'Star' button
    //
    self.starButton.enabled = self.starEnabled;
    
    //
    // Prevent sub views from being covered by navigation bar
    //
    self.navigationController.navigationBar.translucent = NO;
    if ( [self respondsToSelector:@selector( edgesForExtendedLayout )] )
        self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
    
    self.navigationController.toolbar.translucent = NO;
    
    //
    // Install video data.
    //
    [self installDetailsInfo];
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
- (void)installDetailsInfo
{
    self.creationDateLabel.text = NSLocalizedString( @"creationDateLabel", nil );
    self.durationLabel.text = NSLocalizedString( @"durationLabel", nil );
    self.sizeLabel.text = NSLocalizedString( @"sizeLabel", nil );
    self.frameRateLabel.text = NSLocalizedString( @"frameRateLabel", nil );
    self.resolutionLabel.text = NSLocalizedString( @"resolutionLabel", nil );
    self.filesLabel.text = NSLocalizedString( @"filesLabel", nil );
    
    // set creationg date
    NSDateFormatter *videoCreationDateFormatter = [[NSDateFormatter alloc] init];
    [videoCreationDateFormatter setDateStyle:NSDateFormatterNoStyle];
    [videoCreationDateFormatter setDateFormat:NSLocalizedString( @"videoCreationDateFormat", nil )];
    self.creationDateValueLabel.text = [videoCreationDateFormatter stringFromDate:self.videoItem.creationDate];
    
    // set duration
    NSString *durationText;
    NSUInteger durationSeconds = self.videoItem.duration;
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
    self.durationValueLabel.text = durationText;
    
    // set size
    NSString *fileSizeText;
    if ( self.videoItem.videoFileSize < 1024 )// < 1KB
    {
        fileSizeText = [NSString stringWithFormat:NSLocalizedString( @"videoSizeByteFormat", nil ),
                        self.videoItem.videoFileSize];
    }
    else if ( self.videoItem.videoFileSize < 1024 * 1024 )// < 1MB
    {
        fileSizeText = [NSString stringWithFormat:NSLocalizedString( @"videoSizeKByteFormat", nil ),
                        self.videoItem.videoFileSize / 1024.0];
    }
    else if ( self.videoItem.videoFileSize < 1024 * 1024 * 1024 )// < 1GB
    {
        fileSizeText = [NSString stringWithFormat:NSLocalizedString( @"videoSizeMByteFormat", nil ),
                        self.videoItem.videoFileSize / ( 1024.0 * 1024.0 )];
    }
    else
    {
        fileSizeText = [NSString stringWithFormat:NSLocalizedString( @"videoSizeGByteFormat", nil ),
                        self.videoItem.videoFileSize / ( 1024.0 * 1024.0 * 1024.0 )];
    }
    self.sizeValueLabel.text = fileSizeText;
    
    // set frame rate, resolution
    self.frameRateValueLabel.text = [NSString stringWithFormat:NSLocalizedString( @"videoFrameRateFormat", nil ), self.videoItem.frameRate];
    self.resolutionValueLabel.text = [NSString stringWithFormat:NSLocalizedString( @"videoResolutionFormat", nil ),
                                      self.videoItem.dimension.width, self.videoItem.dimension.height];
    
    // set files
    self.videoFileValueLabel.text = self.videoItem.videoFileName;
    self.srtFileValueLabel.text = self.videoItem.videoClipURLs.srtFileURL.lastPathComponent;
    self.gpxFileValueLabel.text = self.videoItem.videoClipURLs.gpxFileURL.lastPathComponent;
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    if ( ![defaultManager fileExistsAtPath:self.videoItem.videoClipURLs.videoFileURL.path] )
    {
        self.videoFileValueLabel.textColor = [UIColor lightGrayColor];
    }
    if ( ![defaultManager fileExistsAtPath:self.videoItem.videoClipURLs.srtFileURL.path] )
    {
        self.srtFileValueLabel.textColor = [UIColor lightGrayColor];
    }
    if ( ![defaultManager fileExistsAtPath:self.videoItem.videoClipURLs.gpxFileURL.path] )
    {
        self.gpxFileValueLabel.textColor = [UIColor lightGrayColor];
    }
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

- (IBAction)starButtonTouched:(id)sender
{
#pragma unused( sender )
    // todo: complete
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString( @"starredPrompt", nil )
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString( @"close", nil )
                                              otherButtonTitles:nil];
    [alertView show];
    self.starButton.enabled = NO;
}
@end
