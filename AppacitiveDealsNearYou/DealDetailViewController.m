//
//  DealDetailViewController.m
//  AppacitiveDealsNearYou
//
//  Created by Sonia Mane on 21/01/13.
//  Copyright (c) 2013 Appacitive. All rights reserved.
//

#import "DealDetailViewController.h"
#import <JSNotifier.h>

@interface DealDetailViewController () {
    int _voteCount;
    JSNotifier *_notifier;
    __block AJNotificationView *_panel;
}
@property (weak, nonatomic) IBOutlet UIImageView *selectedDealImage;
@property (weak, nonatomic) IBOutlet UILabel *votes;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIButton *upvoteButton;
@end

@implementation DealDetailViewController

- (void) setDeal:(Deal *)deal {
    _deal = deal;
    NSString *query = [NSString stringWithFormat:@"articleId=%@&label=%@", [deal.objectId description],@"user"];
    
    [APConnection
     searchForConnectionsWithRelationType:@"vote"
     withQueryString:query
     successHandler:^(NSDictionary *result) {
         NSArray *connections = [result objectForKey:@"connections"];
         if ([connections count] == 0) {
             _voteCount = 0;
         } else {
             _voteCount = connections.count;
         }
         [self.votes setText:[NSString stringWithFormat:@"%d",_voteCount]];
         [self.activityIndicatorView stopAnimating];
         self.upvoteButton.enabled = YES;

     } failureHandler:^(APError *error) {
         [self.activityIndicatorView stopAnimating];
     }];
}

-(void)viewDidLoad {
    [self.upvoteButton setEnabled:NO];
}

- (IBAction)upvoteButtonPressed:(id)sender {
    
    _panel = [AJNotificationView showNoticeInView:self.view
                                             type:AJNotificationTypeBlue
                                            title:@"Updating Vote Count..!"
                                  linedBackground:AJLinedBackgroundTypeAnimated
                                        hideAfter:5.5f response:^{}];
    if (_panel)
        [_panel hide];
    
    [_upvoteButton setEnabled:NO];

    APUser *currentUser = [APUser currentUser];

    APConnection *connection = [APConnection connectionWithRelationType:@"vote"];
    [connection createConnectionWithObjectAId:currentUser.objectId
                                    objectBId:self.deal.objectId
                                       labelA:@"user"
                                       labelB:@"deal"
                               successHandler:^(){
                                   
                                   self.upvoteButton.enabled = YES;
                                   
                                   _voteCount = _voteCount + 1;
                                   [_votes setText:[NSString stringWithFormat:@"%d",_voteCount]];

                                   _panel = [AJNotificationView showNoticeInView:self.view
                                                type:AJNotificationTypeGreen
                                                title:@"Vote count updated!"
                                                linedBackground:AJLinedBackgroundTypeAnimated
                                                hideAfter:5.5f response:^{}];
                                   if (_panel)
                                       [_panel hide];

                               } failureHandler:^(APError *error) {
                                   NSLog(@"The error is %@",[error description]);

                                   if(error.code == 7006) {
                                       _panel = [AJNotificationView showNoticeInView:self.view
                                                    type:AJNotificationTypeRed
                                                    title:@"You have already upvoted this deal."
                                                    linedBackground:AJLinedBackgroundTypeAnimated
                                                    hideAfter:5.5f response:^{}];
                                       if (_panel)
                                           [_panel hide];

                                   } else {
                                       self.upvoteButton.enabled = YES;

                                       _panel = [AJNotificationView showNoticeInView:self.view
                                                    type:AJNotificationTypeRed
                                                    title:@"Error while updating vote count!"
                                                    linedBackground:AJLinedBackgroundTypeAnimated
                                                    hideAfter:5.5f response:^{}];
                                       if (_panel)
                                           [_panel hide];
                                   }
                               }];
}

@end
