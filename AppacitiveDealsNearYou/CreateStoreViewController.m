
//
//  CreateStoreViewController.m
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 18/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//
#import "CreateStoreViewController.h"
#import "Store.h"
#import "StoreImage.h"
#import <QuartzCore/QuartzCore.h>
#import "CreateDealViewController.h"

@interface CreateStoreViewController () {
    CLLocationManager *locationManager;
    CLPlacemark *_placemark;
    dispatch_queue_t _saveStoreObject;
    NSString *_storeLocationCoord;
    NSString *_storeId;
    NSString *_storeLabel;
    __block AJNotificationView *_panel;
    UIImage *_cameraImageToBeUploaded;
    NSString *_uniqueAlphaNumericName;
}
@property (strong, nonatomic) Store *store;
@property (strong, nonatomic) CLGeocoder *geoCoder;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *clickPhotoForStoreOutlet;
@property (weak, nonatomic) IBOutlet UITextField *storeName;
@property (weak, nonatomic) IBOutlet UITextField *storeAddress;
@property (weak, nonatomic) IBOutlet UITextField *storePhoneNumber;
@property (weak, nonatomic) IBOutlet UIButton *fetchLocationText;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *finishedCreatingDealOutlet;
@property (strong, nonatomic) IBOutlet UIView *view;

- (IBAction)clickStorePhoto:(id)sender;
- (IBAction)fetchLocation:(id)sender;

@end

@implementation CreateStoreViewController
@synthesize delegate;

- (void)viewWillAppear:(BOOL)animated {
   _saveStoreObject = dispatch_queue_create("com.appacitive.saveStoreObject", DISPATCH_QUEUE_SERIAL);
    [[NSNotificationCenter defaultCenter] addObserver:self
          selector:@selector(keyboardWillHide:)
          name:UIKeyboardWillHideNotification
          object:self.view.window];
}
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)isStoreObjectValid {
    BOOL isValid = YES;
    struct CGColor *redColor = [[UIColor redColor] CGColor];
    struct CGColor *clearColor = [[UIColor clearColor] CGColor];
    CGFloat borderWidth = 1.0f;
    
    for (int i = 1; i <= 3; i++) {
        UITextField *textField = (UITextField*)[self.view viewWithTag:i];
        if (textField != nil) {
            if ([textField.text isEqualToString:@""]) {
                textField.layer.borderColor = redColor;
                textField.layer.borderWidth = borderWidth;
                textField.layer.cornerRadius = 8.0f;
                textField.layer.masksToBounds = YES;
                isValid = NO;
            } else {
                textField.layer.borderColor = clearColor;
            }
        }
    }
    
    if ([_clickPhotoForStoreOutlet imageForState:UIControlStateNormal] == nil) {
        _clickPhotoForStoreOutlet.layer.borderColor = redColor;
        isValid = NO;
    } else {
        _clickPhotoForStoreOutlet.layer.borderColor = clearColor;
    }
    
    if ([[_fetchLocationText titleLabel].text isEqualToString:@"Fetch Location"]) {
        _fetchLocationText.layer.borderColor = redColor;
        isValid = NO;
    } else {
        _fetchLocationText.layer.borderColor = clearColor;
    }
    if (!isValid) {
        _panel = [AJNotificationView showNoticeInView:self.view
            type:AJNotificationTypeRed
            title:@"Fill the missing fields!"
            linedBackground:AJLinedBackgroundTypeAnimated
            hideAfter:0 response:^{}];
        if (_panel) {
            [_panel hide];
        }

      }
    return isValid;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    CFUUIDRef newUniqueID = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef newUniqueIDString = CFUUIDCreateString(kCFAllocatorDefault, newUniqueID);
    NSString *key = (__bridge NSString *)newUniqueIDString;
    _uniqueAlphaNumericName = [key stringByReplacingOccurrencesOfString:@"-" withString:@""];
    [_store setStoreImageKey:key];
    [[StoreImage sharedInstance] setImage:image forKey:key];
    CFRelease(newUniqueIDString);
    CFRelease(newUniqueID);
    _cameraImageToBeUploaded = image;
    [_clickPhotoForStoreOutlet setImage:image forState:UIControlStateNormal];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma textField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _storeName) {
        [_storeAddress becomeFirstResponder];
    } else if (textField == _storeAddress) {
        [_storePhoneNumber becomeFirstResponder];
    } else if (textField == _storePhoneNumber) {
        [_storePhoneNumber resignFirstResponder];
        [_scrollView setContentOffset:CGPointMake(0, 50) animated:YES];
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    CGRect navframe = [[self.navigationController navigationBar] frame];
    [_scrollView setContentOffset:CGPointMake(0, _storeName.frame.origin.y - navframe.size.height) animated:YES];
    struct CGColor *clearColor = [[UIColor clearColor] CGColor];
    textField.layer.borderColor = clearColor;
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_scrollView setContentOffset:CGPointMake(0, 50) animated:YES];
}

- (void)keyboardWillHide:(NSNotification*) notification {
    [_scrollView setContentOffset:CGPointMake(0, 50) animated:YES];
}

