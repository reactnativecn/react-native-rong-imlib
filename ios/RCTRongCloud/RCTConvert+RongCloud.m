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
    NSString *type = [RCTConvert NSString:json[@"type"]];
    
    if ([@"text" isEqualToString:type]) {
        RCTextMessage* ret = [RCTextMessage messageWithContent:json[@"content"]];
        ret.extra = [RCTConvert NSString:json[@"extra"]];
        return ret;
    } else if ([@"voice" isEqualToString:type]) {
        NSString *base64 = [RCTConvert NSString:json[@"base64"]];
        NSData *voice = [[NSData alloc] initWithBase64EncodedString:base64 options:0];
        long long duration = [RCTConvert int64_t:json[@"duration"]];
        
        RCVoiceMessage *ret = [RCVoiceMessage messageWithAudio:voice duration:duration];
        ret.extra = [RCTConvert NSString:json[@"extra"]];
        return ret;
    } else if ([@"image" isEqualToString:type]) {
        NSString * uri = [RCTConvert NSString:json[@"imageUrl"]];
        RCImageMessage *ret = [RCImageMessage messageWithImageURI:uri];
        ret.full = [json[@"full"] boolValue];
        ret.extra = [RCTConvert NSString:json[@"extra"]];
        return ret;
    } else if ([@"notify" isEqualToString:type]) {
        NSString * name = [RCTConvert NSString:json[@"name"]];
        NSString * data =[RCTConvert NSString:json[@"data"]];
        RCCommandNotificationMessage* ret = [RCCommandNotificationMessage notificationWithName:name data:data];
        return ret;
    }
    else {
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
                                          @"customer_service": @(ConversationType_CUSTOMERSERVICE),
                                          @"system": @(ConversationType_SYSTEM),
                                          @"app_service": @(ConversationType_APPSERVICE),
                                          @"publish_service": @(ConversationType_PUBLICSERVICE),
                                          @"push_service": @(ConversationType_PUSHSERVICE)
                                 }), ConversationType_PRIVATE, unsignedIntegerValue)

@end
