//
//  JDRPFormatUtil.m
//  ChatDemo-UI3.0
//
//  Created by xwxing on 2016/11/24.
//  Copyright © 2016年 xwxing. All rights reserved.
//

#import "JDRPFormatUtil.h"
#import "JDRPOpenConst.h"

@implementation JDRPFormatUtil

+ (NSDictionary *)changeSendInfoToMessage:(NSDictionary *)sendInfo
{
    NSMutableDictionary *sendDic = @{}.mutableCopy;
    if (sendInfo[@"redpkgId"]) {
        [sendDic setValue:sendInfo[@"redpkgId"] forKey:MESSAGE_ATTR_REDPKG_ID];
    }
    if ([EMClient sharedClient].currentUsername) {
        [sendDic setValue:[EMClient sharedClient].currentUsername forKey:MESSAGE_ATTR_SENDER_USERID];
    }
    if (sendInfo[@"content"]) {
        [sendDic setValue:sendInfo[@"content"] forKey:MESSAGE_ATTR_REDPKG_DESC];
    }
    if (sendInfo[@"redpkgExtType"]) {
        [sendDic setValue:sendInfo[@"redpkgExtType"] forKey:MESSAGE_ATTR_REDPKG_TYPE];
    }
    [sendDic setValue:@YES forKey:MESSAGE_ATTR_IS_RED_PACKET_MESSAGE];
    return sendDic;
}

+ (NSDictionary *)changeGrabInfoToMessage:(NSDictionary *)grabInfo
{
    NSMutableDictionary *grabDic = @{}.mutableCopy;
    if ([EMClient sharedClient].currentUsername) {
        [grabDic setValue:[EMClient sharedClient].currentUsername forKey:MESSAGE_ATTR_REV_RECEIVER_USERID];
    }
    if (grabInfo[@"senderUserId"]) {
        [grabDic setValue:grabInfo[@"senderUserId"] forKey:MESSAGE_ATTR_REV_SENDER_USERID];
    }
    [grabDic setValue:@YES forKey:MESSAGE_ATTR_REV_IS_RED_PACKET_MESSAGE];
    return grabDic;
}

@end
