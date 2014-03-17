//
//  CarDVRMapAnnotationView.m
//  CarDVR
//
//  Created by yxd on 14-3-13.
//  Copyright (c) 2014年 iautod. All rights reserved.
//

#import "CarDVRMapAnnotationView.h"
#import "CarDVRVideoItem.h"
#import "CarDVRLocation.h"

static const CGFloat kPolylineWidth = 3.0f;

@interface CarDVRInternalMapAnnotationView: UIView

@property (weak, nonatomic) CarDVRVideoItem *videoItem;
@property (weak, nonatomic) MKMapView *mapView;

- (id)initWithMapView:(MKMapView *)mapView videoItem:(CarDVRVideoItem *)videoItem;

@end

@implementation CarDVRInternalMapAnnotationView

- (id)initWithMapView:(MKMapView *)mapView videoItem:(CarDVRVideoItem *)videoItem
{
    self = [super init];
    if ( self )
    {
        _mapView = mapView;
        _videoItem = videoItem;
        
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
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
			CGPoint point = [_mapView convertCoordinate:CLLocationCoordinate2DMake( location.latitude, location.longitude )
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

@interface CarDVRMapAnnotationView()

@property (weak, nonatomic) CarDVRVideoItem *videoItem;
@property (weak, nonatomic) MKMapView *mapView;
@property (strong, nonatomic) CarDVRInternalMapAnnotationView *internalView;

#pragma mark - Private methods
- (void)regineChanged;

@end

@implementation CarDVRMapAnnotationView

- (id)initWithMapView:(MKMapView *)mapView videoItem:(CarDVRVideoItem *)videoItem
{
    self = [super init];
    if ( self )
    {
        _videoItem = videoItem;
        _mapView = mapView;
        _internalView = [[CarDVRInternalMapAnnotationView alloc] initWithMapView:_mapView videoItem:videoItem];
        [self addSubview:_internalView];
        
        self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = NO;
		self.frame = CGRectMake(0.0, 0.0, _mapView.frame.size.width, _mapView.frame.size.height);
    }
    return self;
}

- (CGPoint)centerOffset
{
    // HACK: use the method to get the centerOffset (called by the main mapview)
	// to reposition our annotation subview in response to zoom and motion
	// events
    [self regineChanged];
    return [super centerOffset];
}

#pragma mark - Private methods
- (void)regineChanged
{
	CGPoint minPoint, maxPoint;
	for ( int i = 0; i < self.videoItem.locations.count; i++ )
	{
		CarDVRLocation* location = [self.videoItem.locations objectAtIndex:i];
        CGPoint point = [_mapView convertCoordinate:CLLocationCoordinate2DMake(location.latitude, location.longitude)
                                      toPointToView:self.mapView];
		if ( point.x < minPoint.x || i == 0 )
			minPoint.x = point.x;
		if ( point.y < minPoint.y || i == 0 )
			minPoint.y = point.y;
		if ( point.x > maxPoint.x || i == 0 )
			maxPoint.x = point.x;
		if ( point.y > maxPoint.y || i == 0 )
			maxPoint.y = point.y;
	}
	
	CGFloat width = maxPoint.x - minPoint.x + ( 2 * kPolylineWidth );
	CGFloat height = maxPoint.y - minPoint.y + ( 2 * kPolylineWidth );
	
	_internalView.frame = CGRectMake( minPoint.x - kPolylineWidth, minPoint.y - kPolylineWidth,
									 width, height );
	[_internalView setNeedsDisplay];
}

@end
