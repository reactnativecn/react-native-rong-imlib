//
//  RCTCovert+RongCloud.m
//  RCTRongCloud
//
//  Created by LvBingru on 1/26/16.
//  Copyright © 2016 erica. All rights reserved.
//

#import "RCTConvert+RongCloud.h"

@implementation RCTConvert(RongCloud)

+ (RCMessageContent *)RCMessageContent:(id)json;
{
    json = [self NSDictionary:json];
    
    if ([@"text" isEqualToString:json[@"type"]]) {
        RCTextMessage* ret = [RCTextMessage messageWithContent:json[@"content"]];
        ret.extra = [json objectForKey:@"extra"];
        return ret;
    } else {
        RCTextMessage* ret = [RCTextMessage messageWithContent:@"[未知消息]"];
        return ret;
    }
//    RCUserInfo *userInfo = [[RCUserInfo alloc] initWithUserId:json[@"userId"] name:json[@"name"] portrait:json[@"portraitUri"]];
//    return userInfo;
}

RCT_ENUM_CONVERTER(RCConversationType, (@{
                                          @"private": @(ConversationType_PRIVATE),
                                          @"discussion": @(ConversationType_DISCUSSION),
                                          @"group": @(ConversationType_GROUP),
                                          @"chatroom": @(ConversationType_CHATROOM),
                                          @"customerService": @(ConversationType_CUSTOMERSERVICE),
                                          @"system": @(ConversationType_SYSTEM),
                                          @"appService": @(ConversationType_APPSERVICE),
                                          @"publishService": @(ConversationType_PUBLICSERVICE),
                                          @"pushService": @(ConversationType_PUSHSERVICE)
                                 }), ConversationType_PRIVATE, unsignedIntegerValue)

@end
