//
//  CarDVRRecentsViewController.m
//  CarDVR
//
//  Created by yxd on 13-10-30.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRVideoBrowserViewController.h"
#import "CarDVRAppDelegate.h"
#import "CarDVRVideoItem.h"
#import "CarDVRVideoDetailViewController.h"
#import "CarDVRVideoCapturerConstants.h"
#import "CarDVRVideoTableViewCell.h"
#import "CarDVRVideoClipURLs.h"

static const NSInteger kVideosSection = 0;
static NSString *const kVideoCellId = @"kVideoCellId";
static NSString *const kShowVideoPlayerSegueId = @"kShowVideoPlayerSegueId";

@interface CarDVRVideoBrowserViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *videoTableView;

@property (strong, nonatomic) NSMutableArray *videos;
@property (weak, nonatomic) CarDVRPathHelper *pathHelper;

#pragma mark - private methods
- (void)loadVideosAsync;
- (NSMutableArray *)loadVideos;
- (void)typeChanged;

- (void)handleCarDVRVideoCapturerDidStartRecordingNotification;
- (void)handleCarDVRVideoCapturerDidStopRecordingNotification;

@end

@implementation CarDVRVideoBrowserViewController

- (void)setType:(CarDVRVideoBrowserViewControllerType)type
{
    _type = type;
    [self typeChanged];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( self )
    {
        [self typeChanged];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self )
    {
        [self typeChanged];
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
    [self typeChanged];
    
    NSNotificationCenter *defaultNC = [NSNotificationCenter defaultCenter];
    [defaultNC addObserver:self
                  selector:@selector(handleCarDVRVideoCapturerDidStopRecordingNotification)
                      name:kCarDVRVideoCapturerDidStopRecordingNotification
                    object:nil];
    
    // Prevent 'recents' list view from being covered by navigation bar and tab bar.
//    self.navigationController.navigationBar.translucent = NO;
    self.tabBarController.tabBar.translucent = NO;
    if ( [self respondsToSelector:@selector( edgesForExtendedLayout )] )
        self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
    
    [self loadVideosAsync];
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
    if ( section == kVideosSection )
    {
        numberOfRows = self.videos.count;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#pragma unused( tableView )
    CarDVRVideoTableViewCell *cell;
    if ( indexPath.section == kVideosSection && indexPath.row < self.videos.count )
    {
        cell = [tableView dequeueReusableCellWithIdentifier:kVideoCellId];
        CarDVRVideoItem *videoItem = [self.videos objectAtIndex:indexPath.row];
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
    if ( indexPath.section == kVideosSection && indexPath.row < self.videos.count )
    {
        if ( editingStyle == UITableViewCellEditingStyleDelete )
        {
            CarDVRVideoItem *videoItem = [self.videos objectAtIndex:indexPath.row];
            NSError *error = nil;
            NSFileManager *defaultManager = [NSFileManager defaultManager];
            [defaultManager removeItemAtURL:videoItem.videoClipURLs.videoFileURL error:&error];
            if ( !error )
            {
                [self.videos removeObjectAtIndex:indexPath.row];
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
        CarDVRVideoItem *videoItem = [self.videos objectAtIndex:[self.videoTableView indexPathForSelectedRow].row];
        CarDVRVideoDetailViewController *playerViewController = [segue destinationViewController];
        playerViewController.videoItem = videoItem;
    }
}

#pragma mark - private methods
- (void)loadVideosAsync
{
    dispatch_async( dispatch_get_current_queue(), ^{
        self.videos = [self loadVideos];
        [self.videoTableView reloadData];
    });
}

- (NSMutableArray *)loadVideos
{
    NSMutableArray *videos = [NSMutableArray array];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    CarDVRAppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    CarDVRPathHelper *pathHelper = appDelegate.pathHelper;
    NSURL *videoFolderURL;
    switch ( self.type )
    {
        case kCarDVRVideoBrowserViewControllerTypeRecents:
            videoFolderURL = pathHelper.recentsFolderURL;
            break;
        case kCarDVRVideoBrowserViewControllerTypeStarred:
            videoFolderURL = pathHelper.starredFolderURL;
            break;
        default:
            break;
    }
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:videoFolderURL.path];
    NSString *fileName;
    while ( ( fileName = [dirEnum nextObject] ) )
    {
        if ( ![CarDVRVideoClipURLs isValidVideoPathExtension:fileName.pathExtension] )
        {
            continue;
        }
        NSString *videoClipName = [fileName.lastPathComponent stringByDeletingPathExtension];
        CarDVRVideoClipURLs *videoClipURLs = [[CarDVRVideoClipURLs alloc] initWithFolderURL:videoFolderURL
                                                                                   clipName:videoClipName];
        CarDVRVideoItem *videoItem = [[CarDVRVideoItem alloc] initWithVideoClipURLs:videoClipURLs];
        if ( videoItem )
        {
            [videos addObject:videoItem];
        }
    }
    return ( videos.count > 0 ? videos : nil );
}

- (void)typeChanged
{
    switch ( _type )
    {
        case kCarDVRVideoBrowserViewControllerTypeRecents:
            self.title = NSLocalizedString( @"recentsViewTitle", @"Recents" );
            break;
        case kCarDVRVideoBrowserViewControllerTypeStarred:
            self.title = NSLocalizedString( @"starredViewTitle", @"Starred" );
            break;
        default:
            break;
    }
}

- (void)handleCarDVRVideoCapturerDidStartRecordingNotification
{
    self.videos = nil;
    [self.videoTableView reloadData];
}

- (void)handleCarDVRVideoCapturerDidStopRecordingNotification
{
    [self loadVideosAsync];
}

@end
