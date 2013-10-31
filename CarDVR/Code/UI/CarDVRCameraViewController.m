//
//  CarDVRCameraViewController.m
//  CarDVR
//
//  Created by yxd on 13-10-14.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRCameraViewController.h"
#import "CarDVRVideoCapturer.h"
#import "CarDVRHomeViewController.h"
#import "CarDVRAppDelegate.h"

@interface CarDVRCameraViewController ()

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *starButton;
@property (weak, nonatomic) IBOutlet UIButton *starredButton;


@property (strong, nonatomic) CarDVRVideoCapturer *videoCapturer;
@property (strong, nonatomic) CarDVRHomeViewController *homeViewController;

@property (weak, nonatomic) IBOutlet UIView *previewerView;

- (IBAction)homeButtonTouched:(id)sender;
- (IBAction)flashButtonTouched:(id)sender;
- (IBAction)fotoButtonTouched:(id)sender;
- (IBAction)startButtonTouched:(id)sender;
- (IBAction)stopButtonTouched:(id)sender;
- (IBAction)starButtonTouched:(id)sender;
- (IBAction)starredButtonTouched:(id)sender;


#pragma mark - private methods
- (void)constructVideoCapturer;
- (void)layoutSubviews;

@end

@implementation CarDVRCameraViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self setTitle:NSLocalizedString( @"cameraViewTitle", @"Camera" )];
        [self constructVideoCapturer];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated
{
#pragma unused(animated)
    self.navigationController.navigationBarHidden = YES;
    
    [self.videoCapturer setPreviewerView:self.previewerView];
    [self layoutSubviews];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    self.homeViewController = nil;
}

#pragma mark - private methods
- (void)constructVideoCapturer
{
    if ( _videoCapturer )
        return;
    CarDVRAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    _videoCapturer = [[CarDVRVideoCapturer alloc] initWithPathHelper:appDelegate.pathHelper];
}

- (void)layoutSubviews
{
    CGRect viewBounds = self.view.bounds;
    [self.previewerView setFrame:viewBounds];
    [self.videoCapturer fitDeviceOrientation];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self layoutSubviews];
}

- (IBAction)homeButtonTouched:(id)sender
{
    if ( !_homeViewController )
    {
        _homeViewController = [[CarDVRHomeViewController alloc] initWithNibName:@"CarDVRHomeViewController"
                                                                         bundle:nil];
    }
    [self.navigationController pushViewController:self.homeViewController animated:YES];
}

- (IBAction)flashButtonTouched:(id)sender
{
    // TODO: complete
}

- (IBAction)fotoButtonTouched:(id)sender
{
    // TODO: complete
}

- (IBAction)startButtonTouched:(id)sender
{
    if ( self.videoCapturer.isRunning )
    {
        [self.videoCapturer stop];
    }
    [self.videoCapturer start];
    self.startButton.hidden = self.videoCapturer.isRunning;
    self.stopButton.hidden = !self.startButton.hidden;
}

- (IBAction)stopButtonTouched:(id)sender
{
    if ( self.videoCapturer.isRunning )
    {
        [self.videoCapturer stop];
    }
    self.startButton.hidden = self.videoCapturer.isRunning;
    self.stopButton.hidden = !self.startButton.hidden;
}

- (IBAction)starButtonTouched:(id)sender
{
    [self.videoCapturer setStarred:YES];
    self.starButton.hidden = self.videoCapturer.starred;
    self.starredButton.hidden = !self.starredButton.hidden;
}

- (IBAction)starredButtonTouched:(id)sender
{
    [self.videoCapturer setStarred:NO];
    self.starButton.hidden = self.videoCapturer.starred;
    self.starredButton.hidden = !self.starredButton.hidden;
}

@end
