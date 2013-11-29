//
//  CarDVRMaxClipDurationSettingViewController.m
//  CarDVR
//
//  Created by yxd on 13-11-29.
//  Copyright (c) 2013年 iautod. All rights reserved.
//

#import "CarDVRMaxClipDurationSettingViewController.h"

static const NSUInteger kMinDuration = 15;// 15 seconds
static const NSUInteger kMinSecondsDuration = 0;
static const NSUInteger kMaxSecondsDuration = 59;
static const NSUInteger kMinMinutesDuration = 0;
static const NSUInteger kMaxMinutesDuration = 30;

@interface CarDVRMaxClipDurationSettingViewController ()<UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIPickerView *minutesPickerView;
@property (weak, nonatomic) IBOutlet UIPickerView *secondsPickerView;

@end

@implementation CarDVRMaxClipDurationSettingViewController

- (void)setMaxClipDuration:(NSUInteger)maxClipDuration
{
    if ( maxClipDuration < kMinDuration )
    {
        maxClipDuration = kMinDuration;
    }
    else if ( maxClipDuration > ( kMaxMinutesDuration * 60 + kMaxSecondsDuration ) )
    {
        maxClipDuration = kMaxSecondsDuration * 60 + kMaxSecondsDuration;
    }
    _maxClipDuration = maxClipDuration;
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
    // Do any additional setup after loading the view.
    self.title = NSLocalizedString( @"maxClipDurationSettingViewTitle", @"Max Clip Duration" );
    NSUInteger minutes = self.maxClipDuration / 60;
    NSUInteger seconds = self.maxClipDuration % 60;
    [self.minutesPickerView selectRow:minutes inComponent:0 animated:NO];
    [self.secondsPickerView selectRow:seconds inComponent:0 animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
#pragma unused( animated )
    NSUInteger maxClipDuration =
    [self.minutesPickerView selectedRowInComponent:0] * 60 + [self.secondsPickerView selectedRowInComponent:0];
    self.maxClipDuration = maxClipDuration;
    [self.delegate maxClipDurationSettingViewControllerDone:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - from UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
#pragma unused( pickerView )
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
#pragma unused( component )
    NSAssert( component == 0, @"There SHOULD be one single component." );
    if ( pickerView == self.minutesPickerView )
    {
        return ( kMaxMinutesDuration - kMinMinutesDuration + 1 );
    }
    if ( pickerView == self.secondsPickerView )
    {
        return ( kMaxSecondsDuration - kMinSecondsDuration + 1 );
    }
    return 0;
}

#pragma mark - from UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
#pragma unused( component )
    NSAssert( component == 0, @"There SHOULD be one single component." );
    if ( pickerView == self.minutesPickerView )
    {
        if ( row < 2 )
        {
            return [NSString stringWithFormat:NSLocalizedString( @"minuteDuration", nil), row];
        }
        return [NSString stringWithFormat:NSLocalizedString( @"minutesDuration", nil), row];
    }
    if ( pickerView == self.secondsPickerView )
    {
        if ( row < 2 )
        {
            return [NSString stringWithFormat:NSLocalizedString( @"secondDuration", nil), row];
        }
        return [NSString stringWithFormat:NSLocalizedString( @"secondsDuration", nil), row];
    }
    return nil;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
#pragma unused( pickerView, row, component )
    if ( ( [self.minutesPickerView selectedRowInComponent:0] == kMinMinutesDuration )
        && ( [self.secondsPickerView selectedRowInComponent:0] < kMinDuration ) )
    {
        [self.secondsPickerView selectRow:kMinDuration inComponent:0 animated:YES];
    }
}

@end
