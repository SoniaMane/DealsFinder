//
//  DateChangeListener.h
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 25/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

@protocol DateChangeListener <NSObject>
- (void) onCancelButtonPressed;
- (void) onDoneButtonPressed:(NSDate *) date forButton:(id) sender;
@end
