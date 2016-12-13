//
//  JDRPNetworkTask.h
//  JDRedPacketsLib
//
//  Created by xwxing on 16/6/29.
//  Copyright © 2016年 JD. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *  响应结果回调
 *
 *  @param resultCode 返回码 0 成功 1 错误弹框 -1 跳转错误页面
 *  @param resultMsg  返回描述
 *  @param resultInfo 返回结果
 */
typedef void(^JDRPNetworkCompletionBlock)(NSInteger resultCode,NSString *resultMsg,id resultInfo);


@interface JDRPNetworkTask : NSObject

/**
 *  网络请求公共方法
 *
 *  @param params          请求参数
 *  @param completionBlock 结果回调block
 */
+ (void)startNetworkTask:(NSDictionary *)params
                callback:(JDRPNetworkCompletionBlock)completionBlock;

@end
