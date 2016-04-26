//
//  RCTRongCloud.m
//  RCTRongCloud
//
//  Created by LvBingru on 1/26/16.
//  Copyright © 2016 erica. All rights reserved.
//

#import "RCTRongCloud.h"
#import <RongIMLib/RongIMLib.h>
#import "RCTConvert+RongCloud.h"
#import "RCTUtils.h"
#import "RCTEventDispatcher.h"
#import "RCTRongCloudVoiceManager.h"

#define OPERATION_FAILED (@"operation returns false.")

@interface RCTRongCloud()<RCIMClientReceiveMessageDelegate>

@property (nonatomic, strong) NSMutableDictionary *userInfoDic;
@property (nonatomic, strong) RCTRongCloudVoiceManager *voiceManager;

@end

@implementation RCTRongCloud

RCT_EXPORT_MODULE(RCTRongIMLib);

@synthesize bridge = _bridge;

- (NSDictionary *)constantsToExport
{
    return @{};
};

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[RCIMClient sharedRCIMClient] setReceiveMessageDelegate:self object:nil];
        _voiceManager = [RCTRongCloudVoiceManager new];
    }
    return self;
}

- (void)dealloc
{
    RCIMClient* client = [RCIMClient sharedRCIMClient];
    [client disconnect];
    [client setReceiveMessageDelegate:nil object:nil];
}

+ (void)registerAPI:(NSString *)aString
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[RCIMClient sharedRCIMClient] initWithAppKey:aString];
    });
}

+ (void)setDeviceToken:(NSData *)aToken
{
    NSString *token =
    [[[[aToken description] stringByReplacingOccurrencesOfString:@"<"
                                                      withString:@""]
      stringByReplacingOccurrencesOfString:@">"
      withString:@""]
     stringByReplacingOccurrencesOfString:@" "
     withString:@""];
    
    [[RCIMClient sharedRCIMClient] setDeviceToken:token];
}

RCT_EXPORT_METHOD(connect:(NSString *)token resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    [[RCIMClient sharedRCIMClient] connectWithToken:token success:^(NSString *userId) {
        // Connect 成功
        resolve(userId);
    } error:^(RCConnectErrorCode status) {
        // Connect 失败
        reject([NSString stringWithFormat:@"%d", (int)status], @"Connection error", nil);
    }
                                     tokenIncorrect:^() {
                                         // Token 失效的状态处理
                                         reject(@"tokenIncorrect", @"Incorrect token provided.", nil);
                                     }];
}

// 断开与融云服务器的连接，并不再接收远程推送
RCT_EXPORT_METHOD(logout:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    [[RCIMClient sharedRCIMClient] logout];
    resolve(nil);
}

// 断开与融云服务器的连接，但仍然接收远程推送
RCT_EXPORT_METHOD(disconnect:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    [[RCIMClient sharedRCIMClient] disconnect];
    resolve(nil);
}

RCT_EXPORT_METHOD(getConversationList:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    NSArray *array = [[RCIMClient sharedRCIMClient] getConversationList:@[@(ConversationType_PRIVATE),
                                                                          @(ConversationType_DISCUSSION),
                                                                          @(ConversationType_GROUP),
                                                                          @(ConversationType_CHATROOM),
                                                                          @(ConversationType_CUSTOMERSERVICE),
                                                                          @(ConversationType_SYSTEM),
                                                                          @(ConversationType_APPSERVICE),
                                                                          @(ConversationType_PUBLICSERVICE),
                                                                          @(ConversationType_PUSHSERVICE)]];
    NSMutableArray *newArray = [NSMutableArray new];
    for (RCConversation *conv in array) {
        NSDictionary *convDic = [self.class _convertConversation:conv];
        [newArray addObject:convDic];
    }
    resolve(newArray);
}

RCT_EXPORT_METHOD(getLatestMessages: (RCConversationType) type targetId:(NSString*) targetId count:(int) count
                  resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    NSArray* array = [[RCIMClient sharedRCIMClient] getLatestMessages:type targetId:targetId count:count];
    
    NSMutableArray* newArray = [NSMutableArray new];
    for (RCMessage* msg in array) {
        NSDictionary* convDic = [self.class _convertMessage:msg];
        [newArray addObject:convDic];
    }
    resolve(newArray);
}

RCT_EXPORT_METHOD(sendMessage: (RCConversationType) type targetId:(NSString*) targetId content:(RCMessageContent*) content
                  pushContent: (NSString*) pushContent pushData:(NSString*) pushData
                  resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    RCIMClient* client = [RCIMClient sharedRCIMClient];
    RCMessage* msg = [client sendMessage:type targetId:targetId content:content pushContent:pushContent
                success:^(long messageId){
                    [_bridge.eventDispatcher sendAppEventWithName:@"msgSendOk" body:@(messageId)];
                } error:^(RCErrorCode code, long messageId){
                    NSMutableDictionary* dic = [NSMutableDictionary new];
                    dic[@"messageId"] = @(messageId);
                    dic[@"errCode"] = @((int)code);
                    [_bridge.eventDispatcher sendAppEventWithName:@"msgSendFailed" body:dic];
                }];
    resolve([self.class _convertMessage:msg]);
}