- (void) doneNumPadButton:(id) sender {
    [_storePhoneNumber resignFirstResponder];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
   _panel = [AJNotificationView showNoticeInView:self.view
        type:AJNotificationTypeRed
        title:@"Location service unavailable !"
        linedBackground:AJLinedBackgroundTypeAnimated
        hideAfter:2.5f response:^{}];
    if (_panel) {
        [_panel hide];
    }
}
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    CLLocation *currentLocation = newLocation;
    [locationManager stopUpdatingLocation];
    _geoCoder = [[CLGeocoder alloc] init];
    [_geoCoder reverseGeocodeLocation: currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (error == nil && [placemarks count] > 0) {
            _placemark = [placemarks lastObject];
            NSString *locatedAt = [NSString stringWithFormat:@"%@ %@",
                                 _placemark.locality,
                                 _placemark.country];
            [_fetchLocationText setTitle:locatedAt forState:UIControlStateNormal];
            NSString *lat = [[NSString alloc] initWithFormat:@"%g", newLocation.coordinate.latitude];
            NSString *lng = [[NSString alloc] initWithFormat:@"%g", newLocation.coordinate.longitude];
            _storeLocationCoord = [NSString stringWithFormat:@"%@, %@",lat, lng];
        } else {
           _panel = [AJNotificationView showNoticeInView:self.view
                type:AJNotificationTypeRed
                title:[NSString stringWithFormat:@"%@",[error debugDescription]]
                linedBackground:AJLinedBackgroundTypeAnimated
                hideAfter:2.5f response:^{}];
            if (_panel) {
                [_panel hide];
            }
        }
    }];
}

- (IBAction)clickStorePhoto:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
        NSLog(@"camera available");
    } else {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        NSLog(@"camera not available");
    }
    
    [imagePicker setDelegate:self];
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)fetchLocation:(id)sender {
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [locationManager startUpdatingLocation];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"CreateDealSegue"] && [self isStoreObjectValid]) {
        return YES;
    }
    return NO;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"CreateDealSegue"] &&  [self isStoreObjectValid]) {
        
        NSData *data = UIImagePNGRepresentation(_cameraImageToBeUploaded);
       
        NSLog(@"store====%@",_uniqueAlphaNumericName);
        [APFile uploadFileWithName:_uniqueAlphaNumericName data:data validUrlForTime:[NSNumber numberWithInt:10] contentType:@"image/png" successHandler:^(NSDictionary *result){
            _panel = [AJNotificationView showNoticeInView:self.view
                            type:AJNotificationTypeBlue
                            title:@"Saving store"
                            linedBackground:AJLinedBackgroundTypeAnimated
                            hideAfter:2.5f response:^{}];
            if (_panel) {
                [_panel hide];
            }

            NSLog(@"image upload data is %@", result);
            NSString *fileName = [result objectForKey:@"id"];
            NSLog(@"The id is %@", fileName);
            
            dispatch_async(_saveStoreObject, ^(){
                if (self.isStoreObjectValid) {
                    _store = [[Store alloc] init];
                    _store.storeName = _storeName.text;
                    _store.storeAddress = _storeAddress.text;
                    _store.storePhone = _storePhoneNumber.text;
                    _store.storeLocation = _storeLocationCoord;
                    
                    APObject *storeObject = [APObject objectWithSchemaName:@"store"];
                    [storeObject addPropertyWithKey:@"name" value:_store.storeName];
                    [storeObject addPropertyWithKey:@"address" value:_store.storeAddress];
                    [storeObject addPropertyWithKey:@"location" value:_store.storeLocation];
                    [storeObject addPropertyWithKey:@"photo" value:fileName];
                    [storeObject addPropertyWithKey:@"phone" value:_store.storePhone];
                    
                    [storeObject saveObjectWithSuccessHandler:^(NSDictionary *dict) {
                        
                        NSDictionary *storedict = dict[@"article"];
                        _store.objectId = [storedict objectForKey:@"__id"];
                        _store.storeLabel = [storedict objectForKey:@"__schematype"];
                        APConnection *connectionOwner = [APConnection connectionWithRelationType:@"owner"];
                        APUser *user = [APUser currentUser];
                        NSLog(@"%@", user.objectId);
                        [connectionOwner createConnectionWithObjectAId:user.objectId objectBId:storeObject.objectId labelA:@"user" labelB:@"store" successHandler:^(){
                            
                            dispatch_async(dispatch_get_main_queue(), ^(){
                                [delegate notifyStoreDatasourceChanged:_store];
                                CreateDealViewController *createDealViewController = [segue destinationViewController];
                                [createDealViewController setEndPointA:_store];
                                _panel = [AJNotificationView showNoticeInView:self.view
                                                                         type:AJNotificationTypeGreen
                                                                        title:@"Store saved"
                                                              linedBackground:AJLinedBackgroundTypeAnimated
                                                                    hideAfter:2.5f response:^{}];
                            });
                            if (_panel) {
                                [_panel hide];
                            }
                            
                        } failureHandler:^(APError *error){
                            _panel = [AJNotificationView showNoticeInView:self.view
                                                                     type:AJNotificationTypeRed
                                                                    title:@"Error in saving store!"
                                                          linedBackground:AJLinedBackgroundTypeAnimated
                                                                hideAfter:2.5f response:^{}];
                            if (_panel) {
                                [_panel hide];
                            }
                        }];
                    } failureHandler:^(APError *error){
                        _panel = [AJNotificationView showNoticeInView:self.view
                                                                 type:AJNotificationTypeRed
                                                                title:@"Error in saving store!"
                                                      linedBackground:AJLinedBackgroundTypeAnimated
                                                            hideAfter:2.5f response:^{}];
                        if (_panel) {
                            [_panel hide];
                        }
                    }];
                } //end of if
            });//end of dispatch asyn
        }
        failureHandler:^(APError *error){
            NSLog(@"upload %@", [error description]);
        }];
    }
}

@end
