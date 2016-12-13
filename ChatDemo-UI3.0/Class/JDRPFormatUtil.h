//
//  JDRPFormatUtil.h
//  ChatDemo-UI3.0
//
//  Created by xwxing on 2016/11/24.
//  Copyright © 2016年 xwxing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JDRPFormatUtil : NSObject

+ (NSDictionary *)changeSendInfoToMessage:(NSDictionary *)sendInfo;

+ (NSDictionary *)changeGrabInfoToMessage:(NSDictionary *)grabInfo;

@end
