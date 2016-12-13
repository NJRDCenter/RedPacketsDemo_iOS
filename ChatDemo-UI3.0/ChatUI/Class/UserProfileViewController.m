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

#import "UserProfileViewController.h"

#import "ChatViewController.h"
#import "UIImageView+HeadImage.h"
#import <JDRedPacketsSDK/JDRedPacketsSDK.h>
#import <JDRedPacketsSDK/JDRPApiObject.h>
#import "JDRPOpenConst.h"
#import "JDRPFormatUtil.h"

@interface UserProfileViewController ()

@property (strong, nonatomic) UIImageView *headImageView;
@property (strong, nonatomic) UILabel *usernameLabel;

@end

@implementation UserProfileViewController

- (instancetype)initWithUsername:(NSString *)username
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _username = username;
    }
    return self;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"title.profile", @"Profile");
    
    self.view.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0];
    
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.allowsSelection = NO;
    self.tableView.tableFooterView = [self configFooterView];
    [self setupBarButtonItem];
    [self loadUserProfile];
}

- (UIView *)configFooterView
{
    CGRect mainBounds = [UIScreen mainScreen].bounds;
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, mainBounds.size.width, 100)];
    UIButton *rewardBtn = [[UIButton alloc] initWithFrame:CGRectMake(mainBounds.size.width/2.0-50, 0, 100, 100)];
    rewardBtn.layer.cornerRadius = 50.0f;
    [rewardBtn setBackgroundColor:[UIColor orangeColor]];
    [rewardBtn setTitle:@"赏" forState:UIControlStateNormal];
    rewardBtn.titleLabel.font = [UIFont boldSystemFontOfSize:30.0];
    [rewardBtn addTarget:self action:@selector(sendRewardRedPacket) forControlEvents:UIControlEventTouchUpInside];
    [footerView addSubview:rewardBtn];
    return footerView;
}

- (void)sendRewardRedPacket
{
    UserProfileEntity *entity = [[UserProfileManager sharedInstance] getUserProfileByUsername:_username];
    NSString *nickname = entity.nickname;
    nickname = nickname.length > 0 ? nickname : _username;
    
    JDRPSendRedPacketsEntity *rewardModel = [[JDRPSendRedPacketsEntity alloc] init];
    rewardModel.rewardUserId = _username;
    rewardModel.rewardUserName = nickname;
    rewardModel.rewardAvatar = entity.imageUrl;

    [[JDRedPacketsSDK sharedInstance] sendRedPackets:JDRPRedpacketTypeReward redpkgEntity:rewardModel completionBlock:^(NSDictionary *resultDic) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showHint:@"打赏成功！"];
        });
        NSString *messageStr = [NSString stringWithFormat:@"[%@]%@", @"环信红包", resultDic[@"content"]];
        EMMessage *message = [EaseSDKHelper sendTextMessage:messageStr
                                                         to:self->_username
                                                messageType:EMChatTypeChat
                                                 messageExt:[JDRPFormatUtil changeSendInfoToMessage:resultDic]];

        [[EMClient sharedClient].chatManager sendMessage:message progress:nil completion:NULL];
    }];
}

- (UIImageView*)headImageView
{
    if (!_headImageView) {
        _headImageView = [[UIImageView alloc] init];
        _headImageView.frame = CGRectMake(20, 10, 60, 60);
        _headImageView.contentMode = UIViewContentModeScaleToFill;
    }
    [_headImageView imageWithUsername:_username placeholderImage:nil];
    return _headImageView;
}

- (UILabel*)usernameLabel
{
    if (!_usernameLabel) {
        _usernameLabel = [[UILabel alloc] init];
        _usernameLabel.frame = CGRectMake(CGRectGetMaxX(_headImageView.frame) + 10.f, 10, 200, 20);
        _usernameLabel.text = _username;
        _usernameLabel.textColor = [UIColor lightGrayColor];
    }
    return _usernameLabel;
}

#pragma mark - Table view datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
    }
    if (indexPath.row == 0) {
        cell.detailTextLabel.text = NSLocalizedString(@"setting.personalInfoUpload", @"Upload HeadImage");
        [cell.contentView addSubview:self.headImageView];
    } else if (indexPath.row == 1) {
        cell.textLabel.text = NSLocalizedString(@"username", @"username");
        cell.detailTextLabel.text = self.usernameLabel.text;
    } else if (indexPath.row == 2) {
        cell.textLabel.text = NSLocalizedString(@"setting.profileNickname", @"Nickname");
        UserProfileEntity *entity = [[UserProfileManager sharedInstance] getUserProfileByUsername:_username];
        if (entity && entity.nickname.length>0) {
            cell.detailTextLabel.text = entity.nickname;
        } else {
            cell.detailTextLabel.text = _username;
        }
        //        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 80;
    }
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)setupBarButtonItem
{
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    backButton.accessibilityIdentifier = @"back";
    [backButton setImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    [self.navigationItem setLeftBarButtonItem:backItem];
}

- (void)loadUserProfile
{
    [self hideHud];
    [self showHudInView:self.view hint:NSLocalizedString(@"loadData", @"Load data...")];
    __weak typeof(self) weakself = self;
    [[UserProfileManager sharedInstance] loadUserProfileInBackground:@[_username] saveToLoacal:YES completion:^(BOOL success, NSError *error) {
        [weakself hideHud];
        if (success) {
            [weakself.tableView reloadData];
        }
    }];
}

- (void)back
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
