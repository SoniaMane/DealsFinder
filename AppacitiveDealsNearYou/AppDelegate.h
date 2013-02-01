//
//  AppDelegate.h
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 14/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import "OAuth+Additions.h"
#import "TWAPIManager.h"
#import "TWSignedRequest.h"

#define ApplicationDelegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIActionSheetDelegate>

extern NSString *const SCSessionStateChangedNotification;
extern NSString *const FacebookAccessTokenKey;
extern NSString *const TwitterOAuthAccessTokenKey;
extern NSString *const TwitterAccessTokenKeyReceivedNotification;
extern NSString *const ExitDealFinder;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;

//Temporary hack till the APUser is modified.
@property (nonatomic, assign) BOOL isLoggedInFromTwitter;
- (void) openSession;
- (void) getTwitterOAuthTokenUsingReverseOAuth;
- (void) logoutFromDealFinder;
@end
