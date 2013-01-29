//
//  Store.m
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 21/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "Store.h"

@implementation Store

- (NSString *)description {
    return [NSString stringWithFormat:@"Stores fetched are - Object id:%@, Name: %@, Address:%@, Phone No.:%@, Location:%@",_objectId, _storeName, _storeAddress, _storePhone, _storeLocation];
}
@end
