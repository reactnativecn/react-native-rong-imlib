//
//  RCTRongCloudVoiceManager.m
//  RCTRongCloud
//
//  Created by LvBingru on 4/18/16.
//  Copyright © 2016 erica. All rights reserved.
//

#import "RCTRongCloudVoiceManager.h"
#import <AVFoundation/AVAudioRecorder.h>
#import <AVFoundation/AVAudioPlayer.h>
#import <AVFoundation/AVAudioSession.h>
#import <RongIMLib/RongIMLib.h>

@interface RCTRongCloudVoiceManager ()<AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic, strong) NSString *recordWavFilePath;
@property (nonatomic, assign) NSTimeInterval duration;

@property (nonatomic, copy) RCVoiceResultBlock finishRecordBlock;
@property (nonatomic, copy) RCVoiceResultBlock finishPlayBlock;

@end


@implementation RCTRongCloudVoiceManager

//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//    }
//    
//    return self;
//}

- (void)dealloc
{
    [self.player setDelegate:nil];
    [self.recorder setDelegate:nil];
    
    if (self.player && self.player.isPlaying)
    {
        [self.player stop];
    }
    
    if (self.recorder && self.recorder.isRecording)
    {
        [self.recorder stop];
    }
}

- (void)canRecordVoice:(RCVoiceResultBlock)result
{
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            result(nil, nil);
        }
        else {
            result([self _errorWithMessage:@"record not granted"], nil);
        }
    }];
}

- (void)startRecord:(RCVoiceResultBlock)result;
{
    [self cancelRecord];
    
    NSError *error = nil;
    // 初始化
    if (self.recorder == nil)
    {
        error = [self _prepareRecorder];
        if (error) {
            result(error, nil);
            return;
        }
    }
    [self.recorder setDelegate:self];

    // 设置环境
    error = [[self class] activeAudioSessionWithCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker];
    if (error) {
        result(error, nil);
        return;
    }
    
    // 准备录音
    BOOL success = [self.recorder prepareToRecord];
    if (!success) {
        result([self _errorWithMessage:@"recorder prepareToRecord failed"], nil);
        return;
    }
    
    // 开始录音
    success = [self.recorder record];
    if (!success) {
        result([self _errorWithMessage:@"record failed"], nil);
        return;
    }
    
    [self setFinishRecordBlock:result];
}

- (void)startPlayVoice:(RCVoiceMessage *)voice result:(RCVoiceResultBlock)result
{
    [self cancelPlay];
    
    // 初始化
    NSError *error = [self _preparePlayer:voice];
    if (error) {
        result(error, nil);
        return;
    }
    
    if (self.player == nil)
    {
        result([self _errorWithMessage:@"player null"], nil);
        return;
    }
    
    [self.player setDelegate:self];
    
    // 配置环境
    error = [[self class] activeAudioSessionWithCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker];
    if (error) {
        result(error, nil);
        return;
    }
    
    // 准备播放
    BOOL success = [self.player prepareToPlay];
    if (!success) {
        result([self _errorWithMessage:@"player prepareToPlay failed"], nil);
        return;
    }
    
    // 开始播放
    success = [self.player play];
    if (!success) {
        result([self _errorWithMessage:@"play failed"], nil);
        return;
    }
    
    [self setFinishPlayBlock:result];
    
}


- (void)cancelRecord
{
    if (self.finishRecordBlock) {
        [self.recorder setDelegate:nil];
        
        [self.recorder stop];
        self.finishRecordBlock([self _errorWithMessage:@"recorder cancelled"], nil);
        [self setFinishRecordBlock:nil];
        [[self class] deactiveAudioSession];
    }
}

- (void)finishRecord
{
    if (!self.recorder.recording) {
        [self cancelRecord];
    }
    else {
        [self setDuration:self.recorder.currentTime];
        [self.recorder stop];
    }
}

- (void)cancelPlay
{
    if (self.finishPlayBlock) {
        [self.recorder setDelegate:nil];
        [self.recorder stop];
        
        self.finishPlayBlock([self _errorWithMessage:@"play cancelled"], nil);
        [self setFinishPlayBlock:nil];
        [[self class] deactiveAudioSession];
    }
}

