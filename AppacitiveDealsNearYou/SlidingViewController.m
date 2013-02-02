//
//  InitialSlidingViewController.m
//  APFindYourDeal
//
//  Created by Sonia Mane on 09/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//


#import "SlidingViewController.h"
#import "LoginViewController.h"
#import "AppDelegate.h"

@interface SlidingViewController() {
    __block AJNotificationView *_panel;
}

@end
@implementation SlidingViewController

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appacitiveSessionReceived) name:SessionReceivedNotification object:nil];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewDidLoad {
    [super viewDidLoad];
}
- (void) appacitiveSessionReceived {
    
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    NSString *token = [userDefaults objectForKey:TwitterAccessTokenKeyReceivedNotification];
//    NSLog(@"---- %@", token);
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded){
        [ApplicationDelegate openSession];
       // [ApplicationDelegate getTwitterOAuthTokenUsingReverseOAuth];
    } else {
        UIStoryboard *storyBoardTemp = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        __weak LoginViewController *loginViewController = (LoginViewController*) [storyBoardTemp instantiateViewControllerWithIdentifier:@"Login"];
        
        loginViewController.loginWithFacebookSuccessful = ^() {
            _panel =  [AJNotificationView showNoticeInView:loginViewController.view
                type:AJNotificationTypeGreen
                title:@"Successfully authenticated with facebook"
                linedBackground:AJLinedBackgroundTypeAnimated
                hideAfter:10.0f response:^{}];
            if (_panel) {
                [_panel hide];
            }

            [loginViewController dismissViewControllerAnimated:YES completion:nil];
        };
        loginViewController.loginWithTwitterSuccessful = ^() {
            [loginViewController dismissViewControllerAnimated:YES completion:nil];
        };
        
        [self presentViewController:loginViewController animated:YES completion:nil];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}
@end
