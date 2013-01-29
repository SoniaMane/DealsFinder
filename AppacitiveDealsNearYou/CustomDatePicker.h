//
//  CustomDatePicker.h
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 24/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//
#import "DateChangeListener.h"

@interface CustomDatePicker : UIView
- (id)initWithFrame:(CGRect)frame andSender:(id)sender;
- (void) setMinDate:(NSDate *)date;
@property (strong, nonatomic) id<DateChangeListener> delegate;
@end
