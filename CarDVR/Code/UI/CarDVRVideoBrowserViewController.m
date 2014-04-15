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
static NSString *const kLoadDidCompleteNotification = @"kLoadDidCompleteNotification";
static NSString *const kStarDidCompleteNotification = @"kStarDidCompleteNotification";
static NSString *const kVideoItemsKey = @"kVideoItemsKey";

@interface CarDVRVideoBrowserViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *videoTableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *starButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButtonItem;

@property (strong, nonatomic) NSMutableArray *videos;
@property (strong, nonatomic) NSMutableSet *markedIndexes;

- (IBAction)cancelButtonItemTouched:(id)sender;
- (IBAction)starButtonItemTouched:(id)sender;
- (IBAction)deleteButtonItemTouched:(id)sender;

#pragma mark - private methods
- (void)loadVideosAsync;
- (NSMutableArray *)loadVideos;
- (void)typeChanged;
- (void)editableVideoBrowserViewControllerDone:(CarDVRVideoBrowserViewController *)controller;
- (void)deleteVideoClipAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteVideoClipsAtIndexPaths:(NSArray *)indexPaths;
- (void)starVideoClipAtIndexPath:(NSIndexPath *)indexPath;
- (void)starVideoClipsAtIndexPaths:(NSArray *)indexPaths;
- (NSMutableArray *)addStarredVideos:(NSArray *)starredVideos;
- (void)addStarredVideosAsync:(NSArray *)starredVideos;

- (void)updateToolbarButtonItemsState;

- (void)handleCarDVRVideoCapturerDidStartRecordingNotification;
- (void)handleCarDVRVideoCapturerDidStopRecordingNotification;

- (void)handleLoadDidCompleteNotification;
- (void)handleStarDidCompleteNotification:(NSNotification *)notification;

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
    
    if ( self.isEditable )
    {
        NSNotificationCenter *defaultNC = [NSNotificationCenter defaultCenter];
        [defaultNC addObserver:self
                      selector:@selector(handleLoadDidCompleteNotification)
                          name:kLoadDidCompleteNotification
                        object:nil];
        _markedIndexes = [[NSMutableSet alloc] init];
        
        self.navigationController.navigationBar.translucent = NO;
        self.navigationController.toolbar.translucent = NO;
    }
    else
    {
        NSNotificationCenter *defaultNC = [NSNotificationCenter defaultCenter];
        [defaultNC addObserver:self
                      selector:@selector(handleCarDVRVideoCapturerDidStopRecordingNotification)
                          name:kCarDVRVideoCapturerDidStopRecordingNotification
                        object:nil];
        
        if ( self.type == kCarDVRVideoBrowserViewControllerTypeStarred )
        {
            [defaultNC addObserver:self
                          selector:@selector(handleStarDidCompleteNotification:)
                              name:kStarDidCompleteNotification
                            object:nil];
        }
        
        // Prevent 'recents' list view from being covered by navigation bar and tab bar.
//        self.navigationController.navigationBar.translucent = NO;
        self.tabBarController.tabBar.translucent = NO;
        if ( [self respondsToSelector:@selector( edgesForExtendedLayout )] )
            self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
    }
    
    [self loadVideosAsync];
}

