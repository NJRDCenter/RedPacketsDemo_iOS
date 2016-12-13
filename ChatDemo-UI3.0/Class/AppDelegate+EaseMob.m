/************************************************************
 *  * Hyphenate CONFIDENTIAL
 * __________________
 * Copyright (C) 2016 Hyphenate Inc. All rights reserved.
 *
 * NOTICE: All information contained herein is, and remains
 * the property of Hyphenate Inc.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Hyphenate Inc.
 */

#import "AppDelegate+EaseMob.h"
#import "AppDelegate+EaseMobDebug.h"
#import "AppDelegate+Parse.h"

#import "EMNavigationController.h"
#import "LoginViewController.h"
#import "ChatUIHelper.h"
#import "MBProgressHUD.h"
#import "JDRPNetworkTask.h"
#import <JDRedPacketsSDK/JDRedPacketsSDK.h>
#import <JDRedPacketsSDK/JDRPApiObject.h>

/**
 *  本类中做了EaseMob初始化和推送等操作
 */

@implementation AppDelegate (EaseMob)

- (void)easemobApplication:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
                    appkey:(NSString *)appkey
              apnsCertName:(NSString *)apnsCertName
               otherConfig:(NSDictionary *)otherConfig
{
    //注册登录状态监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loginStateChange:)
                                                 name:KNOTIFICATION_LOGINCHANGE
                                               object:nil];
    
    [[EaseSDKHelper shareHelper] hyphenateApplication:application
                    didFinishLaunchingWithOptions:launchOptions
                                           appkey:appkey
                                     apnsCertName:apnsCertName
                                      otherConfig:@{kSDKConfigEnableConsoleLogger:[NSNumber numberWithBool:YES],@"easeSandBox":[NSNumber numberWithBool:[self isSpecifyServer]]}];
    
    [ChatUIHelper shareHelper];
    
    BOOL isAutoLogin = [EMClient sharedClient].isAutoLogin;
    if (isAutoLogin){
        [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@YES];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@NO];
    }
}

- (void)easemobApplication:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[EaseSDKHelper shareHelper] hyphenateApplication:application didReceiveRemoteNotification:userInfo];
}

#pragma mark - App Delegate

// 将得到的deviceToken传给SDK
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[EMClient sharedClient] bindDeviceToken:deviceToken];
    });
}

// 注册deviceToken失败，此处失败，与环信SDK无关，一般是您的环境配置或者证书配置有误
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"apns.failToRegisterApns", Fail to register apns)
                                                    message:error.description
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - login changed

- (void)loginStateChange:(NSNotification *)notification
{
    //账号信息变化是清空数据
    [[JDRedPacketsSDK sharedInstance] closeJDRPService];

    BOOL loginSuccess = [notification.object boolValue];
    EMNavigationController *navigationController = nil;
    if (loginSuccess) {//登陆成功加载主窗口控制器
        //加载申请通知的数据
        [[UserProfileManager sharedInstance] loadUserProfileInBackground:@[[EMClient sharedClient].currentUsername] saveToLoacal:YES completion:^(BOOL success, NSError *error) {
        }];

        [[ApplyViewController shareController] loadDataSourceFromLocalDB];
        if (self.mainController == nil) {
            self.mainController = [[MainViewController alloc] init];
            navigationController = [[EMNavigationController alloc] initWithRootViewController:self.mainController];
        }else{
            navigationController  = (EMNavigationController *)self.mainController.navigationController;
        }
        // 环信UIdemo中有用到Parse，您的项目中不需要添加，可忽略此处
        [self initParse];

        [ChatUIHelper shareHelper].mainVC = self.mainController;
        
        [[ChatUIHelper shareHelper] asyncGroupFromServer];
        [[ChatUIHelper shareHelper] asyncConversationFromDB];
        [[ChatUIHelper shareHelper] asyncPushOptions];
        
        [self startJDRPService];
    }
    else{//登陆失败加载登陆页面控制器
        if (self.mainController) {
            [self.mainController.navigationController popToRootViewControllerAnimated:NO];
        }
        self.mainController = nil;
        [ChatUIHelper shareHelper].mainVC = nil;
        
        LoginViewController *loginController = [[LoginViewController alloc] init];
        navigationController = [[EMNavigationController alloc] initWithRootViewController:loginController];
        
        [self clearParse];
    }
    
    //设置7.0以下的导航栏
    if ([UIDevice currentDevice].systemVersion.floatValue < 7.0){
        navigationController.navigationBar.barStyle = UIBarStyleDefault;
        [navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"titleBar"]
                                                 forBarMetrics:UIBarMetricsDefault];
        [navigationController.navigationBar.layer setMasksToBounds:YES];
    }
    
    navigationController.navigationBar.accessibilityIdentifier = @"navigationbar";
    self.window.rootViewController = navigationController;
}

#pragma mark - EMPushManagerDelegateDevice

// 打印收到的apns信息
-(void)didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSError *parseError = nil;
    NSData  *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo
                                                        options:NSJSONWritingPrettyPrinted error:&parseError];
    NSString *str =  [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"apns.content", @"Apns content")
                                                    message:str
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                          otherButtonTitles:nil];
    [alert show];
    
}

#pragma mark
#pragma mark - 初始化红包信息
- (void)startJDRPService
{
    [[UserProfileManager sharedInstance] loadUserProfileInBackground:@[[EMClient sharedClient].currentUsername]
                                                        saveToLoacal:YES
                                                          completion:nil];

    [JDRPNetworkTask startNetworkTask:@{@"userId":[EMClient sharedClient].currentUsername} callback:^(NSInteger resultCode, NSString *resultMsg, id resultInfo) {
        UserProfileEntity *entity = [[UserProfileManager sharedInstance] getCurUserProfile];
        NSString *nickname = entity.nickname;
        nickname = nickname.length > 0 ? nickname : [EMClient sharedClient].currentUsername;
        
        JDRPBasicParamsInfo *basicInfo = [[JDRPBasicParamsInfo alloc] init];
        basicInfo.platformUserName = nickname;
        basicInfo.platformHeadImg = entity.imageUrl;
        basicInfo.sign = resultInfo;    //注意sign是NSString类型
        NSDictionary *riskInfo = @{@"eid":@"redpkgtest",
                                   @"isCompany":@"1",
                                   @"isErp":@"1",
                                   @"userLevel":@"G"};//风控信息注意更换
        basicInfo.riskInfo = riskInfo;
        [[JDRedPacketsSDK sharedInstance] initSDK:basicInfo
                                      expiryBlock:^(BOOL result, JDRPFetchBlock fetchBlock) {
            //token失效后重新获取签名数据
            if (!result) {
                [JDRPNetworkTask startNetworkTask:@{@"userId":[EMClient sharedClient].currentUsername} callback:^(NSInteger resultCode, NSString *resultMsg, id resultInfo) {
                    if (fetchBlock) {
                        fetchBlock(resultInfo);
                    }
                }];
            }
        }];
    }];
}

@end
