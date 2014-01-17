//
//  CarDVRRecentsViewController.m
//  CarDVR
//
//  Created by yxd on 13-10-30.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRRecentsViewController.h"
#import "CarDVRAppDelegate.h"
#import "CarDVRVideoItem.h"
#import "CarDVRVideoDetailViewController.h"
#import "CarDVRVideoCapturerConstants.h"
#import "CarDVRVideoTableViewCell.h"
#import "CarDVRVideoClipURLs.h"

static const NSInteger kRecentVideosSection = 0;
static NSString *const kRecentVideoCellId = @"kRecentVideoCellId";
static NSString *const kShowVideoPlayerSegueId = @"kShowVideoPlayerSegueId";

@interface CarDVRRecentsViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *recentVideoTableView;

@property (strong, nonatomic) NSMutableArray *recentVideos;
@property (weak, nonatomic) CarDVRPathHelper *pathHelper;

#pragma mark - private methods
- (void)loadRecentsVideoAsync;
- (NSMutableArray *)loadRecentsVideo;

- (void)handleCarDVRVideoCapturerDidStartRecordingNotification;
- (void)handleCarDVRVideoCapturerDidStopRecordingNotification;

@end

@implementation CarDVRRecentsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self )
    {
        self.title = NSLocalizedString( @"recentsViewTitle", @"Recents" );
        NSNotificationCenter *defaultNC = [NSNotificationCenter defaultCenter];
        [defaultNC addObserver:self
                      selector:@selector(handleCarDVRVideoCapturerDidStopRecordingNotification)
                          name:kCarDVRVideoCapturerDidStopRecordingNotification
                        object:nil];
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
    
    // Prevent 'recents' list view from being covered by navigation bar and tab bar.
//    self.navigationController.navigationBar.translucent = NO;
    self.tabBarController.tabBar.translucent = NO;
    if ( [self respondsToSelector:@selector( edgesForExtendedLayout )] )
        self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
    
    [self loadRecentsVideoAsync];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - from UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#pragma unused( tableView )
    NSInteger numberOfRows = 0;
    if ( section == kRecentVideosSection )
    {
        numberOfRows = self.recentVideos.count;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#pragma unused( tableView )
    CarDVRVideoTableViewCell *cell = nil;
    if ( indexPath.section == kRecentVideosSection && indexPath.row < self.recentVideos.count )
    {
        cell = [tableView dequeueReusableCellWithIdentifier:kRecentVideoCellId];
        CarDVRVideoItem *videoItem = [self.recentVideos objectAtIndex:indexPath.row];
        cell.videoItem = videoItem;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
#pragma unused( tableView, indexPath )
    return YES;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
#pragma unused( tableView )
    if ( indexPath.section == kRecentVideosSection && indexPath.row < self.recentVideos.count )
    {
        if ( editingStyle == UITableViewCellEditingStyleDelete )
        {
            CarDVRVideoItem *videoItem = [self.recentVideos objectAtIndex:indexPath.row];
            NSError *error = nil;
            NSFileManager *defaultManager = [NSFileManager defaultManager];
            [defaultManager removeItemAtURL:videoItem.videoClipURLs.videoFileURL error:&error];
            if ( !error )
            {
                [self.recentVideos removeObjectAtIndex:indexPath.row];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
            [defaultManager removeItemAtURL:videoItem.videoClipURLs.srtFileURL error:&error];
            [defaultManager removeItemAtURL:videoItem.videoClipURLs.gpxFileURL error:&error];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:kShowVideoPlayerSegueId] )
    {
        CarDVRVideoItem *videoItem = [self.recentVideos objectAtIndex:[self.recentVideoTableView indexPathForSelectedRow].row];
        CarDVRVideoDetailViewController *playerViewController = [segue destinationViewController];
        playerViewController.videoItem = videoItem;
    }
}

#pragma mark - private methods
- (void)loadRecentsVideoAsync
{
    dispatch_async( dispatch_get_current_queue(), ^{
        self.recentVideos = [self loadRecentsVideo];
        [self.recentVideoTableView reloadData];
    });
}

- (NSMutableArray *)loadRecentsVideo
{
    NSMutableArray *recentVideos = [NSMutableArray array];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    CarDVRAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    CarDVRPathHelper *pathHelper = appDelegate.pathHelper;
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:pathHelper.recentsFolderURL.path];
    NSString *fileName;
    while ( ( fileName = [dirEnum nextObject] ) )
    {
        if ( ![CarDVRVideoClipURLs isValidVideoPathExtension:fileName.pathExtension] )
        {
            continue;
        }
        NSString *videoClipName = [fileName.lastPathComponent stringByDeletingPathExtension];
        CarDVRVideoClipURLs *videoClipURLs = [[CarDVRVideoClipURLs alloc] initWithFolderURL:pathHelper.recentsFolderURL
                                                                                   clipName:videoClipName];
        CarDVRVideoItem *videoItem = [[CarDVRVideoItem alloc] initWithVideoClipURLs:videoClipURLs];
        if ( videoItem )
        {
            [recentVideos addObject:videoItem];
        }
    }
    return ( recentVideos.count > 0 ? recentVideos : nil );
}

- (void)handleCarDVRVideoCapturerDidStartRecordingNotification
{
    self.recentVideos = nil;
    [self.recentVideoTableView reloadData];
}

- (void)handleCarDVRVideoCapturerDidStopRecordingNotification
{
    [self loadRecentsVideoAsync];
}

@end
