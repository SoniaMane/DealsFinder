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

@implementation AppDelegate
NSString *const SCSessionStateChangedNotification = @"com.appacitive.AppacitiveDealsNearYou:SCSessionStateChangedNotification";
NSString *const FacebookAccessTokenKey = @"com.appacitive.AppacitiveDealsNearYou:FacebookAccessTokenKey";

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Appacitive appacitiveWithApiKey:@"r6ZODXPtV2UTDUkykGs92+lPwGBGa0R1FKXMizNTvDw="];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSession.activeSession handleDidBecomeActive];
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
                    linedBackground:AJLinedBackgroundTypeAnimated                             hideAfter:2.5f response:^{}];
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

@end
