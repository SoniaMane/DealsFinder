//
//  DealsFinderHelperMethods.m
//  AppacitiveDealsNearYou
//
//  Created by Kauserali on 22/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "DealsFinderHelperMethods.h"

@implementation DealsFinderHelperMethods

+ (CLLocation *) jsonLocationStringToLatLng: (NSString *) locationString {
    NSArray *latLngString = [locationString componentsSeparatedByString:@","];
    
    NSString *lat = [latLngString objectAtIndex:0];
    NSString *lng = [latLngString objectAtIndex:1];
    CLLocation *location = [[CLLocation alloc]initWithLatitude:[lat doubleValue] longitude:[lng doubleValue]];
    return location;
}
@end
