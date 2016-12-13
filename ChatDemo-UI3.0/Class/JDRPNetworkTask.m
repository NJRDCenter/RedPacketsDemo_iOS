//
//  JDRPNetworkTask.m
//  JDRedPacketsLib
//
//  Created by xwxing on 16/6/29.
//  Copyright © 2016年 JD. All rights reserved.
//

#import "JDRPNetworkTask.h"

#define kNetworkFail            @"网络异常，无网络连接，请检查您的网络。"

#define kServerUrl              @"https://mt.jdpay.com/"        //线上环境
//#define kServerUrl              @"http://172.24.9.200:8091/"    //测试环境

@implementation JDRPNetworkTask

#pragma mark
#pragma mark - 发送网络请求
+ (void)startNetworkTask:(NSDictionary *)params
                callback:(JDRPNetworkCompletionBlock)completionBlock
{
    //网络请求
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];

    NSURLSession *mySession = [NSURLSession sessionWithConfiguration:configuration];
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",kServerUrl,@"redpkgop/im/sign/",params[@"userId"]]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    request.HTTPMethod= @"POST";
    [request addValue:@"application/text" forHTTPHeaderField:@"Content-Type"];

#ifdef JDRP_PRINTF_LOG
    NSLog(@"request params = \n%@",paramsDic);
#endif
//    NSString *userId = params[@"userId"];
//    request.HTTPBody= [userId dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSessionDataTask * task = [mySession dataTaskWithRequest:request completionHandler:^(NSData* _Nullable data,NSURLResponse* _Nullable response,NSError* _Nullable error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                //接口访问失败
                completionBlock(1,kNetworkFail,nil);
            }
            else
            {
                //接口访问成功
                //JSON解析
                NSError * parseError1 =nil;
//                NSDictionary * dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&parseError1];
                NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//#ifdef JDRP_PRINTF_LOG
                NSLog(@"response str = \n%@",str);
//#endif
                
                if (parseError1) {
                    //                    NSLog(@"JSON解析错误");
                    if (completionBlock) {
                        completionBlock(1,kNetworkFail,nil);
                    }
                    return;
                }
                
                if (str) {
                    if (completionBlock) {
                        completionBlock(0,@"",str);
                    }
                }else
                {
                    if (completionBlock) {
                        completionBlock(1,kNetworkFail,nil);
                    }
                }
                
            }
        });
    }];
    
    [task resume];
}

@end