- (void)stopPlayVoice
{
    if (!self.player.isPlaying) {
        [self cancelPlay];
    }
    else {
        [self.player stop];
    }
}

#pragma mark - private

- (NSError *)_prepareRecorder
{
    //初始化录音
    NSDictionary *settings = @{AVFormatIDKey: @(kAudioFormatLinearPCM),
                               AVSampleRateKey: @8000.00f,
                               AVNumberOfChannelsKey: @1,
                               AVLinearPCMBitDepthKey: @16,
                               AVLinearPCMIsNonInterleaved: @NO,
                               AVLinearPCMIsFloatKey: @NO,
                               AVLinearPCMIsBigEndianKey: @NO};
    
    NSString *tempPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];

    NSString *savePath = [tempPath stringByAppendingPathComponent:[NSString stringWithFormat:@"tempRecorderVoice%lld", (long long)([[NSDate date] timeIntervalSince1970]*1000)]];
    [self setRecordWavFilePath:savePath];
    
    NSURL *outputFileURL = [NSURL fileURLWithPath:self.recordWavFilePath];
    
    NSError *error;
    AVAudioRecorder *recoder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:settings  error:&error];
    if (error)
    {
        return error;
    }
    
    [self setRecorder:recoder];
    return nil;
}

- (NSError *)_preparePlayer:(RCVoiceMessage *)voice
{
    NSError *error = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithData:voice.wavAudioData error:&error];
    
    if (error)
    {
        [self setPlayer:nil];
        return error;
    }
    [self setPlayer:player];
    
    return nil;
}

- (NSError *)_errorWithMessage:(NSString *)errorMessage
{
    return [NSError errorWithDomain:@"cn.reactnative.rongcloud"
                               code:-1
                           userInfo:@{ NSLocalizedDescriptionKey: errorMessage}];
}


#pragma mark - Recorder Delegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag
{
    if (self.finishRecordBlock) {
        if (flag == YES)
        {
            NSData *data = [NSData dataWithContentsOfFile:self.recordWavFilePath];
            NSString *base64 = [data base64EncodedStringWithOptions:0];
            NSDictionary *body = @{
                                   @"base64":base64,
                                   @"type":@"voice",
                                   @"duration":@(self.duration * 1000)
                                   };
            
            self.finishRecordBlock(nil,body);
            [self setFinishRecordBlock:nil];
        }
        else
        {
            self.finishRecordBlock([self _errorWithMessage:@"record failed"], nil);
            [self setFinishRecordBlock:nil];
        }
    }
    [[self class] deactiveAudioSession];
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    if (self.finishRecordBlock) {
        self.finishRecordBlock([self _errorWithMessage:@"record failed"], nil);
        [self setFinishRecordBlock:nil];
    }
    [[self class] deactiveAudioSession];
}

#pragma mark - Player Delegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if (self.finishPlayBlock) {
        if (flag == YES)
        {
            self.finishPlayBlock(nil, nil);
            [self setFinishPlayBlock:nil];
        }
        else
        {
            self.finishPlayBlock([self _errorWithMessage:@"play failed"], nil);
            [self setFinishPlayBlock:nil];
        }
    }
    [[self class] deactiveAudioSession];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    if (self.finishPlayBlock) {
        self.finishPlayBlock([self _errorWithMessage:@"play failed"], nil);
        [self setFinishPlayBlock:nil];
    }
    [[self class] deactiveAudioSession];
}

#pragma mark - context

+ (NSError *)activeAudioSession
{
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    return error;
}

+ (NSError *)deactiveAudioSession
{
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    return error;
}

+ (NSError *)activeAudioSessionWithCategory:(NSString*)category withOptions:(AVAudioSessionCategoryOptions)options
{
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    if(!options)
    {
        [audioSession setCategory:category error:&error];
    }
    else
    {
        [audioSession setCategory:category withOptions:options error:&error];
    }
    
    if(!error)
    {
        [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    }
    return error;
}

+ (NSError *)deactiveAudioSessionWithCategory:(NSString*)category
{
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ret = [audioSession setCategory:category error:&error];
    
    if(ret)
    {
        [audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    }
    return error;
}


@end
