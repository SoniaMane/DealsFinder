//
//  StoreListViewController.m
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 14/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "StoreListViewController.h"
#import "Store.h"
#import "StoreCell.h"
#import "CreateStoreViewController.h"
#import "CreateDealViewController.h"

#define KPageSize 50
#define STORE_CELL_IMAGE 101
#define STORE_CELL_NAME 201
#define STORE_CELL_ADDRESS 301
#define STORE_CELL_PHONE_NUM 401

@interface StoreListViewController () {
    int _pNum;
    int _pSize;
    AJNotificationView *_panel;
    UISearchDisplayController *searchDisplayController;
}
@property (strong, nonatomic) NSMutableArray *stores;
@property (strong, nonatomic) NSMutableArray *filteredStores;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createNewStore;
@property (weak, nonatomic) IBOutlet UITableView *storeTableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *revealPublishOptions;
@property (strong, nonatomic) IBOutlet UITableViewCell *storeCell;
@property (strong, nonatomic) UINib *storeCellNib;
@property (weak, nonatomic) IBOutlet UISearchBar *storeSearchBar;

@end

@implementation StoreListViewController
static NSString *NibStoreCellIdentifier = @"NibStoreCellIdentifier";
static NSString *StoreCellIdentifier = @"StoreCellIdentifier";
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        self->_pSize = KPageSize;
        self->_pNum = 1;
    }
    return self;
}

