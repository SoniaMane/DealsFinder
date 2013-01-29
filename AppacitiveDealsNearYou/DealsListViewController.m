//
//  DealsListViewController.m
//  '
//
//  Created by Sonia Mane on 14/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#define KPageSize 50

#import "DealsListViewController.h"
#import "DealCell.h"
#import "Deal.h"
#import "DealDetailViewController.h"
#import "DealsFinderHelperMethods.h"

@interface DealsListViewController ()<FBUserSettingsDelegate> {
    int _pNum;
    int _pSize;
    CLLocationManager *_locationManager;
    CLPlacemark *_placemark;
    CLLocation *_currentLocation;
}
@property (strong, nonatomic) FBUserSettingsViewController *settingsViewController;
@property (weak, nonatomic) IBOutlet UITableView *dealTableView;
@property (strong, nonatomic) NSMutableArray *deals;

- (IBAction)showMenu:(id)sender;
@end

@implementation DealsListViewController

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        self->_pSize = KPageSize;
        self->_pNum = 1;
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
        [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [_locationManager startUpdatingLocation];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl = refreshControl;
    [self.refreshControl addTarget:self action:@selector(refreshControlCallback) forControlEvents:UIControlEventValueChanged];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionCreated) name:SessionReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionCreationFailed) name:ErrorRetrievingSessionNotification object:nil];
    [self fetchDeals];
}

- (void) sessionCreated {
    [self fetchDeals];
}

- (void) sessionCreationFailed {
    [AJNotificationView showNoticeInView:self.view
                                    type:AJNotificationTypeRed
                                   title:@"Connection error!"
                         linedBackground:AJLinedBackgroundTypeAnimated  hideAfter:2.5f response:^{}];
}

- (void) refreshControlCallback {
    [self fetchDeals];
}

- (IBAction)showMenu:(id)sender {
    [[self revealViewController] revealToggleAnimated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *dealItemCell = @"DealCell";
    
    DealCell *cell = (DealCell *)[tableView dequeueReusableCellWithIdentifier:dealItemCell];
    Deal *deal = [_deals objectAtIndex:indexPath.row];
    
    cell.dealNameLabel.text = deal.dealTitle;
    cell.dealDescriptionLabel.text = deal.dealDescription;
    cell.dealStartDateLabel.text = [[APHelperMethods deserializeJsonDateString:deal.dealStartDate] description];
    cell.dealEndDateLabel.text = [[APHelperMethods deserializeJsonDateString:deal.dealEndDate] description];
    
    CLLocationDistance distance = [_currentLocation distanceFromLocation:[DealsFinderHelperMethods jsonLocationStringToLatLng:deal.dealLocation]];
    cell.dealMilesAway.text = [NSString stringWithFormat:@"%.2f km",distance];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_deals count];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowDealDetail"]) {
        DealDetailViewController *dealDetail = [segue destinationViewController];
        NSIndexPath *path = [_dealTableView indexPathForSelectedRow];
        Deal *selectedDeal = [_deals objectAtIndex:path.row];
        [dealDetail setDeal:selectedDeal];
    }
}

-(void) fetchDeals {
    [AJNotificationView showNoticeInView:self.view
                                    type:AJNotificationTypeBlue
                                   title:@"Fetching Deals"
                         linedBackground:AJLinedBackgroundTypeAnimated
                               hideAfter:0.5f response:^{}];
    NSString *locationQuery = [APQuery queryStringForGeoCodeProperty:@"location" location:_currentLocation distance:kKilometers raduis:@50];
    NSString *query = [NSString stringWithFormat:@"%@&%@&query=%@",[APQuery queryStringForPageNumber:_pNum],[APQuery queryStringForPageSize:_pSize], locationQuery];
    [APObject searchObjectsWithSchemaName:@"deal"
                          withQueryString:query
                           successHandler:^(NSDictionary *dict){
                               NSArray *dealsArray = [dict objectForKey:@"articles"];
                               if (_deals == nil) {
                                   _deals = [[NSMutableArray alloc] init];
                               }
                               [dealsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
                                   NSDictionary *dealDictionary = obj;
                                   Deal *deal = [[Deal alloc]init];
                                   deal.objectId = [dealDictionary objectForKey:@"__id"];
                                   deal.dealTitle = [dealDictionary objectForKey:@"title"];
                                   deal.dealImageUrl = [dealDictionary objectForKey:@"photo"];
                                   deal.dealStartDate = [dealDictionary objectForKey:@"startdate"];
                                   deal.dealEndDate = [dealDictionary objectForKey:@"enddate"];
                                   deal.dealDescription = [dealDictionary objectForKey:@"description"];
                                   deal.dealLocation = [dealDictionary objectForKey:@"location"];
                                   [_deals addObject:deal];
                               }];
                               [_dealTableView reloadData];
                               [self.refreshControl endRefreshing];
                               NSDictionary *pagingInfo = [dict objectForKey:@"paginginfo"];
                               NSNumber *pageNum = [pagingInfo objectForKey:@"pagenumber"];
                               NSNumber *pageSize = [pagingInfo objectForKey:@"pagesize"];
                               NSNumber *toatalRecords = [pagingInfo objectForKey:@"totalrecords"];
                               
                               if ((pageNum.intValue * pageSize.intValue) <= toatalRecords.intValue) {
                                   _pNum++;
                                   [self fetchDeals];
                               }
                               [AJNotificationView showNoticeInView:self.view
                                                               type:AJNotificationTypeGreen
                                                              title:@"Deals fetched"
                                                    linedBackground:AJLinedBackgroundTypeDisabled                             hideAfter:2.5f response:^{}];
                           } failureHandler:^(APError *error) {
                               [AJNotificationView showNoticeInView:self.view
                                                               type:AJNotificationTypeRed
                                                              title:@"Error in fetching Deals! Just pull to refresh"
                                                    linedBackground:AJLinedBackgroundTypeAnimated                              hideAfter:2.5f response:^{}];
                               [self.refreshControl endRefreshing];
                           }];
}

#pragma mark location manager methods

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    [AJNotificationView showNoticeInView:self.view
                                    type:AJNotificationTypeRed
                                   title:@"Location services disabled!"
                         linedBackground:AJLinedBackgroundTypeAnimated                              hideAfter:2.5f response:^{}];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    _currentLocation = newLocation;
    [_locationManager stopUpdatingLocation];
}

- (IBAction)signOut:(id)sender {
    if (self.settingsViewController == nil) {
        self.settingsViewController = [[FBUserSettingsViewController alloc] init];
        self.settingsViewController.delegate = self;
    }
    [self.navigationController pushViewController:self.settingsViewController animated:YES];
}

#pragma mark - FBUserSettingDelegate methods

- (void)loginViewControllerDidLogUserOut:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

@end
