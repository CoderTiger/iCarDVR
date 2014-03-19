//
//  CarDVRTracksMapView.m
//  CarDVR
//
//  Created by yxd on 14-3-17.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import "CarDVRTracksLayerView.h"
#import "CarDVRVideoItem.h"
#import "CarDVRLocation.h"

static const CGFloat kPolylineWidth = 4.0f;

@interface CarDVRInternalTracksLayerView : UIView

@property (weak, nonatomic) MKMapView *mapView;
@property (weak, nonatomic) CarDVRVideoItem *videoItem;

- (void)mapViewRegionChanged;

@end

@implementation CarDVRInternalTracksLayerView

- (id)init
{
    self = [super init];
    if ( self )
    {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)mapViewRegionChanged
{
    self.frame = CGRectMake( -kPolylineWidth,
                            -kPolylineWidth,
                            _mapView.frame.size.width + kPolylineWidth * 2,
                            _mapView.frame.size.height + kPolylineWidth * 2 );
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    NSArray *locations = self.videoItem.locations;
	if ( locations && locations.count > 0)
	{
		CGContextRef context = UIGraphicsGetCurrentContext();
		CGContextSetStrokeColorWithColor( context, [UIColor blueColor].CGColor );
		CGContextSetRGBFillColor( context, 0.0, 0.0, 1.0, 1.0 );
		CGContextSetAlpha( context, 0.5 );
        CGContextSetLineCap( context, kCGLineCapRound );
		
		CGContextSetLineWidth( context, kPolylineWidth );
		
		for ( int i = 0; i < locations.count; i++ )
        {
			CarDVRLocation* location = [locations objectAtIndex:i];
			CGPoint point = [self.mapView convertCoordinate:CLLocationCoordinate2DMake( location.latitude, location.longitude )
                                              toPointToView:self];
			
			if ( i == 0 )
				CGContextMoveToPoint( context, point.x, point.y );
			else
				CGContextAddLineToPoint( context, point.x, point.y );
		}
		
		CGContextStrokePath( context );
	}
}

@end

@interface CarDVRTracksLayerView ()

@property (weak, nonatomic) CarDVRInternalTracksLayerView *internalTracksLayerView;

@end

@implementation CarDVRTracksLayerView

- (void)setMapView:(MKMapView *)mapView
{
    if ( _mapView != mapView )
    {
        _mapView = mapView;
        CarDVRInternalTracksLayerView *internalTracksLayerView = [[CarDVRInternalTracksLayerView alloc] init];
        internalTracksLayerView.mapView = _mapView;
        internalTracksLayerView.videoItem = _videoItem;
        [_mapView addSubview:internalTracksLayerView];
        internalTracksLayerView.frame = CGRectMake( -kPolylineWidth,
                                                   -kPolylineWidth,
                                                   _mapView.frame.size.width + kPolylineWidth * 2,
                                                   _mapView.frame.size.height + kPolylineWidth * 2 );
        _internalTracksLayerView = internalTracksLayerView;
    }
}

- (void)setVideoItem:(CarDVRVideoItem *)videoItem
{
    if ( _videoItem != videoItem )
    {
        _videoItem = videoItem;
        _internalTracksLayerView.videoItem = videoItem;
    }
}

- (void)mapViewRegionChanged
{
    [self.internalTracksLayerView mapViewRegionChanged];
}

- (CGPoint)centerOffset
{
    // REMARKS: derived from MKAnnotationView,
    // HACK here to reposition and redraw tracks when scaling or moving map view.
    [self.internalTracksLayerView mapViewRegionChanged];
    return [super centerOffset];
}

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if ( self )
    {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        self.userInteractionEnabled = NO;
    }
    return self;
}

@end