- (void)viewWillAppear:(BOOL)animated
{
#pragma unused( animated )
    if ( self.isEditable )
    {
        self.videoTableView.contentOffset = self.ownerViewController.videoTableView.contentOffset;
        self.navigationController.toolbarHidden = NO;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
#pragma unused( animated )
    if ( self.isEditable )
    {
        self.navigationController.toolbarHidden = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - from UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSMutableArray *videos = self.isEditable ? self.ownerViewController.videos : self.videos;
    return [videos count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title;
    NSMutableArray *videos = self.isEditable ? self.ownerViewController.videos : self.videos;
    if ( section < videos.count )
    {
        CarDVRVideoItem *videoItem = [videos[section] objectAtIndex:0];
        NSString *creationDate = [videoCreationDateFormatter stringFromDate:videoItem.creationDate];
        if ( [videos[section] count] > 1 )
        {
            title = [NSString stringWithFormat:NSLocalizedString( @"multipleVideoSectionHeaderTitleFormat", nil ),
                     creationDate, [videos[section] count]];
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
    NSMutableArray *videos = self.isEditable ? self.ownerViewController.videos : self.videos;
    if ( section < videos.count )
    {
        numberOfRows = [videos[section] count];
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#pragma unused( tableView )
    CarDVRVideoTableViewCell *cell;
    NSMutableArray *videos = self.isEditable ? self.ownerViewController.videos : self.videos;
    if ( indexPath.section < videos.count && indexPath.row < [videos[indexPath.section] count] )
    {
        cell = [tableView dequeueReusableCellWithIdentifier:kVideoCellId];
        if ( !cell )
        {
            cell = [[CarDVRVideoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kVideoCellId];
        }
        CarDVRVideoItem *videoItem = [videos[indexPath.section] objectAtIndex:indexPath.row];
        cell.videoItem = videoItem;
        
        if ( self.isEditable )
        {
            if ( [self.markedIndexes containsObject:indexPath] )
            {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
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
    NSMutableArray *videos = self.isEditable ? self.ownerViewController.videos : self.videos;
    if ( indexPath.section < videos.count && indexPath.row < [videos[indexPath.section] count] )
    {
        if ( editingStyle == UITableViewCellEditingStyleDelete )
        {
            [self deleteVideoClipAtIndexPath:indexPath];
        }
    }
}

#pragma mark - from UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ( self.isEditable )
    {
        if ( [self.markedIndexes containsObject:indexPath] )
        {
            [self.markedIndexes removeObject:indexPath];
        }
        else
        {
            [self.markedIndexes addObject:indexPath];
        }
        [self updateToolbarButtonItemsState];
        [tableView reloadData];
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
            else
            {
                playerViewController.starEnabled = NO;
            }
        }
    }
}

- (IBAction)cancelButtonItemTouched:(id)sender
{
#pragma unused( sender )
    [self.ownerViewController editableVideoBrowserViewControllerDone:self];
    [self.navigationController dismissModalViewControllerAnimated:YES];
    
}

- (IBAction)starButtonItemTouched:(id)sender
{
#pragma unused( sender )
    [self starVideoClipsAtIndexPaths:[self.markedIndexes allObjects]];
}

- (IBAction)deleteButtonItemTouched:(id)sender
{
#pragma unused( sender )
    [self deleteVideoClipsAtIndexPaths:[self.markedIndexes allObjects]];
}

#pragma mark - private methods
- (void)loadVideosAsync
{
    dispatch_async( dispatch_get_current_queue(), ^{
        if ( self.isEditable )
        {
            if ( self.ownerViewController.videos.count > 0 )
            {
                [self.videoTableView reloadData];
            }
        }
        else
        {
            self.videos = [self loadVideos];
            [self.videoTableView reloadData];
        }
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

- (void)editableVideoBrowserViewControllerDone:(CarDVRVideoBrowserViewController *)controller
{
    self.videoTableView.contentOffset = controller.videoTableView.contentOffset;
}

- (void)deleteVideoClipAtIndexPath:(NSIndexPath *)indexPath
{
    [self deleteVideoClipsAtIndexPaths:@[indexPath]];
}

- (void)deleteVideoClipsAtIndexPaths:(NSArray *)indexPaths
{
    NSMutableArray *videos = self.isEditable ? self.ownerViewController.videos : self.videos;
    
    //
    // mark video clips for deleting.
    //
    NSMutableDictionary *videosToDelete = [NSMutableDictionary dictionary];
    for ( NSIndexPath *indexPath in indexPaths )
    {
        CarDVRVideoItem *videoItem = [videos[indexPath.section] objectAtIndex:indexPath.row];
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
        NSNumber *sectionNumber = [NSNumber numberWithInteger:indexPath.section];
        NSMutableIndexSet *videoClipIndexSet = [videosToDelete objectForKey:sectionNumber];
        if ( !videoClipIndexSet )
        {
            videoClipIndexSet = [NSMutableIndexSet indexSet];
            [videosToDelete setObject:videoClipIndexSet forKey:sectionNumber];
        }
        [videoClipIndexSet addIndex:indexPath.row];
        
        if ( self.isEditable )
        {
            [self.markedIndexes removeObject:indexPath];
        }
    }
    
    //
    // delete marked video clip objects.
    //
    NSMutableIndexSet *sectionSetToDelete = [NSMutableIndexSet indexSet];
    [videosToDelete enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSNumber *sectionNumber = key;
        NSIndexSet *videoClipIndexSet = obj;
        [videos[sectionNumber.integerValue] removeObjectsAtIndexes:videoClipIndexSet];
        if ( [videos[sectionNumber.integerValue] count] == 0 )
        {
            [sectionSetToDelete addIndex:sectionNumber.integerValue];
        }
    }];
    [videos removeObjectsAtIndexes:sectionSetToDelete];
    
    //
    // delete rows from video table view.
    //
    if ( self.isEditable )
    {
        [self.ownerViewController.videoTableView beginUpdates];
        if ( sectionSetToDelete.count > 0 )
        {
            [self.ownerViewController.videoTableView deleteSections:sectionSetToDelete withRowAnimation:UITableViewRowAnimationNone];
        }
        [self.ownerViewController.videoTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.ownerViewController.videoTableView endUpdates];
    }
    [self.videoTableView beginUpdates];
    if ( sectionSetToDelete.count > 0 )
    {
        [self.videoTableView deleteSections:sectionSetToDelete withRowAnimation:UITableViewRowAnimationNone];
    }
    [self.videoTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.videoTableView endUpdates];
    
    [self updateToolbarButtonItemsState];
}

- (void)starVideoClipAtIndexPath:(NSIndexPath *)indexPath
{
    [self starVideoClipsAtIndexPaths:@[indexPath]];
}

- (void)starVideoClipsAtIndexPaths:(NSArray *)indexPaths
{
    if ( self.type != kCarDVRVideoBrowserViewControllerTypeRecents )
    {
        return;
    }
    NSMutableArray *videos = self.isEditable ? self.ownerViewController.videos : self.videos;
    //
    // mark video clips that will be starred.
    //
    NSMutableDictionary *videosToMove = [NSMutableDictionary dictionary];
    for ( NSIndexPath *indexPath in indexPaths )
    {
        CarDVRVideoItem *videoItem = [videos[indexPath.section] objectAtIndex:indexPath.row];
        NSError *error;
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        CarDVRVideoClipURLs *starredURLs = [[CarDVRVideoClipURLs alloc] initWithFolderURL:self.pathHelper.starredFolderURL
                                                                                 clipName:videoItem.videoClipURLs.clipName];
        [defaultManager moveItemAtURL:videoItem.videoClipURLs.videoFileURL
                                toURL:starredURLs.videoFileURL
                                error:&error];
#ifdef DEBUG
        if ( error )
        {
            NSLog( @"[Error]failed to move '%@' to '%@':\n%@",
                  videoItem.videoClipURLs.videoFileURL, starredURLs.videoFileURL, error.description );
        }
#endif
        [defaultManager moveItemAtURL:videoItem.videoClipURLs.srtFileURL
                                toURL:starredURLs.srtFileURL
                                error:&error];
#ifdef DEBUG
        if ( error )
        {
            NSLog( @"[Error]failed to move '%@' to '%@':\n%@",
                  videoItem.videoClipURLs.srtFileURL, starredURLs.srtFileURL, error.description );
        }
#endif
        [defaultManager moveItemAtURL:videoItem.videoClipURLs.gpxFileURL
                                toURL:starredURLs.gpxFileURL
                                error:&error];
#ifdef DEBUG
        if ( error )
        {
            NSLog( @"[Error]failed to move '%@' to '%@':\n%@",
                  videoItem.videoClipURLs.gpxFileURL, starredURLs.gpxFileURL, error.description );
        }
#endif
        videoItem.videoClipURLs.folderURL = self.pathHelper.starredFolderURL;
        
        NSNumber *sectionNumber = [NSNumber numberWithInteger:indexPath.section];
        NSMutableIndexSet *videoClipIndexSet = [videosToMove objectForKey:sectionNumber];
        if ( !videoClipIndexSet )
        {
            videoClipIndexSet = [NSMutableIndexSet indexSet];
            [videosToMove setObject:videoClipIndexSet forKey:sectionNumber];
        }
        [videoClipIndexSet addIndex:indexPath.row];
        
        if ( self.isEditable )
        {
            [self.markedIndexes removeObject:indexPath];
        }
    }
    
    //
    // cache marked video clip objects for 'star' notification.
    //
    NSMutableArray *starredVideos = [NSMutableArray array];
    NSMutableIndexSet *sectionSetToDelete = [NSMutableIndexSet indexSet];
    [videosToMove enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSNumber *sectionNumber = key;
        NSIndexSet *videoClipIndexSet = obj;
        [starredVideos addObjectsFromArray:[videos[sectionNumber.integerValue] objectsAtIndexes:videoClipIndexSet]];
        [videos[sectionNumber.integerValue] removeObjectsAtIndexes:videoClipIndexSet];
        if ( [videos[sectionNumber.integerValue] count] == 0 )
        {
            [sectionSetToDelete addIndex:sectionNumber.integerValue];
        }
    }];
    [videos removeObjectsAtIndexes:sectionSetToDelete];
    
    //
    // delete rows from video table view.
    //
    if ( self.isEditable )
    {
        [self.ownerViewController.videoTableView beginUpdates];
        if ( sectionSetToDelete.count > 0 )
        {
            [self.ownerViewController.videoTableView deleteSections:sectionSetToDelete withRowAnimation:UITableViewRowAnimationNone];
        }
        [self.ownerViewController.videoTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.ownerViewController.videoTableView endUpdates];
    }
    [self.videoTableView beginUpdates];
    if ( sectionSetToDelete.count > 0 )
    {
        [self.videoTableView deleteSections:sectionSetToDelete withRowAnimation:UITableViewRowAnimationNone];
    }
    [self.videoTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self.videoTableView endUpdates];
    
    //
    // post 'star' notification
    //
    [[NSNotificationCenter defaultCenter] postNotificationName:kStarDidCompleteNotification
                                                        object:self
                                                      userInfo:@{kVideoItemsKey: starredVideos}];
    
    [self updateToolbarButtonItemsState];
}

- (NSMutableArray *)addStarredVideos:(NSArray *)starredVideos
{
    NSMutableArray *sortedVideos = [[NSMutableArray alloc] init];
    [sortedVideos addObjectsFromArray:starredVideos];
    for ( NSArray *videoGroup in self.videos )
    {
        [sortedVideos addObjectsFromArray:videoGroup];
    }
    [sortedVideos sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        CarDVRVideoItem *videoItem1 = (CarDVRVideoItem *)obj1;
        CarDVRVideoItem *videoItem2 = (CarDVRVideoItem *)obj2;
        return [videoItem1.creationDate compare:videoItem2.creationDate];
    }];
    
    NSMutableArray *newGroupedVideos = [[NSMutableArray alloc] init];
    
    NSDate *prevFileEndDate;
    NSMutableArray *videoGroup;
    for ( NSUInteger i = 0; i < sortedVideos.count; i++ )
    {
        CarDVRVideoItem *videoItem = [sortedVideos objectAtIndex:i];
        if ( prevFileEndDate )
        {
            NSComparisonResult comparisonResult = [videoItem.creationDate compare:prevFileEndDate];
            if ( comparisonResult == NSOrderedDescending )// later than prevFileEndDate
            {
                videoGroup = [NSMutableArray array];
                [newGroupedVideos insertObject:videoGroup atIndex:0];
            }
        }
        else
        {
            videoGroup = [NSMutableArray array];
            [newGroupedVideos insertObject:videoGroup atIndex:0];
        }
        [videoGroup addObject:videoItem];
        prevFileEndDate = [NSDate dateWithTimeInterval:videoItem.duration sinceDate:videoItem.creationDate];
    }
    return ( newGroupedVideos.count > 0 ? newGroupedVideos : nil );
}

- (void)addStarredVideosAsync:(NSArray *)starredVideos
{
    dispatch_async( dispatch_get_current_queue(), ^{
        if ( self.type == kCarDVRVideoBrowserViewControllerTypeStarred )
        {
            self.videos = [self addStarredVideos:starredVideos];
            [self.videoTableView reloadData];
        }
    });
}

- (void)updateToolbarButtonItemsState
{
    if ( self.isEditable )
    {
        self.deleteButtonItem.enabled = self.markedIndexes.count > 0;
        if ( self.type == kCarDVRVideoBrowserViewControllerTypeRecents )
        {
            self.starButtonItem.enabled = self.deleteButtonItem.enabled;
        }
        else
        {
            self.starButtonItem.enabled = NO;
        }
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

- (void)handleLoadDidCompleteNotification
{
    [self.videoTableView reloadData];
}

- (void)handleStarDidCompleteNotification:(NSNotification *)notification
{
    if ( self.type != kCarDVRVideoBrowserViewControllerTypeStarred )
    {
        NSAssert1( NO, @"[Error]Wrong type (%d) for handleStarDidCompleteNotification", (NSInteger)self.type );
        return;
    }
    if ( self.isEditable )
    {
        NSAssert( NO, @"[Error]handleStarDidCompleteNotification should NOT run under 'editable' mode" );
        return;
    }
    NSArray *starredVideos = [notification.userInfo objectForKey:kVideoItemsKey];
    if ( starredVideos.count == 0 )
    {
        return;
    }
    
    [self addStarredVideosAsync:starredVideos];
}

@end
