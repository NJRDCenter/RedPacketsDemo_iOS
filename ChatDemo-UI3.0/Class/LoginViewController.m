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

#import "LoginViewController.h"
#import "EMError.h"
#import "ChatUIHelper.h"
#import "MBProgressHUD.h"
#import "RCAnimatedImagesView.h"

@interface LoginViewController ()<UITextFieldDelegate,RCAnimatedImagesViewDelegate>

@property (weak, nonatomic) IBOutlet RCAnimatedImagesView *animatedImagesView;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UISwitch *useIpSwitch;
@property (weak, nonatomic) IBOutlet UILabel *noteLbl;
@property (weak, nonatomic) IBOutlet UIButton *exchangeBtn;

- (IBAction)doRegister:(id)sender;
- (IBAction)doLogin:(id)sender;
- (IBAction)useIpAction:(id)sender;

@property (nonatomic, assign)   BOOL        isLoginView;

@end

@implementation LoginViewController

@synthesize usernameTextField = _usernameTextField;
@synthesize passwordTextField = _passwordTextField;
@synthesize registerButton = _registerButton;
@synthesize loginButton = _loginButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        //添加动态图
//        self.animatedImagesView = [[RCAnimatedImagesView alloc]
//                                   initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width,
//                                                            self.view.bounds.size.height)];
        _isLoginView = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];

    self.animatedImagesView.delegate = self;

    self.noteLbl.font = [UIFont fontWithName:@"Zapfino" size:18.0f];
    
    [self setupForDismissKeyboard];
    
    _usernameTextField.delegate = self;
    _passwordTextField.delegate = self;
    
    NSString *username = [self lastLoginUsername];
    if (username && username.length > 0) {
        _usernameTextField.text = username;
    }
    
//    [_useIpSwitch setOn:[[EMClient sharedClient].options enableDnsConfig] animated:YES];
    
    self.title = NSLocalizedString(@"AppName", @"EaseMobDemo");
    
    [self addSnowLayer];
}

- (void)addSnowLayer
{
    // =================== 樱花飘落 ====================
    CAEmitterLayer * snowEmitterLayer = [CAEmitterLayer layer];
    snowEmitterLayer.emitterPosition = CGPointMake(100, -30);
    snowEmitterLayer.emitterSize = CGSizeMake(self.view.bounds.size.width * 2, 0);
    snowEmitterLayer.emitterMode = kCAEmitterLayerOutline;
    snowEmitterLayer.emitterShape = kCAEmitterLayerLine;
    //    snowEmitterLayer.renderMode = kCAEmitterLayerAdditive;
    
    CAEmitterCell * snowCell = [CAEmitterCell emitterCell];
    snowCell.contents = (__bridge id)[UIImage imageNamed:@"snow"].CGImage;
    
    // 花瓣缩放比例
    snowCell.scale = 0.02;
    snowCell.scaleRange = 0.5;
    
    // 每秒产生的花瓣数量
    snowCell.birthRate = 0.8;
    snowCell.lifetime = 80;
    
    // 每秒花瓣变透明的速度
    snowCell.alphaSpeed = -0.01;
    
    // 秒速“五”厘米～～
    snowCell.velocity = 40;
    snowCell.velocityRange = 60;
    
    // 花瓣掉落的角度范围
    snowCell.emissionRange = M_PI;
    
    // 花瓣旋转的速度
    snowCell.spin = M_PI_4;
    
    // 每个cell的颜色
    //    snowCell.color = [[UIColor redColor] CGColor];
    
    // 阴影的 不透明 度
    snowEmitterLayer.shadowOpacity = 1;
    // 阴影化开的程度（就像墨水滴在宣纸上化开那样）
    snowEmitterLayer.shadowRadius = 8;
    // 阴影的偏移量
    snowEmitterLayer.shadowOffset = CGSizeMake(3, 3);
    // 阴影的颜色
    snowEmitterLayer.shadowColor = [[UIColor whiteColor] CGColor];
    
    
    snowEmitterLayer.emitterCells = [NSArray arrayWithObject:snowCell];
    [self.view.layer addSublayer:snowEmitterLayer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString *username = [self lastLoginUsername];
    if (username && username.length > 0) {
        self.usernameTextField.text = username;
    }
    self.loginButton.hidden = NO;
    self.registerButton.hidden = YES;
    [self.exchangeBtn setTitle:@"新用户注册⇨" forState:UIControlStateNormal];

    [self.animatedImagesView startAnimating];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.animatedImagesView stopAnimating];
}

