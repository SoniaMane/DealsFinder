//
//  StoreListViewController.h
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 14/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "StoreListProtocol.h"

@interface StoreListViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, StoreListProtocol, UISearchBarDelegate, UISearchDisplayDelegate, UIScrollViewDelegate>
@end
