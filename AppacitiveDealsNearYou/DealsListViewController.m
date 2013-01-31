//
//  DealsListViewController.m
//  
//
//  Created by Sonia Mane on 14/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#define KPageSize 50
#define DEAL_CELL_IMAGE 100
#define DEAL_CELL_TITLE 200
#define DEAL_CELL_DESC 300
#define DEAL_CELL_START_DATE 400
#define DEAL_CELL_END_DATE 500
#define DEAL_CELL_MILES_AWAY 600

#import "DealsListViewController.h"
#import "DealCell.h"
#import "Deal.h"
#import "DealDetailViewController.h"
#import "DealsFinderHelperMethods.h"
#import "AppDelegate.h"
#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import "OAuth+Additions.h"
#import "TWAPIManager.h"
#import "TWSignedRequest.h"
#import "LoginViewController.h"

@interface DealsListViewController ()<FBUserSettingsDelegate> {
    int _pNum;
    int _pSize;
    CLLocationManager *_locationManager;
    CLPlacemark *_placemark;
    CLLocation *_currentLocation;
    AJNotificationView *_panel;
    UISearchDisplayController *searchDisplayController;
}

@property (strong, nonatomic) FBUserSettingsViewController *settingsViewController;
@property (strong, nonatomic) NSMutableArray *deals;
@property (strong, nonatomic) NSMutableArray *filteredDeals;

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;
- (IBAction)signOutOfApp:(id)sender;
@property (weak, nonatomic) IBOutlet UISearchBar *dealSearchbar;
@property (strong, nonatomic) IBOutlet UITableViewCell *dealCell;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *showMenuOutlet;

@property (strong, nonatomic) UINib *dealCellNib;
@end

@implementation DealsListViewController

static NSString *NibDealCellIdentifier = @"NibDealCellIdentifier";
static NSString *DealCellIdentifier = @"DealCellIdentifier";

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        self->_pSize = KPageSize;
        self->_pNum = 1;
        self.accountStore = [[ACAccountStore alloc] init];
        self.apiManager = [[TWAPIManager alloc] init];
    }
    return self;
}

- (UINib *)dealCellNib {
    if (!_dealCellNib)
    {
        _dealCellNib = [UINib nibWithNibName:@"DealCell" bundle:nil];
    }
    return _dealCellNib;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@"view did appear called=========================================");
    [self.showMenuOutlet setTarget: self.revealViewController];
    [self.showMenuOutlet setAction: @selector( revealToggle: )];
    [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    
    _locationManager = [[CLLocationManager alloc] init];
    [_locationManager setDelegate:self];
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [_locationManager startUpdatingLocation];

    _filteredDeals = [[NSMutableArray alloc] init];
    [_dealSearchbar setShowsScopeBar:NO];
    [_dealSearchbar sizeToFit];
    
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
    _panel = [AJNotificationView showNoticeInView:self.view
                    type:AJNotificationTypeRed
                    title:@"Connection error!"
                    linedBackground:AJLinedBackgroundTypeAnimated  hideAfter:3.0f response:^{}];
    if (_panel)
        [_panel hide];
}

- (void) refreshControlCallback {
    [self fetchDeals];
}

- (IBAction)signOutOfApp:(id)sender {
    APUser *user = [APUser currentUser];
    if(user.loggedInWithTwitter) {
        [ApplicationDelegate logoutFromDealFinder];
    } else if (user.loggedInWithFacebook){
        if (self.settingsViewController == nil) {
            self.settingsViewController = [[FBUserSettingsViewController alloc] init];
            self.settingsViewController.delegate = self;
        }
        [self.navigationController pushViewController:self.settingsViewController animated:YES];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = (UITableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:DealCellIdentifier];
    if (cell == nil)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:NibDealCellIdentifier];
        
        if (cell == nil)
        {
            [self.dealCellNib instantiateWithOwner:self options:nil];
            cell = self.dealCell;
            self.dealCell = nil;
        }
    }

    Deal *deal = nil;
    if (tableView == self.tableView)
	{
        deal = [_deals objectAtIndex:indexPath.row];
    } else {
        NSLog(@"table is %@", [tableView class]);
        deal = [_filteredDeals objectAtIndex:indexPath.row];
        NSLog(@"found deal============== %@", [deal  description]);
    }
    
    
    UILabel *dealNameLabel = (UILabel *)[cell viewWithTag:DEAL_CELL_TITLE];
    dealNameLabel.text = deal.dealTitle;
    
    UILabel *dealDescriptionLabel = (UILabel *)[cell viewWithTag:DEAL_CELL_DESC];
    dealDescriptionLabel.text = deal.dealDescription;

    UILabel *dealStartDateLabel = (UILabel *)[cell viewWithTag:DEAL_CELL_START_DATE];
    dealStartDateLabel.text = deal.dealStartDate;

    UILabel *dealEndDateLabel = (UILabel *)[cell viewWithTag:DEAL_CELL_END_DATE];
    dealEndDateLabel.text = deal.dealEndDate;

    UILabel *dealMilesAway = (UILabel *)[cell viewWithTag:DEAL_CELL_MILES_AWAY];
    CLLocationDistance distance = [_currentLocation distanceFromLocation:[DealsFinderHelperMethods jsonLocationStringToLatLng:deal.dealLocation]];
    dealMilesAway.text = [NSString stringWithFormat:@"%.2f km",distance];
    UIImageView *dealImageView = (UIImageView *)[cell viewWithTag:DEAL_CELL_IMAGE];
    [APBlob downloadImageFromRemoteUrl:@"https://s3.grouponcdn.com/images/site_images/2943/3316/RackMultipart20130123-18719-19qc5x7_grid_4.jpg" successHandler:^(UIImage *image,NSURL *url ,BOOL isCached) {
        [dealImageView setImage:image];
    }];
    

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView)
	{
        return [_filteredDeals count];
    } else {
        return [_deals count];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowDealDetail"]) {
        DealDetailViewController *dealDetail = [segue destinationViewController];
        if(sender == self.searchDisplayController.searchResultsTableView) {
             NSIndexPath *path = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
            Deal *selectedDeal = [_filteredDeals objectAtIndex:path.row];
            [dealDetail setDeal:selectedDeal];
        } else {
            NSIndexPath *path = [self.tableView indexPathForSelectedRow];
            Deal *selectedDeal = [_deals objectAtIndex:path.row];
            [dealDetail setDeal:selectedDeal];
        }
    }
}

