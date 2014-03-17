//
//  CarDVRTracksViewController.m
//  CarDVR
//
//  Created by yxd on 14-3-12.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import "CarDVRTracksViewController.h"
#import <MapKit/MapKit.h>
#import "CarDVRSettings.h"
#import "CarDVRVideoItem.h"
#import "CarDVRLocation.h"
#import "CarDVRAnnotation.h"
#import "CarDVRTracksOverlay.h"
#import "CarDVRTracksLayerView.h"

@interface CarDVRTracksViewController ()<MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mapTypeSegmentedControl;

@property (readonly, nonatomic) MKMapType mapType;
@property (readonly, nonatomic) NSInteger selectedMapTypeSegmentIndex;

- (IBAction)selectedMapTypeChanged:(id)sender;

#pragma mark - Private methods
- (void)centerMap;

@end

@implementation CarDVRTracksViewController

@synthesize mapType = _mapType;
@synthesize selectedMapTypeSegmentIndex = _selectedMapTypeSegmentIndex;

- (MKMapType)mapType
{
    NSInteger tracksMapTypeValue = self.settings.tracksMapType.integerValue;
    switch ( tracksMapTypeValue )
    {
        case kCarDVRMapTypeStandard:
            return MKMapTypeStandard;
        case kCarDVRMapTypeSatellite:
            return MKMapTypeSatellite;
        case kCarDVRMapTypeHybrid:
            return MKMapTypeHybrid;
        default:
            break;
    }
    return MKMapTypeStandard;
}

- (NSInteger)selectedMapTypeSegmentIndex
{
    NSInteger tracksMapTypeValue = self.settings.tracksMapType.integerValue;
    switch ( tracksMapTypeValue )
    {
        case kCarDVRMapTypeStandard:
            return 0;
        case kCarDVRMapTypeSatellite:
            return 1;
        case kCarDVRMapTypeHybrid:
            return 2;
        default:
            break;
    }
    return 0;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString( @"tracksViewTitle", nil );
    self.mapView.mapType = self.mapType;
    self.mapTypeSegmentedControl.selectedSegmentIndex = self.selectedMapTypeSegmentIndex;
    
    // Prevent sub views from being covered by navigation bar
    self.navigationController.navigationBar.translucent = NO;
    if ( [self respondsToSelector:@selector( edgesForExtendedLayout )] )
        self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
    
    [self.mapTypeSegmentedControl setTitle:NSLocalizedString( @"stadardMapTypeName", nil ) forSegmentAtIndex:0];
    [self.mapTypeSegmentedControl setTitle:NSLocalizedString( @"satelliteMapTypeName", nil ) forSegmentAtIndex:1];
    [self.mapTypeSegmentedControl setTitle:NSLocalizedString( @"hybridMapTypeName", nil ) forSegmentAtIndex:2];
    
    [self centerMap];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)selectedMapTypeChanged:(id)sender
{
#pragma unused( sender )
    switch ( self.mapTypeSegmentedControl.selectedSegmentIndex )
    {
        case 0:
            self.mapView.mapType = MKMapTypeStandard;
            self.settings.tracksMapType = [NSNumber numberWithInteger:kCarDVRMapTypeStandard];
            break;
        case 1:
            self.mapView.mapType = MKMapTypeSatellite;
            self.settings.tracksMapType = [NSNumber numberWithInteger:kCarDVRMapTypeSatellite];
            break;
        case 2:
            self.mapView.mapType = MKMapTypeHybrid;
            self.settings.tracksMapType = [NSNumber numberWithInteger:kCarDVRMapTypeHybrid];
            break;
        default:
            NSAssert1( NO, @"[Error]unsupported map type index: %d", self.mapTypeSegmentedControl.selectedSegmentIndex );
            break;
    }
}

#pragma mark - from MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ( [annotation isKindOfClass:[CarDVRTracksOverlay class]] )
    {
        CarDVRTracksLayerView *tracksLayerView =
            (CarDVRTracksLayerView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"CarDVRTracksLayerView"];
        if ( !tracksLayerView )
        {
            tracksLayerView = [[CarDVRTracksLayerView alloc] initWithAnnotation:annotation
                                                                reuseIdentifier:@"CarDVRTracksLayerView"];
        }
        tracksLayerView.mapView = self.mapView;
        tracksLayerView.videoItem = self.videoItem;
        return tracksLayerView;
    }
    return nil;
}

#pragma mark - Private methods
- (void)centerMap
{
    NSUInteger locationCount = self.videoItem.locations.count;
    if ( !locationCount )
    {
        return;
    }
    CLLocationDegrees maxLat = -90.0f;
    CLLocationDegrees minLat = 90.0f;
	CLLocationDegrees maxLon = -180.0f;
	CLLocationDegrees minLon = 180.0f;
    for ( NSInteger idx = 0; idx < locationCount; idx++ )
    {
        CarDVRLocation *location = self.videoItem.locations[idx];
        if ( location.latitude > maxLat )
            maxLat = location.latitude;
        if ( location.latitude < minLat )
            minLat = location.latitude;
        if ( location.longitude > maxLon )
            maxLon = location.longitude;
        if ( location.longitude < minLon )
            minLon = location.longitude;
    }
    MKCoordinateRegion region;
    region.center.latitude = ( maxLat + minLat ) / 2;
	region.center.longitude = ( maxLon + minLon ) / 2;
	region.span.latitudeDelta = ( maxLat - minLat ) * 1.2;
	region.span.longitudeDelta = ( maxLon - minLon ) * 1.2;
    [self.mapView setRegion:region animated:YES];
    
    CarDVRAnnotation *startAnnotation = [[CarDVRAnnotation alloc] initWithLocation:self.videoItem.locations[0]
                                                                                title:NSLocalizedString( @"startAnnotation", nil )];
    [self.mapView addAnnotation:startAnnotation];
    if ( locationCount > 1 )
    {
        CarDVRAnnotation *endAnnotation = [[CarDVRAnnotation alloc] initWithLocation:[self.videoItem.locations lastObject]
                                                                               title:NSLocalizedString( @"endAnnotation", nil )];
        [self.mapView addAnnotation:endAnnotation];
    }
    
    // TODO: try to drow tracks with overlay manner
    CarDVRTracksOverlay *tracksOverlay = [[CarDVRTracksOverlay alloc] initWithVideoItem:self.videoItem];
//    [self.mapView addOverlay:tracksOverlay];
    [self.mapView addAnnotation:tracksOverlay];
}

@end
