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

@interface StoreListViewController () {
    int _pNum;
    int _pSize;
}
@property (strong, nonatomic) NSMutableArray *stores;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createNewStore;
@property (weak, nonatomic) IBOutlet UITableView *storeTableView;
- (IBAction)revealPublishOptions:(id)sender;

@end

@implementation StoreListViewController

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
        self->_pSize = KPageSize;
        self->_pNum = 1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
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

- (IBAction)revealPublishOptions:(id)sender {
    [[self navigationController] dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_stores count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"StoreCell";
    StoreCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Store *store = [_stores objectAtIndex:indexPath.row];
    if ([[store storeImageUrl] isEqual:nil] && [[store storeImageUrl] length] != 0) {
        [APBlob downloadImageFromRemoteUrl:[store storeImageUrl] successHandler:^(UIImage *image,NSURL *url ,BOOL isCached) {
            [cell.storeImageView setImage:image];
        }];
    }
    cell.storeNameLabel.text = [store storeName];
    cell.storeAddressLabel.text = [store storeAddress];
    cell.storePhoneLabel.text = [store storePhone];
    return cell;
}

#pragma mark - fetch remote data

- (void) fetchStores {
    [AJNotificationView showNoticeInView:self.view
            type:AJNotificationTypeBlue
            title:@"Fetching Stores"
            linedBackground:AJLinedBackgroundTypeAnimated
            hideAfter:2.5f response:^{}];
    
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
            [AJNotificationView showNoticeInView:self.view
                type:AJNotificationTypeGreen
                title:@"Stores fetched"
                linedBackground:AJLinedBackgroundTypeDisabled
                hideAfter:2.5f response:^{}];

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
        [AJNotificationView showNoticeInView:self.view
            type:AJNotificationTypeRed
            title:@"Error! just pull to refresh."
            linedBackground:AJLinedBackgroundTypeAnimated
            hideAfter:2.5f response:^{}
                      ];
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
@end