-(void) fetchDeals {
    _panel = [AJNotificationView showNoticeInView:self.view
                    type:AJNotificationTypeBlue
                    title:@"Fetching Deals"
                    linedBackground:AJLinedBackgroundTypeAnimated
                    hideAfter:3.0f response:^{}];
    
    NSString *locationQuery = [APQuery queryStringForGeoCodeProperty:@"location" location:_currentLocation distance:kKilometers raduis:@50];
    NSString *query = [NSString stringWithFormat:@"%@&%@&query=%@",[APQuery queryStringForPageNumber:_pNum],[APQuery queryStringForPageSize:_pSize], locationQuery];
    [APObject searchObjectsWithSchemaName:@"deal"
                          withQueryString:query
                           successHandler:^(NSDictionary *dict){
                               NSArray *dealsArray = [dict objectForKey:@"articles"];
                               if (_deals == nil) {
                                   _deals = [[NSMutableArray alloc] init];                                   
                               } else {
                                   [_deals removeAllObjects];
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
                               
                               _filteredDeals = [NSMutableArray arrayWithCapacity:[_deals count]];
                               NSLog(@"filtered array is %d - %d", [_deals count], [_filteredDeals count]);
                               [self.tableView reloadData];
                               [self.refreshControl endRefreshing];
                               NSDictionary *pagingInfo = [dict objectForKey:@"paginginfo"];
                               NSNumber *pageNum = [pagingInfo objectForKey:@"pagenumber"];
                               NSNumber *pageSize = [pagingInfo objectForKey:@"pagesize"];
                               NSNumber *toatalRecords = [pagingInfo objectForKey:@"totalrecords"];
                               
                               if ((pageNum.intValue * pageSize.intValue) <= toatalRecords.intValue) {
                                   _pNum++;
                                   [self fetchDeals];
                               }
                               _panel = [AJNotificationView showNoticeInView:self.view
                                                                        type:AJNotificationTypeGreen
                                                                       title:@"Deals fetched"
                                                             linedBackground:AJLinedBackgroundTypeDisabled
                                                                   hideAfter:2.5f response:^{}];
                               
                           } failureHandler:^(APError *error) {
                               if (_panel) {
                                   [_panel hide];
                               }
                               _panel = [AJNotificationView showNoticeInView:self.view
                                                                        type:AJNotificationTypeRed
                                                                       title:@"Error in fetching Deals! Just pull to refresh"
                                                             linedBackground:AJLinedBackgroundTypeAnimated
                                                                   hideAfter:3.0f response:^{}];
                               [self.refreshControl endRefreshing];
                           }];
}

#pragma mark location manager methods

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    _panel = [AJNotificationView showNoticeInView:self.view
                type:AJNotificationTypeRed
                title:@"Location services disabled!"
                linedBackground:AJLinedBackgroundTypeAnimated
                hideAfter:2.5f response:^{}];
    if (_panel)
        [_panel hide];
}
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    _currentLocation = newLocation;
    [_locationManager stopUpdatingLocation];
}

#pragma mark - FBUserSettingDelegate methods

- (void)loginViewControllerDidLogUserOut:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

#pragma mark - UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    tableView.rowHeight = 195;
}

#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    [_filteredDeals removeAllObjects];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.dealTitle contains[c] %@",searchText];
    NSArray *tempArray = [_deals filteredArrayUsingPredicate:predicate];
    NSLog(@"%@ temp", tempArray);
//    if(![scope isEqualToString:@"All"]) {
//        // Further filter the array with the scope
//        NSPredicate *scopePredicate = [NSPredicate predicateWithFormat:@"SELF.category contains[c] %@",scope];
//        tempArray = [tempArray filteredArrayUsingPredicate:scopePredicate];
//    }
    
    _filteredDeals = [NSMutableArray arrayWithArray:tempArray];
}
@end
