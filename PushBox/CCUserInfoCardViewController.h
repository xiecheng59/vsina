//
//  CCUserInfoCardViewController.h
//  PushBox
//
//  Created by Gabriel Yeah on 11-10-16.
//  Copyright (c) 2011年 同济大学. All rights reserved.
//

#import "UserCardBaseViewController.h"

@interface CCUserInfoCardViewController : UserCardBaseViewController{
	UIImageView *_newFriendsImageView;
}

@property(nonatomic, retain) IBOutlet UIImageView* newFriendsImageView;

@end