RCT_EXPORT_METHOD(canRecordVoice:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    [_voiceManager canRecordVoice:^(NSError *error, NSDictionary *result) {
        if (error) {
            reject([NSString stringWithFormat:@"%ld", error.code], error.description, error);
        }
        else {
            resolve(result);
        }
    }];
}

RCT_EXPORT_METHOD(startRecordVoice:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    [_voiceManager startRecord:^(NSError *error,NSDictionary *result) {
        if (error) {
            reject([NSString stringWithFormat:@"%ld", error.code], error.description, error);
        }
        else {
            resolve(result);
        }
    }];
}

RCT_EXPORT_METHOD(cancelRecordVoice)
{
    [_voiceManager cancelRecord];
}

RCT_EXPORT_METHOD(finishRecordVoice)
{
    [_voiceManager finishRecord];
}

RCT_EXPORT_METHOD(startPlayVoice:(RCMessageContent *)voice rosolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)
{
    [_voiceManager startPlayVoice:(RCVoiceMessage *)voice result:^(NSError *error, NSDictionary *result) {
        if (error) {
            reject([NSString stringWithFormat:@"%ld", error.code], error.description, error);
        }
        else {
            resolve(result);
        }
    }];
}

RCT_EXPORT_METHOD(stopPlayVoice)
{
    [_voiceManager stopPlayVoice];
}

#pragma mark - delegate
- (void)onReceived:(RCMessage *)message
              left:(int)nLeft
            object:(id)object
{
    [_bridge.eventDispatcher sendAppEventWithName:@"rongIMMsgRecved" body:[self.class _convertMessage:message]];
}

#pragma mark - private

+ (NSDictionary *)_convertConversation:(RCConversation *)conversation
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    dic[@"title"] = conversation.conversationTitle;
    dic[@"type"] = @(conversation.conversationType);
    dic[@"targetId"] = conversation.targetId;
    dic[@"unreadCount"] = @(conversation.unreadMessageCount);
    dic[@"lastMessage"] = [self _converMessageContent:conversation.lastestMessage];
    
    dic[@"isTop"] = @(conversation.isTop);
    dic[@"receivedStatus"] = @(conversation.receivedStatus);
    dic[@"sentStatus"] = @(conversation.sentStatus);
    dic[@"receivedTime"] = @(conversation.receivedTime);
    dic[@"sentTime"] = @(conversation.sentTime);
    dic[@"draft"] = conversation.draft;
    dic[@"objectName"] = conversation.objectName;
    dic[@"senderUserId"] = conversation.senderUserId;
    dic[@"jsonDict"] = conversation.jsonDict;
    dic[@"lastestMessageId"] = @(conversation.lastestMessageId);
    return dic;
}

+ (NSDictionary *)_convertMessage:(RCMessage *)message
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    dic[@"senderId"] = message.senderUserId;
    dic[@"targetId"] = message.targetId;
    dic[@"conversationType"] = @(message.conversationType);
    dic[@"extra"] = message.extra;
    dic[@"messageId"] = @(message.messageId);
    dic[@"receivedTime"] = @(message.receivedTime);
    dic[@"sentTime"] = @(message.sentTime);
    dic[@"content"] = [self _converMessageContent:message.content];

    dic[@"messageDirection"] = @(message.messageDirection);
    dic[@"receivedStatus"] = @(message.receivedStatus);
    dic[@"sentStatus"] = @(message.sentStatus);
    dic[@"objectName"] = message.objectName;
    dic[@"messageUId"] = message.messageUId;
    return dic;
}

+ (NSDictionary *)_converMessageContent:(RCMessageContent *)messageContent
{
    NSMutableDictionary *dic = [NSMutableDictionary new];
    if ([messageContent isKindOfClass:[RCTextMessage class]]) {
        RCTextMessage *message = (RCTextMessage *)messageContent;
        dic[@"type"] = @"text";
        dic[@"content"] = message.content;
        dic[@"extra"] = message.extra;
    }
    else if ([messageContent isKindOfClass:[RCVoiceMessage class]]) {
        RCVoiceMessage *message = (RCVoiceMessage *)messageContent;
        dic[@"type"] = @"voice";
        dic[@"duration"] = @(message.duration);
        dic[@"extra"] = message.extra;
        if (message.wavAudioData) {
            dic[@"base64"] = [message.wavAudioData base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
        }
    }
    else if ([messageContent isKindOfClass:[RCImageMessage class]]) {
        RCImageMessage *message = (RCImageMessage*)messageContent;
        dic[@"type"] = @"image";
        dic[@"imageUrl"] = message.imageUrl;
        dic[@"thumb"] = [NSString stringWithFormat:@"data:image/png;base64,%@", [UIImagePNGRepresentation(message.thumbnailImage) base64EncodedStringWithOptions:0]];
        dic[@"extra"] = message.extra;
    }
    else if ([messageContent isKindOfClass:[RCCommandNotificationMessage class]]){
        RCCommandNotificationMessage * message = (RCCommandNotificationMessage*)messageContent;
        dic[@"type"] = @"notify";
        dic[@"name"] = message.name;
        dic[@"data"] = message.data;
    }
    else {
        dic[@"type"] = @"unknown";
    }
    return dic;
}

@end
