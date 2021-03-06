//
//  AboutViewController.h
//  VCard HD
//
//  Created by Hasky on 11-3-1.
//  Copyright 2011 同济大学. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#define kNotificationNameTellFriends @"kNotificationNameTellAFriend"
#define kNotificationNameShouldDismissPopoverView @"kNotificationNameShouldDismissPopoverView"

@interface AboutViewController : UIViewController <MFMailComposeViewControllerDelegate, UIAlertViewDelegate> {
	UIButton *_followButton;
}

@property (nonatomic, retain) IBOutlet UIButton* followButton;

- (IBAction)rate:(UIButton *)sender;
- (IBAction)followAuthor:(UIButton *)sender;
- (IBAction)tellFriends:(UIButton *)sender;
- (IBAction)otherApps:(UIButton *)sender;
- (IBAction)feedback:(UIButton *)sender;

@end