- (void)viewDidUnload {
    [self setAnimatedImagesView:nil];
    
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)doSwitchView:(id)sender {
    
    [UIView animateWithDuration:0.3 animations:^{
        self.usernameTextField.alpha = 0;
        self.passwordTextField.alpha = 0;
        self.loginButton.alpha = 0;
        self.registerButton.alpha = 0;
        self.exchangeBtn.alpha = 0;
    } completion:^(BOOL finished) {
        if (self.isLoginView) {
            self.usernameTextField.text = @"";
            self.passwordTextField.text = @"";
            self.loginButton.hidden = YES;
            self.registerButton.hidden = NO;
            [self.exchangeBtn setTitle:@"⇦返回登录" forState:UIControlStateNormal];
        }else
        {
            NSString *username = [self lastLoginUsername];
            if (username && username.length > 0) {
                self.usernameTextField.text = username;
            }
            self.passwordTextField.text = @"";
            self.loginButton.hidden = NO;
            self.registerButton.hidden = YES;
            [self.exchangeBtn setTitle:@"新用户注册⇨" forState:UIControlStateNormal];
        }
        
        self.isLoginView = !self.isLoginView;

        [UIView animateWithDuration:0.3 animations:^{
            self.usernameTextField.alpha = 1;
            self.passwordTextField.alpha = 1;
            self.loginButton.alpha = 1;
            self.registerButton.alpha = 1;
            self.exchangeBtn.alpha = 1;
        } completion:nil];
    }];
}

//注册账号
//Registered account
- (IBAction)doRegister:(id)sender {
    if (![self isEmpty]) {
        //隐藏键盘
        [self.view endEditing:YES];
        //判断是否是中文，但不支持中英文混编
        if ([self.usernameTextField.text isChinese]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"login.nameNotSupportZh", @"Name does not support Chinese")
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                  otherButtonTitles:nil];
            
            [alert show];
            
            return;
        }
        [self showHudInView:self.view hint:NSLocalizedString(@"register.ongoing", @"Is to register...")];
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            EMError *error = [[EMClient sharedClient] registerWithUsername:weakself.usernameTextField.text password:weakself.passwordTextField.text];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself hideHud];
                if (!error) {
                    [self loginWithUsername:weakself.usernameTextField.text password:weakself.passwordTextField.text];

//                    TTAlertNoTitle(NSLocalizedString(@"register.success", @"Registered successfully, please log in"));
                }else{
                    switch (error.code) {
                        case EMErrorServerNotReachable:
                            TTAlertNoTitle(NSLocalizedString(@"error.connectServerFail", @"Connect to the server failed!"));
                            break;
                        case EMErrorUserAlreadyExist:
                            TTAlertNoTitle(NSLocalizedString(@"register.repeat", @"You registered user already exists!"));
                            break;
                        case EMErrorNetworkUnavailable:
                            TTAlertNoTitle(NSLocalizedString(@"error.connectNetworkFail", @"No network connection!"));
                            break;
                        case EMErrorServerTimeout:
                            TTAlertNoTitle(NSLocalizedString(@"error.connectServerTimeout", @"Connect to the server timed out!"));
                            break;
                        case EMErrorServerServingForbidden:
                            TTAlertNoTitle(NSLocalizedString(@"servingIsBanned", @"Serving is banned"));
                            break;
                        default:
                            TTAlertNoTitle(NSLocalizedString(@"register.fail", @"Registration failed"));
                            break;
                    }
                }
            });
        });
    }
}

//点击登陆后的操作
- (void)loginWithUsername:(NSString *)username password:(NSString *)password
{
    [self showHudInView:self.view hint:NSLocalizedString(@"login.ongoing", @"Is Login...")];
    //异步登陆账号
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = [[EMClient sharedClient] loginWithUsername:username password:password];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself hideHud];
            if (!error) {                
                //设置是否自动登录
                [[EMClient sharedClient].options setIsAutoLogin:YES];
                
                [[UserProfileManager sharedInstance] loadUserProfileInBackground:@[username] saveToLoacal:YES completion:^(BOOL success, NSError *error) {
                    [weakself hideHud];
                    UserProfileEntity *entity = [UserProfileManager sharedInstance].getCurUserProfile;
                    if (!entity.imageUrl) {
                        UIImage *placeholderImage = [UIImage imageNamed:@"chatListCellHead"];
                        [[UserProfileManager sharedInstance] uploadUserHeadImageProfileInBackground:placeholderImage completion:^(BOOL success, NSError *error) {
                            [weakself hideHud];
                        }];
                    }
                }];
                
                //获取数据库中数据
                [MBProgressHUD showHUDAddedTo:weakself.view animated:YES];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[EMClient sharedClient] migrateDatabaseToLatestSDK];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[ChatUIHelper shareHelper] asyncGroupFromServer];
                        [[ChatUIHelper shareHelper] asyncConversationFromDB];
                        [[ChatUIHelper shareHelper] asyncPushOptions];
                        [MBProgressHUD hideAllHUDsForView:weakself.view animated:YES];
                        //发送自动登陆状态通知
                        [[NSNotificationCenter defaultCenter] postNotificationName:KNOTIFICATION_LOGINCHANGE object:@([[EMClient sharedClient] isLoggedIn])];
                        
                        //保存最近一次登录用户名
                        [weakself saveLastLoginUsername];
                    });
                });
            } else {
                switch (error.code)
                {
//                    case EMErrorNotFound:
//                        TTAlertNoTitle(error.errorDescription);
//                        break;
                    case EMErrorNetworkUnavailable:
                        TTAlertNoTitle(NSLocalizedString(@"error.connectNetworkFail", @"No network connection!"));
                        break;
                    case EMErrorServerNotReachable:
                        TTAlertNoTitle(NSLocalizedString(@"error.connectServerFail", @"Connect to the server failed!"));
                        break;
                    case EMErrorUserAuthenticationFailed:
                        TTAlertNoTitle(error.errorDescription);
                        break;
                    case EMErrorServerTimeout:
                        TTAlertNoTitle(NSLocalizedString(@"error.connectServerTimeout", @"Connect to the server timed out!"));
                        break;
                    case EMErrorServerServingForbidden:
                        TTAlertNoTitle(NSLocalizedString(@"servingIsBanned", @"Serving is banned"));
                        break;
                    default:
                        TTAlertNoTitle(NSLocalizedString(@"login.fail", @"Login failure"));
                        break;
                }
            }
        });
    });
}

