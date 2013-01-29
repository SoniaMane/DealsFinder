//
//  StoreListProtocol.h
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 23/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

@class Store;

@protocol StoreListProtocol <NSObject>
- (void) notifyStoreDatasourceChanged:(Store *) store;
@end
