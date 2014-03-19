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
#import "CarDVRPathHelper.h"

static NSDateFormatter *videoCreationDateFormatter;

static NSString *const kVideoCellId = @"kVideoCellId";
static NSString *const kShowVideoPlayerSegueId = @"kShowVideoPlayerSegueId";

@interface CarDVRVideoBrowserViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *videoTableView;

@property (strong, nonatomic) NSMutableArray *videos;

#pragma mark - private methods
- (void)loadVideosAsync;
- (NSMutableArray *)loadVideos;
- (void)typeChanged;

- (void)handleCarDVRVideoCapturerDidStartRecordingNotification;
- (void)handleCarDVRVideoCapturerDidStopRecordingNotification;

@end

@implementation CarDVRVideoBrowserViewController

+ (void)initialize
{
    videoCreationDateFormatter = [[NSDateFormatter alloc] init];
    [videoCreationDateFormatter setDateStyle:NSDateFormatterNoStyle];
    [videoCreationDateFormatter setDateFormat:NSLocalizedString( @"videoCreationDateFormat", nil )];
}

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
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.videos count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title;
    if ( section < self.videos.count )
    {
        CarDVRVideoItem *videoItem = [self.videos[section] objectAtIndex:0];
        NSString *creationDate = [videoCreationDateFormatter stringFromDate:videoItem.creationDate];
        if ( [self.videos[section] count] > 1 )
        {
            title = [NSString stringWithFormat:NSLocalizedString( @"multipleVideoSectionHeaderTitleFormat", nil ),
                     creationDate, [self.videos[section] count]];
        }
        else
        {
            title = [NSString stringWithFormat:NSLocalizedString( @"singleVideoSectionHeaderTitleFormat", nil ),
                     creationDate];
        }
    }
    return title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#pragma unused( tableView )
    NSInteger numberOfRows = 0;
    if ( section < self.videos.count )
    {
        numberOfRows = [self.videos[section] count];
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#pragma unused( tableView )
    CarDVRVideoTableViewCell *cell;
    if ( indexPath.section < self.videos.count && indexPath.row < [self.videos[indexPath.section] count] )
    {
        cell = [tableView dequeueReusableCellWithIdentifier:kVideoCellId];
        if ( !cell )
        {
            cell = [[CarDVRVideoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kVideoCellId];
        }
        CarDVRVideoItem *videoItem = [self.videos[indexPath.section] objectAtIndex:indexPath.row];
        cell.videoItem = videoItem;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
#pragma unused( tableView, indexPath )
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
#pragma unused( tableView )
    if ( indexPath.section < self.videos.count && indexPath.row < [self.videos[indexPath.section] count] )
    {
        if ( editingStyle == UITableViewCellEditingStyleDelete )
        {
            CarDVRVideoItem *videoItem = [self.videos[indexPath.section] objectAtIndex:indexPath.row];
            NSError *error;
            NSFileManager *defaultManager = [NSFileManager defaultManager];
            [defaultManager removeItemAtURL:videoItem.videoClipURLs.videoFileURL error:&error];
#ifdef DEBUG
            if ( error )
            {
                NSLog( @"[Error]failed to delete '%@':\n%@", videoItem.videoClipURLs.videoFileURL, error.description );
            }
#endif
            [defaultManager removeItemAtURL:videoItem.videoClipURLs.srtFileURL error:&error];
#ifdef DEBUG
            if ( error )
            {
                NSLog( @"[Error]failed to delete '%@':\n%@", videoItem.videoClipURLs.srtFileURL, error.description );
            }
#endif
            [defaultManager removeItemAtURL:videoItem.videoClipURLs.gpxFileURL error:&error];
#ifdef DEBUG
            if ( error )
            {
                NSLog( @"[Error]failed to delete '%@':\n%@", videoItem.videoClipURLs.gpxFileURL, error.description );
            }
#endif
//            if ( !error )
            {
                [self.videos[indexPath.section] removeObjectAtIndex:indexPath.row];
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:indexPath.section];
                if ( [self.videos[indexPath.section] count] == 0 )
                {
                    [self.videos removeObjectAtIndex:indexPath.section];
                    [tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
                }
                else
                {
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [self.videoTableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
                }
            }
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:kShowVideoPlayerSegueId] )
    {
        NSIndexPath *indexPath = [self.videoTableView indexPathForSelectedRow];
        if ( indexPath.section < self.videos.count && indexPath.row < [self.videos[indexPath.section] count] )
        {
            CarDVRVideoItem *videoItem = [self.videos[indexPath.section] objectAtIndex:indexPath.row];
            CarDVRVideoDetailViewController *playerViewController = [segue destinationViewController];
            playerViewController.settings = self.settins;
            playerViewController.videoItem = videoItem;
            if ( self.type == kCarDVRVideoBrowserViewControllerTypeRecents )
            {
                playerViewController.starEnabled = YES;
            }
        }
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
    
    NSURL *videoFolderURL;
    switch ( self.type )
    {
        case kCarDVRVideoBrowserViewControllerTypeRecents:
            videoFolderURL = self.pathHelper.recentsFolderURL;
            break;
        case kCarDVRVideoBrowserViewControllerTypeStarred:
            videoFolderURL = self.pathHelper.starredFolderURL;
            break;
        default:
            break;
    }
    NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtURL:videoFolderURL
                                       includingPropertiesForKeys:@[NSURLCreationDateKey]
                                                          options:NSDirectoryEnumerationSkipsSubdirectoryDescendants
                                                     errorHandler:^BOOL(NSURL *url, NSError *error) {
                                                         NSLog( @"[Error] %@, %@", url, error.description );
                                                         return YES;
                                                     }];//[fileManager enumeratorAtPath:videoFolderURL.path];
    
    NSMutableDictionary *fileURLWithDateDict = [NSMutableDictionary dictionary];
    for ( NSURL *fileURL in dirEnum )
    {
        NSDate *creationgDate;
        if ( [fileURL getResourceValue:&creationgDate forKey:NSURLCreationDateKey error:nil] )
        {
            [fileURLWithDateDict setObject:creationgDate forKey:fileURL];
        }
    }
    
    NSDate *prevFileEndDate;
    NSMutableArray *videoGroup;
    for ( NSURL *fileURL in [fileURLWithDateDict keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }])
    {
        if ( ![CarDVRVideoClipURLs isValidVideoPathExtension:fileURL.pathExtension] )
        {
            continue;
        }
        NSString *videoClipName = [fileURL.lastPathComponent stringByDeletingPathExtension];
        CarDVRVideoClipURLs *videoClipURLs = [[CarDVRVideoClipURLs alloc] initWithFolderURL:videoFolderURL
                                                                                   clipName:videoClipName];
        CarDVRVideoItem *videoItem = [[CarDVRVideoItem alloc] initWithVideoClipURLs:videoClipURLs];
        if ( !videoItem )
        {
            if ( !self.switchFromRecordingCamera )
            {
                // remove truncated or invalid video files
                NSFileManager *defaultFileManager = [NSFileManager defaultManager];
                [defaultFileManager removeItemAtURL:videoClipURLs.videoFileURL error:nil];
                [defaultFileManager removeItemAtURL:videoClipURLs.srtFileURL error:nil];
                [defaultFileManager removeItemAtURL:videoClipURLs.gpxFileURL error:nil];
            }
            continue;
        }
        
        if ( prevFileEndDate )
        {
            NSComparisonResult comparisonResult = [videoItem.creationDate compare:prevFileEndDate];
            if ( comparisonResult == NSOrderedDescending )// later than prevFileEndDate
            {
                videoGroup = [NSMutableArray array];
                [videos insertObject:videoGroup atIndex:0];
            }
        }
        else
        {
            videoGroup = [NSMutableArray array];
            [videos insertObject:videoGroup atIndex:0];
        }
        [videoGroup addObject:videoItem];
        prevFileEndDate = [NSDate dateWithTimeInterval:videoItem.duration sinceDate:videoItem.creationDate];
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
