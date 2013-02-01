//
//  LoginViewController.m
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 14/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "AppDelegate.h"

@interface LoginViewController () {
    __block AJNotificationView *_panel;
}
@end

@implementation LoginViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
       
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
- (void) viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(facebookSessionChangedNotification:) name:SCSessionStateChangedNotification object:nil];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * token = [userDefaults  objectForKey:TwitterOAuthAccessTokenKey];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(twitterOAuthTokenReceived:) name:TwitterAccessTokenKeyReceivedNotification object:nil];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];    
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) twitterOAuthTokenReceived:(NSNotification *) notification {
    NSString *twitterAccessToken = [[notification userInfo] objectForKey:@"twitterOAuthToken"];
    NSLog(@"twitter access token is %@", twitterAccessToken);
    NSLog(@"login with twitter successful ??? %@", self.loginWithTwitterSuccessful);
    if (twitterAccessToken != nil && twitterAccessToken != @"" && self.loginWithTwitterSuccessful != nil) {
        self.loginWithTwitterSuccessful();
    } else {
        _panel = [AJNotificationView showNoticeInView:self.view
            type:AJNotificationTypeRed
            title:@"Login with twitter failed !"
            linedBackground:AJLinedBackgroundTypeAnimated  hideAfter:2.5f response:^{}];
        if (_panel) {
            [_panel hide];
        }
    }
}
- (void) facebookSessionChangedNotification:(NSNotification*)notification {
    FBSession *session = [[notification userInfo] objectForKey:@"session"];
    if (session.state == FBSessionStateOpen && self.loginWithFacebookSuccessful != nil) {
        self.loginWithFacebookSuccessful();
    } else {
        _panel = [AJNotificationView showNoticeInView:self.view
            type:AJNotificationTypeRed
            title:@"Login with facebook failed !"
            linedBackground:AJLinedBackgroundTypeAnimated  hideAfter:2.5f response:^{}];
        if (_panel) {
            [_panel hide];
        }
    }
}

- (IBAction)loginWithFacebook:(id)sender {
    [ApplicationDelegate openSession];
}
- (IBAction)loginWithTwitter:(id)sender {
    [ApplicationDelegate getTwitterOAuthTokenUsingReverseOAuth];
}
@end
