//
//  AppDelegate.m
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 14/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "AppDelegate.h"
#import "FacebookSDK.h"
#import "LoginViewController.h"

//#define kTWConsumerKey @"FClGZiCSGc3wVEYu60u9A"
//#define kTWConsumerSecret @"q5vywdaYhuWCpijH8JDuR9xo1M0VGg6elBMiaWmkQI"
//#define kTWAuthTokenSecret @"SZGIIhuaUmOeT5mkFRkC28sk8fjOhm5AHC9rCVomU"

#define kTWConsumerKey @"mj4Dmaq8ikrDAg5UTVBlw"
#define kTWConsumerSecret @"KruMMqRqTpbDZcOT1KpxwXROPhKohQf7H9RwXhbHQ2w"
#define kTWAuthTokenSecret @"3A4OIVS70IRI8rSoAbmYe4nTEQBFGYIofRKfWniEk8"

@implementation AppDelegate
@synthesize accounts, accountStore, apiManager, isLoggedInFromTwitter;

NSString *const SCSessionStateChangedNotification = @"com.appacitive.AppacitiveDealsNearYou:SCSessionStateChangedNotification";
NSString *const FacebookAccessTokenKey = @"com.appacitive.AppacitiveDealsNearYou:FacebookAccessTokenKey";
NSString *const TwitterOAuthAccessTokenKey = @"com.appacitive.AppacitiveDealsNearYou:TwitterOAuthAccessTokenKey";
NSString *const TwitterAccessTokenKeyReceivedNotification = @"com.appacitive.AppacitiveDealsNearYou:TwitterAccessTokenKeyReceivedNotification";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Appacitive appacitiveWithApiKey:@"r6ZODXPtV2UTDUkykGs92+lPwGBGa0R1FKXMizNTvDw="];
    self.accountStore = [[ACAccountStore alloc] init];
    self.apiManager = [[TWAPIManager alloc] init];
    [self refreshTwitterAccounts];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTwitterAccounts)
     name:ACAccountStoreDidChangeNotification
     object:nil];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSession.activeSession handleDidBecomeActive];
}

