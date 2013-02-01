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
#import "DealsListViewController.h"

@implementation SlidingViewController

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appacitiveSessionReceived) name:SessionReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exitTheApp) name:ExitDealFinder object:nil];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) viewDidLoad {
    [super viewDidLoad];
}
- (void) appacitiveSessionReceived {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [userDefaults objectForKey:TwitterAccessTokenKeyReceivedNotification];
    NSLog(@"---- %@", token);
    if ((FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) && (token == nil || token == @"")) {
        [ApplicationDelegate openSession];
       // [ApplicationDelegate getTwitterOAuthTokenUsingReverseOAuth];
    } else {
        UIStoryboard *storyBoardTemp = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
        __weak LoginViewController *loginViewController = (LoginViewController*) [storyBoardTemp instantiateViewControllerWithIdentifier:@"Login"];
        
        loginViewController.loginWithFacebookSuccessful = ^() {
            [loginViewController dismissViewControllerAnimated:YES completion:nil];
        };
        loginViewController.loginWithTwitterSuccessful = ^() {
            [loginViewController dismissViewControllerAnimated:YES completion:nil];
        };
        
        [self presentViewController:loginViewController animated:YES completion:nil];
    }
}

- (void) exitTheApp {
    UIStoryboard *storyBoardTemp = [UIStoryboard storyboardWithName:@"iPhone" bundle:nil];
    __weak LoginViewController *loginViewController = (LoginViewController*) [storyBoardTemp instantiateViewControllerWithIdentifier:@"Login"];
    NSLog(@"REached here in sliding %@", [self.navigationController class]);
    __weak DealsListViewController *dlvc = (DealsListViewController*) [storyBoardTemp instantiateViewControllerWithIdentifier:@"DealList"];
    
    [self.presentedViewController presentViewController:loginViewController animated:YES completion:nil];
//    dlvc.logoutOfApp = ^() {
//        [dlvc dismissViewControllerAnimated:YES completion:nil];
//    };
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}
@end