- (UINib *) storeCellNib {
    if (!_storeCellNib) {
        _storeCellNib = [UINib nibWithNibName:@"StoreCell" bundle:nil];
    }
    return _storeCellNib;

}
- (void)viewDidLoad {
    [super viewDidLoad];
    _filteredStores = [[NSMutableArray alloc] init];
    [_storeSearchBar setShowsScopeBar:NO];
    [_storeSearchBar sizeToFit];
    
    [self.revealPublishOptions setTarget: self.revealViewController];
    [self.revealPublishOptions setAction: @selector( revealToggle: )];
    [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl = refreshControl;
    [self.refreshControl addTarget:self action:@selector(refreshControlCallback) forControlEvents:UIControlEventValueChanged];
}

-(void)viewDidAppear:(BOOL)animated {
    [self fetchStores];
}

- (void) refreshControlCallback {
    [self fetchStores];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [_filteredStores count];
    } else {
        return [_stores count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self.storeTableView dequeueReusableCellWithIdentifier:StoreCellIdentifier];
    
    if (cell == nil) {
        cell = [self.storeTableView dequeueReusableCellWithIdentifier:NibStoreCellIdentifier];
        if (cell == nil) {
            [self.storeCellNib instantiateWithOwner:self options:nil];
            cell = self.storeCell;
            self.storeCell = nil;
        }
    }

    Store *store = nil;
    if (tableView == self.storeTableView) {
        store = [_stores objectAtIndex:indexPath.row];
    } else {
        store = [_filteredStores objectAtIndex:indexPath.row];
    }
    
    
    UILabel *storeNameLabel = (UILabel *)[cell viewWithTag:STORE_CELL_NAME];
    storeNameLabel.text = store.storeName;
    
    UILabel *storeAddressLabel = (UILabel *)[cell viewWithTag:STORE_CELL_ADDRESS];
    storeAddressLabel.text = store.storeAddress;
    
    UILabel *storePhoneLabel = (UILabel *)[cell viewWithTag:STORE_CELL_PHONE_NUM];
    storePhoneLabel.text = store.storePhone;
    
    UIImageView *storeImageView = (UIImageView *)[cell viewWithTag:STORE_CELL_IMAGE];

    if ([[store storeImageUrl] isEqual:nil] && [[store storeImageUrl] length] != 0) {
        [APBlob downloadImageFromRemoteUrl:@"https://s3.grouponcdn.com/images/site_images/2943/3316/RackMultipart20130123-18719-19qc5x7_grid_4.jpg" successHandler:^(UIImage *image,NSURL *url ,BOOL isCached) {
            [storeImageView setImage:image];
        }];
    }
    return cell;
}

#pragma mark - fetch remote data

- (void) fetchStores {
    _panel = [AJNotificationView showNoticeInView:self.view
            type:AJNotificationTypeBlue
            title:@"Fetching Stores"
            linedBackground:AJLinedBackgroundTypeAnimated
            hideAfter:2.5f response:^{}];
    if (_panel) {
        [_panel hide];
    }
    APUser *user = [APUser currentUser];
    NSNumber *objectId = user.objectId;
    NSString *userId = [NSString stringWithFormat:@"%lld",16134112148587524];
   
    NSString *pageQuery = [NSString stringWithFormat:@"%@&%@",[APQuery queryStringForPageNumber:_pNum],[APQuery queryStringForPageSize:_pSize]];
    NSString *query = [NSString stringWithFormat:@"articleId=%@&label=%@&%@", userId, @"store",pageQuery];
    [APConnection searchForConnectionsWithRelationType:@"owner" withQueryString:query successHandler:^(NSDictionary *result){
        NSArray *connectionsArray = [result objectForKey:@"connections"];
        NSMutableArray *endPointAArray = [[NSMutableArray alloc]init];
        [connectionsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){
            NSDictionary *connectionDictionary = obj;
            NSDictionary *endPointADictionary = [connectionDictionary objectForKey:@"__endpointa"];
            [endPointAArray addObject:endPointADictionary];
        }];
        
        NSMutableArray *storeIdArray = [[NSMutableArray alloc] init];
        [endPointAArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop){

            NSDictionary *idDict = obj;
            NSString *storeId = [idDict objectForKey:@"articleid"];        
            [storeIdArray addObject:storeId];
        }];
        
        [APObject fetchObjectsWithObjectIds:storeIdArray schemaName:@"store" successHandler:^(NSDictionary *dict){
           _panel = [AJNotificationView showNoticeInView:self.view
                type:AJNotificationTypeGreen
                title:@"Stores fetched"
                linedBackground:AJLinedBackgroundTypeDisabled
                hideAfter:2.5f response:^{}];
            if (_panel) {
                [_panel hide];
            }
            NSArray *storesArray = [dict objectForKey:@"articles"];
            _stores = [[NSMutableArray alloc] init];
            [storesArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSDictionary *storeDictionary = obj;
                    Store *store = [[Store alloc] init];
                    store.objectId = [storeDictionary objectForKey:@"__id"];
                    store.storeLabel = [storeDictionary objectForKey:@"__schematype"];
                    store.storeName = [storeDictionary objectForKey:@"name"];
                    store.storeAddress = [storeDictionary objectForKey:@"address"];
                    store.storePhone = [storeDictionary objectForKey:@"phone"];
                    store.storeImageUrl = [storeDictionary objectForKey:@"photo"];
                    [_stores addObject:store];
                    [_storeTableView reloadData];
                    [self.refreshControl endRefreshing];
                    }];
            NSDictionary *pagingInfo = [result objectForKey:@"paginginfo"];
            NSLog(@"paging info %@", pagingInfo);
            NSNumber *pageNum = [pagingInfo objectForKey:@"pagenumber"];
            NSNumber *pageSize = [pagingInfo objectForKey:@"pagesize"];
            NSNumber *toatalRecords = [pagingInfo objectForKey:@"totalrecords"];
            
            if ((pageNum.intValue * pageSize.intValue) <= toatalRecords.intValue) {
                _pNum++;
                [self fetchStores];
            }
        } failureHandler:^(APError *error){}];
    } failureHandler:^(APError *error){
       _panel = [AJNotificationView showNoticeInView:self.view
            type:AJNotificationTypeRed
            title:@"Error! just pull to refresh."
            linedBackground:AJLinedBackgroundTypeAnimated
                                           hideAfter:2.5f response:^{}];
        if (_panel) {
            [_panel hide];
        }

        [self.refreshControl endRefreshing];
    }];
}

#pragma store Datasource Protocol

- (void) notifyStoreDatasourceChanged:(Store *) store {
    [_stores addObject:store];
    [_storeTableView reloadData];
}

#pragma mark segue methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CreateNewDealSegue"]) {
        CreateDealViewController *createDeal = [segue destinationViewController];
        NSIndexPath *path = [_storeTableView indexPathForSelectedRow];
        Store *selectedStore = [_stores objectAtIndex:path.row];
        [createDeal setEndPointA:selectedStore];
    }
}

#pragma mark - UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    tableView.rowHeight = 195;
}

#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    [_filteredStores removeAllObjects];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.storeName contains[c] %@",searchText];
    NSArray *tempArray = [_stores filteredArrayUsingPredicate:predicate];
    NSLog(@"%@ temp", tempArray);
    _filteredStores = [NSMutableArray arrayWithArray:tempArray];
}

@end
