//
//  CreateDealViewController.m
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 18/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "CreateDealViewController.h"
#import "Deal.h"
#import "StoreImage.h"
#import "CustomDatePicker.h"
#import <QuartzCore/QuartzCore.h>
#import "Store.h"

@interface CreateDealViewController () {
    CLLocationManager *_locationManager;
    CLPlacemark *_placemark;
    dispatch_queue_t _saveDealObject;
    NSString *_startDateString;
    NSString *_endDateString;
    NSString *_dealLocationCoord;
    CustomDatePicker *_customPicker;
    NSDate *_startDate;
}
@property (strong, nonatomic) Store *store;
@property (strong, nonatomic) CLGeocoder *geoCoder;
@property (weak, nonatomic) Deal *deal;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *dealNameText;
@property (weak, nonatomic) IBOutlet UITextField *dealDescriptionText;
@property (weak, nonatomic) IBOutlet UIButton *getStartDateOutlet;
@property (weak, nonatomic) IBOutlet UIButton *getEndDateOutlet;
@property (weak, nonatomic) IBOutlet UIButton *clickDealOutlet;
@property (weak, nonatomic) IBOutlet UIButton *locationLabel;
- (IBAction)clickDealPhoto:(id)sender;
- (IBAction)fetchCurrentLocation:(id)sender;
- (IBAction)getDealStartDate:(id)sender;
- (IBAction)getDealEndDate:(id)sender;
- (IBAction)doneWithDeal:(id)sender;
@end

@implementation CreateDealViewController

- (void) setEndPointA:(Store *) store{
    _store = store;
}

- (void) viewWillAppear:(BOOL)animated {
    _saveDealObject = dispatch_queue_create("com.appacitive.saveDealObject", DISPATCH_QUEUE_SERIAL);
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(keyboardWillHide:)
        name:UIKeyboardWillHideNotification
        object:self.view.window];
}
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)clickDealPhoto:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypeCamera];
    } else {
        [imagePicker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }
    [imagePicker setDelegate:self];
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)fetchCurrentLocation:(id)sender {
    [_dealDescriptionText resignFirstResponder];
    [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    _locationManager = [[CLLocationManager alloc] init];
    [_locationManager setDelegate:self];
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [_locationManager startUpdatingLocation];
}

- (IBAction)getDealStartDate:(id)sender {
    [_scrollView setContentOffset:CGPointMake(0, _dealNameText.frame.origin.y) animated:YES];    
    _customPicker = [[CustomDatePicker alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 420) andSender:sender];
    _customPicker.delegate = self;
    [self.view addSubview:_customPicker];
}

- (IBAction)getDealEndDate:(id)sender {
    [_scrollView setContentOffset:CGPointMake(0, _dealNameText.frame.origin.y) animated:YES];
    if (_startDate != nil) {
        _customPicker = [[CustomDatePicker alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 420) andSender:sender];
        [_customPicker setMinDate:_startDate];
        _customPicker.delegate = self;
    } else {
        
    }
        [self.view addSubview:_customPicker];
}

- (IBAction)doneWithDeal:(id)sender {
    if ([self isDealObjectValid]) {
        [AJNotificationView showNoticeInView:self.view
            type:AJNotificationTypeBlue
            title:@"Saving deal"
            linedBackground:AJLinedBackgroundTypeAnimated
            hideAfter:10.5f response:^{}];
        dispatch_async(_saveDealObject, ^() {
            if ([self isDealObjectValid]) {
                APObject *objectB = [APObject objectWithSchemaName:@"deal"];
                [objectB addPropertyWithKey:@"title" value:_dealNameText.text];
                // [objectB addPropertyWithKey:@"photo" value:_imageCaptured];
                [objectB addPropertyWithKey:@"startdate" value:_startDateString];
                [objectB addPropertyWithKey:@"enddate" value:_endDateString];
                [objectB addPropertyWithKey:@"description" value:_dealDescriptionText.text];
                [objectB addPropertyWithKey:@"location" value:_dealLocationCoord];
                
                [objectB saveObjectWithSuccessHandler:^(NSDictionary *result){
                    NSDictionary *dealDictionary = [result objectForKey:@"article"];
                    NSString *dealBId = [dealDictionary objectForKey:@"__id"];
                    NSString *dealBLabel = [dealDictionary objectForKey:@"__schematype"];
                    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                    [formatter setNumberStyle:NSNumberFormatterNoStyle];
                    NSNumber *endPointBId = [formatter numberFromString:dealBId];
                    NSString *labelB = dealBLabel;
                    
                    formatter = [[NSNumberFormatter alloc] init];
                    [formatter setNumberStyle:NSNumberFormatterNoStyle];
                    NSNumber *endPointAId = [formatter numberFromString:_store.objectId];
                    NSString *labelA = _store.storeLabel;
                    APConnection *connection = [APConnection connectionWithRelationType:@"deals"];
                    [connection createConnectionWithObjectAId:endPointAId objectBId:endPointBId labelA:labelA labelB:labelB
                        successHandler:^(){
                    dispatch_async(dispatch_get_main_queue(), ^() {                                                       [AJNotificationView showNoticeInView:self.view
                            type:AJNotificationTypeGreen
                            title:@"Deal saved"
                            linedBackground:AJLinedBackgroundTypeAnimated
                            hideAfter:10.5f response:^{}];
                        [[self navigationController] popViewControllerAnimated:YES];
                                });
                        } failureHandler:^(APError *error){
                            [AJNotificationView showNoticeInView:self.view
                                type:AJNotificationTypeRed
                                title:@"Error in saving deal!"
                                linedBackground:AJLinedBackgroundTypeAnimated
                                hideAfter:10.5f response:^{}];
                        }];
                } failureHandler:^(APError *error){
                    [AJNotificationView showNoticeInView:self.view
                        type:AJNotificationTypeRed
                        title:@"Error in saving deal!"
                        linedBackground:AJLinedBackgroundTypeAnimated
                        hideAfter:10.5f response:^{}];
                }];
            }
        });
    }
}

#pragma mark - location manager methods

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    [AJNotificationView showNoticeInView:self.view
        type:AJNotificationTypeRed
        title:@"Location service unavailable !"
        linedBackground:AJLinedBackgroundTypeAnimated
        hideAfter:2.5f response:^{}];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    CLLocation *currentLocation = newLocation;
    [_locationManager stopUpdatingLocation];
    _geoCoder = [[CLGeocoder alloc] init];
    [_geoCoder reverseGeocodeLocation: currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error == nil && [placemarks count] > 0) {
            _placemark = [placemarks lastObject];
            NSString *locatedAt = [NSString stringWithFormat:@"%@ %@",
                                   _placemark.locality,
                                   _placemark.country];
            [_locationLabel setTitle:locatedAt forState:UIControlStateNormal];
            NSString *lat = [[NSString alloc] initWithFormat:@"%g", newLocation.coordinate.latitude];
            NSString *lng = [[NSString alloc] initWithFormat:@"%g", newLocation.coordinate.longitude];
            _dealLocationCoord = [NSString stringWithFormat:@"%@, %@",lat, lng];
            
        } else {
            [AJNotificationView showNoticeInView:self.view
                type:AJNotificationTypeRed
                title:@"Error in fetching current location !"
                linedBackground:AJLinedBackgroundTypeAnimated
                hideAfter:2.5f response:^{}];
        }
    }];
}

