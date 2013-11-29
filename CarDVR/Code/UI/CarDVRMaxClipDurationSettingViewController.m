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

@end

@implementation CarDVRMaxClipDurationSettingViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
