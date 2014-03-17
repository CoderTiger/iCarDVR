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

@implementation CarDVRTracksLayerView

- (void)setMapView:(MKMapView *)mapView
{
    if ( _mapView != mapView )
    {
        _mapView = mapView;
        self.frame = CGRectMake( 0, 0, _mapView.frame.size.width, _mapView.frame.size.height );
    }
}

- (CGPoint)centerOffset
{
    // REMARKS: derived from MKAnnotationView,
    // HACK here to redraw tracks when scaling or moving map view.
    [self setNeedsDisplay];
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

- (id)initWithMapView:(MKMapView *)mapView videoItem:(CarDVRVideoItem *)videoItem
{
    self = [super initWithFrame:CGRectMake( 0, 0, mapView.frame.size.width, mapView.frame.size.height )];
    if ( self )
    {
        _mapView = mapView;
        _videoItem = videoItem;
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        self.userInteractionEnabled = NO;
        [_mapView addSubview:self];
    }
    return self;
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