- (void) getTwitterOAuthTokenUsingReverseOAuth {
    if ([TWAPIManager isLocalTwitterAccountAvailable]) {
        UIActionSheet *sheet = [[UIActionSheet alloc]
                                initWithTitle:@"Choose an Account"
                                delegate:self
                                cancelButtonTitle:nil
                                destructiveButtonTitle:nil
                                otherButtonTitles:nil];
        
        for (ACAccount *acct in self.accounts) {
            [sheet addButtonWithTitle:acct.username];
        }
        
        [sheet addButtonWithTitle:@"Logout from Deal finder"];
        [sheet setDestructiveButtonIndex:[self.accounts count]];
        UIStoryboard *storyBoardTemp = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        __weak LoginViewController *loginViewController = (LoginViewController*) [storyBoardTemp instantiateViewControllerWithIdentifier:@"Login"];
        [sheet showInView:loginViewController.view];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc]
            initWithTitle:@"No Accounts"
            message:@"Please configure a Twitter "
            "account in Settings.app"
            delegate:nil
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil];
        [alert show];
    }   
}
- (void)openSession {
    [FBSession openActiveSessionWithReadPermissions:nil
        allowLoginUI:YES
        completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
        [self sessionStateChanged:session state:state error:error];
    }];
}

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error {
    switch (state) {
        case FBSessionStateOpen: {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:session.accessToken forKey:FacebookAccessTokenKey];

            [APUser authenticateUserWithFacebook:session.accessToken successHandler:^(){
                isLoggedInFromTwitter = NO;
                NSLog(@"Facebook access token is %@", session.accessToken);
                [AJNotificationView showNoticeInView:self.window.rootViewController.view
                    type:AJNotificationTypeGreen
                    title:@"Successfully authenticated with facebook"
                    linedBackground:AJLinedBackgroundTypeAnimated
                    hideAfter:10.0f response:^{}];
                APUser *authenticatedUser = [APUser currentUser];
                NSLog(@"user token %@", authenticatedUser.objectId);
            } failureHandler:^(APError *error){
                [AJNotificationView showNoticeInView:self.window.rootViewController.navigationController.view
                    type:AJNotificationTypeRed
                    title:@"Login with facebook failed"
                    linedBackground:AJLinedBackgroundTypeAnimated
                    hideAfter:2.5f response:^{}];
            }];
        }
            break;
        case FBSessionStateClosed:
        {
            [FBSession.activeSession closeAndClearTokenInformation];
            UIStoryboard *storyBoardTemp = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
            __weak LoginViewController *loginViewController = (LoginViewController*) [storyBoardTemp instantiateViewControllerWithIdentifier:@"Login"];
            
            loginViewController.loginWithFacebookSuccessful = ^() {
                [loginViewController dismissViewControllerAnimated:YES completion:nil];
            };
            [self.window.rootViewController presentViewController:loginViewController animated:YES completion:nil];

        }
            break;
        case FBSessionStateClosedLoginFailed: {
            [FBSession.activeSession closeAndClearTokenInformation];
        }
            break;
        default:
            break;
    }
    // The below code should be in the success handler
    [[NSNotificationCenter defaultCenter] postNotificationName:SCSessionStateChangedNotification object:session userInfo:@{@"session":session}];
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription
                                                           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBSession.activeSession handleOpenURL:url];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != (actionSheet.numberOfButtons - 1)) {
        [self.apiManager
         performReverseAuthForAccount:self.accounts[buttonIndex]
         withHandler:^(NSData *responseData, NSError *error) {
             if (responseData) {
                 NSString *responseStr = [[NSString alloc]
                                          initWithData:responseData
                                          encoding:NSUTF8StringEncoding];                 
                 NSArray *parts = [responseStr
                                   componentsSeparatedByString:@"&"];
                 NSString *oAuthTokenString = [parts objectAtIndex:0];                 
                 NSString *twitterOAuthToken = [[oAuthTokenString componentsSeparatedByString:@"="] objectAtIndex:1];
                 NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                 [userDefaults setObject:twitterOAuthToken forKey:TwitterOAuthAccessTokenKey];
                
                 [APUser authenticateUserWithTwitter: twitterOAuthToken oauthSecret: kTWAuthTokenSecret consumerKey:kTWConsumerKey consumerSecret:kTWConsumerSecret successHandler:^(){
                     isLoggedInFromTwitter = YES;
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [[NSNotificationCenter defaultCenter] postNotificationName:TwitterAccessTokenKeyReceivedNotification object:twitterOAuthToken userInfo:@{@"twitterOAuthToken":twitterOAuthToken}];
                     });
                 } failureHandler:^(APError *error){
                 }];
             }
             else {
                 NSLog(@"Error!\n%@", [error localizedDescription]);
             }
         }];
    }
}

#pragma mark - Private

- (void)refreshTwitterAccounts
{
    [self obtainAccessToAccountsWithBlock:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
               // _loginWithTwiterButton.enabled = YES;
            }
            else {
                NSLog(@"You were not granted access to the Twitter accounts.");
            }
        });
    }];
}

- (void)obtainAccessToAccountsWithBlock:(void (^)(BOOL))block
{
    ACAccountType *twitterType = [self.accountStore
                                  accountTypeWithAccountTypeIdentifier:
                                  ACAccountTypeIdentifierTwitter];
    
    ACAccountStoreRequestAccessCompletionHandler handler =
    ^(BOOL granted, NSError *error) {
        if (granted) {
            self.accounts = [self.accountStore accountsWithAccountType:twitterType];
        }
        
        block(granted);
    };
    
    //  This method changed in iOS6.  If the new version isn't available, fall
    //  back to the original (which means that we're running on iOS5+).
    if ([self.accountStore
         respondsToSelector:@selector(requestAccessToAccountsWithType:
                                      options:
                                      completion:)]) {
             [self.accountStore requestAccessToAccountsWithType:twitterType
                                                    options:nil
                                                 completion:handler];
         }
    else {
        [self.accountStore requestAccessToAccountsWithType:twitterType
                                 withCompletionHandler:handler];
    }
}

- (void) logoutFromDealFinder {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:nil forKey:TwitterOAuthAccessTokenKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:TwitterAccessTokenKeyReceivedNotification object:nil userInfo:@{@"twitterOAuthToken":@""}];
    UIStoryboard *storyBoardTemp = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    __weak LoginViewController *loginViewController = (LoginViewController*) [storyBoardTemp instantiateViewControllerWithIdentifier:@"Login"];
    
    loginViewController.loginWithTwitterSuccessful = ^() {
        [loginViewController dismissViewControllerAnimated:YES completion:nil];
    };
    [self.window.rootViewController presentViewController:loginViewController animated:YES completion:nil];
}
@end