//弹出提示的代理方法
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if ([alertView cancelButtonIndex] != buttonIndex) {
        //获取文本输入框
        UITextField *nameTextField = [alertView textFieldAtIndex:0];
        if(nameTextField.text.length > 0)
        {
            //设置推送设置
            [[EMClient sharedClient] setApnsNickname:nameTextField.text];
        }
    }
    //登陆
    [self loginWithUsername:_usernameTextField.text password:_passwordTextField.text];
}

//登陆账号
- (IBAction)doLogin:(id)sender {
    if (![self isEmpty]) {
        [self.view endEditing:YES];
        //支持是否为中文
        if ([self.usernameTextField.text isChinese]) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"login.nameNotSupportZh", @"Name does not support Chinese")
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                  otherButtonTitles:nil];
            
            [alert show];
            
            return;
        }
        /*
#if !TARGET_IPHONE_SIMULATOR
        //弹出提示
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"login.inputApnsNickname", @"Please enter nickname for apns") delegate:self cancelButtonTitle:NSLocalizedString(@"cancel", @"Cancel") otherButtonTitles:NSLocalizedString(@"ok", @"OK"), nil];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        UITextField *nameTextField = [alert textFieldAtIndex:0];
        nameTextField.text = self.usernameTextField.text;
        [alert show];
#elif TARGET_IPHONE_SIMULATOR
        [self loginWithUsername:_usernameTextField.text password:_passwordTextField.text];
#endif
         */
        [self loginWithUsername:_usernameTextField.text password:_passwordTextField.text];
    }
}

//是否使用ip
- (IBAction)useIpAction:(id)sender
{
//    UISwitch *ipSwitch = (UISwitch *)sender;
//    [[EMClient sharedClient].options setEnableDnsConfig:ipSwitch.isOn];
}

//判断账号和密码是否为空
- (BOOL)isEmpty{
    BOOL ret = NO;
    NSString *username = _usernameTextField.text;
    NSString *password = _passwordTextField.text;
    if (username.length == 0 || password.length == 0) {
        ret = YES;
        [EMAlertView showAlertWithTitle:NSLocalizedString(@"prompt", @"Prompt")
                                message:NSLocalizedString(@"login.inputNameAndPswd", @"Please enter username and password")
                        completionBlock:nil
                      cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                      otherButtonTitles:nil];
    }
    
    return ret;
}


#pragma  mark - TextFieldDelegate
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if (textField == _usernameTextField) {
        _passwordTextField.text = @"";
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == _usernameTextField) {
        [_usernameTextField resignFirstResponder];
        [_passwordTextField becomeFirstResponder];
    } else if (textField == _passwordTextField) {
        [_passwordTextField resignFirstResponder];
        [self doLogin:nil];
    }
    return YES;
}

#pragma  mark - private
- (void)saveLastLoginUsername
{
    NSString *username = [[EMClient sharedClient] currentUsername];
    if (username && username.length > 0) {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:username forKey:[NSString stringWithFormat:@"em_lastLogin_username"]];
        [ud synchronize];
    }
}

- (NSString*)lastLoginUsername
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *username = [ud objectForKey:[NSString stringWithFormat:@"em_lastLogin_username"]];
    if (username && username.length > 0) {
        return username;
    }
    return nil;
}

#pragma RCAnimatedImagesViewDelegate
- (NSUInteger)animatedImagesNumberOfImages:
(RCAnimatedImagesView *)animatedImagesView {
    return 2;
}

- (UIImage *)animatedImagesView:(RCAnimatedImagesView *)animatedImagesView
                   imageAtIndex:(NSUInteger)index {
    return [UIImage imageNamed:@"login_background.jpg"];
}


@end