#pragma mark imagePicker method

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    CFUUIDRef newUniqueID = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef newUniqueIDString = CFUUIDCreateString(kCFAllocatorDefault, newUniqueID);
    NSString *key = (__bridge NSString *)newUniqueIDString;
    [_deal setDealImageKey:key];
    [[StoreImage sharedInstance] setImage:image forKey:key];
    CFRelease(newUniqueIDString);
    CFRelease(newUniqueID);
    [_clickDealOutlet setBackgroundImage: image forState:UIControlStateNormal];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark text field delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _dealNameText) {
        [_dealDescriptionText becomeFirstResponder];
    } else if (textField == _dealDescriptionText) {
        [_dealDescriptionText resignFirstResponder];
        [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [_scrollView setContentOffset:CGPointMake(0, _dealNameText.frame.origin.y) animated:YES];
    struct CGColor *clearColor = [[UIColor clearColor] CGColor];
    textField.layer.borderColor = clearColor;
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)keyboardWillHide:(NSNotification*) notification {
    [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
}

#pragma mark Date change listener methods

- (void) onCancelButtonPressed {
    [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    [_customPicker removeFromSuperview];
}

- (void) onDoneButtonPressed:(NSDate *)date forButton:(id)sender {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *displayDate = [formatter stringFromDate:date];
    
    UIButton *button = (UIButton *)sender;
    if (button.tag  == 1) {
        _startDate = date;
        _startDateString =
        [APHelperMethods jsonDateStringFromDate:date];
        _deal.dealStartDate = _startDateString;
        [_getStartDateOutlet setTitle:displayDate forState:UIControlStateNormal];
    } else if (button.tag == 2) {
        _endDateString =
        [APHelperMethods jsonDateStringFromDate:date];
        _deal.dealEndDate = _endDateString;
        [_getEndDateOutlet setTitle:displayDate forState:UIControlStateNormal];
    }
    [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    [_customPicker removeFromSuperview];
}

#pragma mark Valid deal object creation

- (BOOL)isDealObjectValid {
    BOOL isValid = YES;
    struct CGColor *redColor = [[UIColor redColor] CGColor];
    struct CGColor *clearColor = [[UIColor clearColor] CGColor];
    CGFloat borderWidth = 1.0f;
    
    for (int i = 1; i <= 2; i++) {
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
    
    if ([[_locationLabel titleLabel].text isEqualToString:@"Fetch Location"]) {
        _locationLabel.layer.borderColor = redColor;
        isValid = NO;
    } else {
        _locationLabel.layer.borderColor = clearColor;
    }
    
    if ([[_getStartDateOutlet titleLabel].text isEqualToString:@"Start date"]) {
        _getStartDateOutlet.layer.borderColor = redColor;
        isValid = NO;
    } else {
        _getStartDateOutlet.layer.borderColor = clearColor;
    }
    
    if ([[_getEndDateOutlet titleLabel].text isEqualToString:@"End date"]) {
        _getEndDateOutlet.layer.borderColor = redColor;
        isValid = NO;
    } else {
        _getEndDateOutlet.layer.borderColor = clearColor;
    }

    if (!isValid) {
        [AJNotificationView showNoticeInView:self.view
            type:AJNotificationTypeRed
            title:@"Fill the missing fields!"
            linedBackground:AJLinedBackgroundTypeAnimated
            hideAfter:2.0f response:^{}];
    }
    return isValid;
}
@end




