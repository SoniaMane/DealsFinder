//
//  CustomDatePicker.m
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 24/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "CustomDatePicker.h"

@interface CustomDatePicker() {
    UIDatePicker * _picker;
    UIView *_backgroundBar;
    id _sender;
    NSDate *_startDate;
}

@end

@implementation CustomDatePicker
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame andSender:(id)sender
{
    self = [super initWithFrame:frame];
    if (self) {
        _sender = sender;
        [self initializeSubviews];
    }
    return self;
}
- (void) setMinDate:(NSDate *)date {
    [_picker setMinimumDate:date];
}
- (void) initializeSubviews {
    _picker = [[UIDatePicker alloc] init];
    _picker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _picker.datePickerMode = UIDatePickerModeDate;
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *currentDate = [NSDate date];
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:0];
    NSDate *minDate = [gregorian dateByAddingComponents:comps toDate:currentDate  options:0];
    
    UIButton *button = (UIButton *)_sender;
    if (button.tag  == 1) {
     _picker.minimumDate = minDate;
    } else if (button.tag == 2) {
        _picker.minimumDate = minDate;
    }
    
    CGSize pickerSize = [_picker sizeThatFits:CGSizeZero];
    _picker.frame = CGRectMake(0, 250, pickerSize.width, pickerSize.height);
    [self addSubview:_picker];
    UIToolbar* numberToolbar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, 320, 50)];
    numberToolbar.barStyle = UIBarStyleBlackTranslucent;
    numberToolbar.items = [NSArray arrayWithObjects:
    [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelDatePickerView)],
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
    [[UIBarButtonItem alloc]initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(doneWithDatePickerView)],
                           nil];
    [numberToolbar sizeToFit];
    _backgroundBar = [[UIView alloc] initWithFrame:CGRectMake(0, _picker.frame.origin.y - 40, self.frame.size.width, 50)];
    [_backgroundBar addSubview:numberToolbar];    
    [self addSubview:_backgroundBar];
}

-(void)cancelDatePickerView {
    [delegate onCancelButtonPressed];
}

-(void)doneWithDatePickerView {
    NSDate *date = _picker.date;
    [delegate onDoneButtonPressed:date forButton:_sender];
}


@end
