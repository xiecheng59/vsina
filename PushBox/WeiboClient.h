//
//  WeiboClient.h
//  PushboxHD
//
//  Created by Xie Hasky on 11-7-23.
//  Copyright 2011年 同济大学. All rights reserved.
//

#import "OAuthHTTPRequest.h"

@class WeiboClient;

enum {
    ResetUnreadCountTypeComments = 1,
    ResetUnreadCountTypeReferMe = 2,
    ResetUnreadCountTypeDirectMessage = 3,
    ResetUnreadCountTypeFollowers = 4,
};

typedef void (^WCCompletionBlock)(WeiboClient *client);

@interface WeiboClient : NSObject <ASIHTTPRequestDelegate> {
    BOOL _hasError;
    NSString* _errorDesc;
    int _responseStatusCode;
    id _responseJSONObject;
    WCCompletionBlock _completionBlock;
}

@property (nonatomic, assign) BOOL hasError;
@property (nonatomic, copy) NSString* errorDesc;

// Status code generated by server side application
@property (nonatomic, assign) int responseStatusCode;

// NSDictionary or NSArray
@property (nonatomic, retain) id responseJSONObject;

- (void)setCompletionBlock:(void (^)(WeiboClient* client))completionBlock;
- (WCCompletionBlock)completionBlock;

// return an autoreleased object, while gets released after one of following calls complete
+ (id)client;

// return true if user already logged in
+ (BOOL)authorized;
+ (void)signout;
+ (NSString *)currentUserID;

- (void)authWithUsername:(NSString *)username password:(NSString *)password autosave:(BOOL)autosave;

- (void)getFriendsTimelineSinceID:(NSString *)sinceID 
                            maxID:(NSString *)maxID 
                   startingAtPage:(int)page 
                            count:(int)count
                          feature:(int)feature;

- (void)getUserTimeline:(NSString *)userID 
				SinceID:(NSString *)sinceID 
                  maxID:(NSString *)maxID 
		 startingAtPage:(int)page 
				  count:(int)count
                feature:(int)feature;

- (void)getCommentsToMeSinceID:(NSString *)sinceID 
                         maxID:(NSString *)maxID 
                          page:(int)page 
                         count:(int)count;

- (void)getCommentsOfStatus:(NSString *)statusID
                       page:(int)page
                      count:(int)count;

- (void)getCommentsAndRepostsCount:(NSArray *)statusIDs;

- (void)getUser:(NSString *)userID;

- (void)getFriendsOfUser:(NSString *)userID cursor:(int)cursor count:(int)count;
- (void)getFollowersOfUser:(NSString *)userID cursor:(int)cursor count:(int)count;

- (void)follow:(NSString *)userID;
- (void)unfollow:(NSString *)userID;

- (void)favorite:(NSString *)statusID;
- (void)unFavorite:(NSString *)statusID;

- (void)post:(NSString *)text;
- (void)post:(NSString *)text withImage:(UIImage *)image;
- (void)repost:(NSString *)statusID 
          text:(NSString *)text 
 commentStatus:(BOOL)commentStatus 
 commentOrigin:(BOOL)commentOrigin;

- (void)comment:(NSString *)statusID 
            cid:(NSString *)cid 
           text:(NSString *)text
  commentOrigin:(BOOL)commentOrigin;

- (void)destroyStatus:(NSString *)statusID;

- (void)getFavoritesByPage:(int)page;

- (void)getRelationshipWithUser:(NSString *)userID;

- (void)getUnreadCountSinceStatusID:(NSString *)statusID;
- (void)resetUnreadCount:(int)type;
- (void)getSearchStatuses:(NSString *)q
               filter_ori:(int)filter_ori 
               filter_pic:(int)filter_pic
                     fuid:(int64_t)fuid 
                 province:(int)province
                     city:(int)city 
                starttime:(int64_t)starttime
                  endtime:(int64_t)endtime 
                    count:(int)count
                     page:(int)page 
                needcount:(Boolean)needcount
                 base_app:(int)base_app;

- (void)getMessagesByUserSinceID:(NSString *)sinceID 
                           maxID:(NSString *)maxID 
                           count:(int)count
                            page:(int)page;

@end
