//
//  Store.m
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 21/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "Store.h"

@implementation Store


- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _thumbnailData = [aDecoder decodeObjectForKey:@"thumbnailData"];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_thumbnailData forKey:@"thumbnailData"];
}
- (UIImage *) thumbnail {
    if (!_thumbnailData) {
        return nil;
    }
    
    if (!_thumbnail) {
        _thumbnail = [UIImage imageWithData:_thumbnailData];
    }
    return _thumbnail;
}

- (void) setThumbnailDataForImage:(UIImage *)image {
    CGSize origImageSize = [image size];
    CGRect newRect = CGRectMake(0, 0, 100, 100);
    
    float ratio = MAX(newRect.size.width / origImageSize.width, newRect.size.height / origImageSize.height);
    
    UIGraphicsBeginImageContextWithOptions(newRect.size, NO, 0.0);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:newRect cornerRadius:5.0];
    
    [path addClip];
    
    CGRect projectRect;
    projectRect.size.width = ratio * origImageSize.width;
    projectRect.size.height = ratio * origImageSize.height;
    projectRect.origin.x = (newRect.size.width - projectRect.size.width) / 2;
    projectRect.origin.y = (newRect.size.height - projectRect.size.height) / 2;
    
    [image drawInRect:projectRect];
    
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    [self setThumbnail:smallImage];
    
    NSData *data = UIImagePNGRepresentation(smallImage);
    [self setThumbnailData:data];
    
    UIGraphicsEndImageContext();
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Stores fetched are - Object id:%@, Name: %@, Address:%@, Phone No.:%@, Location:%@",_objectId, _storeName, _storeAddress, _storePhone, _storeLocation];
}
@end
