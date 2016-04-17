//
//  RCTRongCloud.h
//  RCTRongCloud
//
//  Created by LvBingru on 1/26/16.
//  Copyright © 2016 erica. All rights reserved.
//

#import "RCTBridgeModule.h"

@interface RCTRongCloud : NSObject <RCTBridgeModule>

+ (void)registerAPI:(NSString *)aString;
+ (void)setDeviceToken:(NSData *)aToken;

@end
