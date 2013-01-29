//
//  CreateDealViewController.h
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 18/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "DateChangeListener.h"
@class Store;
@interface CreateDealViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, CLLocationManagerDelegate, DateChangeListener>
- (void) setEndPointA:(Store *) store;
@end
