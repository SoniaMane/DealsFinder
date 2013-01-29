//
//  DealsFinderHelperMethods.m
//  AppacitiveDealsNearYou
//
//  Created by Kauserali on 22/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "DealsFinderHelperMethods.h"

@implementation DealsFinderHelperMethods

+ (NSString *) deserializeJsonDateStringToHumanReadableForm: (NSString *)jsonDateString {
    if (jsonDateString == nil && jsonDateString.length == 0) {
        return nil;
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSSS"];
    NSDate *date = [dateFormatter dateFromString:jsonDateString];
    
    [dateFormatter setDateFormat:@"dd-MM-yy"];
    return [dateFormatter stringFromDate:date];
}

+ (CLLocation *) jsonLocationStringToLatLng: (NSString *) locationString {
    NSArray *latLngString = [locationString componentsSeparatedByString:@","];
    
    NSString *lat = [latLngString objectAtIndex:0];
    NSString *lng = [latLngString objectAtIndex:1];
    CLLocation *location = [[CLLocation alloc]initWithLatitude:[lat doubleValue] longitude:[lng doubleValue]];
    return location;
}
@end
