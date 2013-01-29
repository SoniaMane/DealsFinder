//
//  CreateStoreViewController.h
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 18/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "StoreListProtocol.h"

@interface CreateStoreViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, CLLocationManagerDelegate>
@property (strong, nonatomic) id<StoreListProtocol> delegate;
@end
