//
//  RCTRongCloudVoiceManager.h
//  RCTRongCloud
//
//  Created by LvBingru on 4/18/16.
//  Copyright © 2016 erica. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCVoiceMessage;

typedef void (^RCVoiceResultBlock)(NSError *error, NSDictionary *result);

@interface RCTRongCloudVoiceManager : NSObject

- (void)canRecordVoice:(RCVoiceResultBlock)result;
- (void)startRecord:(RCVoiceResultBlock)result;
- (void)cancelRecord;
- (void)finishRecord;
- (void)startPlayVoice:(RCVoiceMessage *)voice result:(RCVoiceResultBlock)result;
- (void)stopPlayVoice;

@end
