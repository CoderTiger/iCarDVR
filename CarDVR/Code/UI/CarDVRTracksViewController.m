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

@interface CarDVRTracksViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mapTypeSegmentedControl;

@property (readonly, nonatomic) MKMapType mapType;
@property (readonly, nonatomic) NSInteger selectedMapTypeSegmentIndex;

- (IBAction)selectedMapTypeChanged:(id)sender;

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
@end
