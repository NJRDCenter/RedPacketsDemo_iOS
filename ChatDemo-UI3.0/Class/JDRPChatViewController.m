//
//  JDRPChatViewController.m
//  ChatDemo-UI3.0
//
//  Created by xwxing on 2016/11/17.
//  Copyright © 2016年 xwxing. All rights reserved.
//

#import "JDRPChatViewController.h"

#import "EaseRedBagCell.h"
#import "RedpacketMessageCell.h"
#import "ChatUIHelper.h"
#import "TransferCell.h"
#import <JDRedPacketsSDK/JDRedPacketsSDK.h>
#import <JDRedPacketsSDK/JDRPApiObject.h>
#import "ContactSelectionViewController.h"
#import "JDRPFormatUtil.h"
#import "JDRPOpenConst.h"
#import "JDRPNetworkTask.h"

/**
 *  红包聊天窗口
 */
@interface JDRPChatViewController () < EaseMessageCellDelegate,
EaseMessageViewControllerDataSource, JDRedPacketsDelegate,EMChooseViewDelegate>

@property (nonatomic, copy) JDRPMemberBlock         memberBlock;

@end

@implementation JDRPChatViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //  设置用户头像
    [[EaseRedBagCell appearance] setAvatarSize:40.f];
    //  设置头像圆角
    [[EaseRedBagCell appearance] setAvatarCornerRadius:20.f];
    
    [[TransferCell appearance] setAvatarSize:40.0f];
    [[TransferCell appearance] setAvatarCornerRadius:20.0f];
    
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor],NSFontAttributeName : [UIFont systemFontOfSize:18]};
    
    if ([self.chatToolbar isKindOfClass:[EaseChatToolbar class]]) {
        //  MARK: __redbag  红包
        [self.chatBarMoreView insertItemWithImage:[UIImage imageNamed:@"RedpacketCellResource.bundle/redpacket_redpacket"] highlightedImage:[UIImage imageNamed:@"RedpacketCellResource.bundle/redpacket_redpacket_high"] title:@"红包"];
        
        //  MARK: __redbag 转账
        [self.chatBarMoreView insertItemWithImage:[UIImage imageNamed:@"RedPacketResource.bundle/redpacket_transfer_high"] highlightedImage:[UIImage imageNamed:@"RedPacketResource.bundle/redpacket_transfer_high"] title:@"转账"];
    }
    
    //  显示红包的Cell视图
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([RedpacketMessageCell class]) bundle:nil]forCellReuseIdentifier:NSStringFromClass([RedpacketMessageCell class])];
}

- (BOOL)isRedpacketTakenMessage:(NSDictionary *)dic
{
    if (dic[@"hasGrab"] && [dic[@"revAmount"] integerValue] != 0) {
        return YES;
    }
    return NO;
}

#pragma mark - 获取通讯录列表（专属红包）
- (void)getMemberAvatarsWithCurrentVC:(id)currentVC andLimitMembers:(NSInteger)limitCount completionBlock:(JDRPMemberBlock)block
{
    //to be done
    _memberBlock = [block copy];
//    userId:专属用户ID,userName：专属用户昵称,avatar：专属用户头像
    EMGroup *chatGroup = [[[EMClient sharedClient] groupManager] fetchGroupInfo:self.conversation.conversationId includeMembersList:YES error:nil];
    
    if (chatGroup) {
        if (!chatGroup.occupants) {
            __weak JDRPChatViewController* weakSelf = self;
            [self showHudInView:self.view hint:@"Fetching group members..."];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                EMError *error = nil;
                EMGroup *group = [[EMClient sharedClient].groupManager fetchGroupInfo:chatGroup.groupId includeMembersList:YES error:&error];
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong JDRPChatViewController *strongSelf = weakSelf;
                    if (strongSelf) {
                        [strongSelf hideHud];
                        if (error) {
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Fetching group members failed [%@]", error.errorDescription] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                            [alertView show];
                        }
                        else {
                            if (![group.occupants count]) {
                                if (block) {
                                    block(nil);
                                }
                                return;
                            }
                            ContactSelectionViewController *selectController = [[ContactSelectionViewController alloc] initWithContacts:group.occupants];
                            selectController.delegate = self;
                            selectController.maxNumber = limitCount;
                            UIViewController *vc = (UIViewController *)currentVC;
                            [vc.navigationController pushViewController:selectController animated:YES];
                        }
                    }
                });
            });
        }
        else {
            if (![chatGroup.occupants count]) {
                if (block) {
                    block(nil);
                }
                return;
            }
            ContactSelectionViewController *selectController = [[ContactSelectionViewController alloc] initWithContacts:chatGroup.occupants];
            selectController.delegate = self;
            selectController.maxNumber = limitCount;
            UIViewController *vc = (UIViewController *)currentVC;
            [vc.navigationController pushViewController:selectController animated:YES];
        }
    }
}

// 要在此处根据userID获得用户昵称,和头像地址
//- (RedpacketUserInfo *)profileEntityWith:(NSString *)userId
//{
//    RedpacketUserInfo *userInfo = [RedpacketUserInfo new];
//    
//    UserCacheInfo *user = [UserCacheManager getById:userId];
//    userInfo.userNickname = user.NickName;
//    userInfo.userAvatar = user.NickName;
//    userInfo.userId = userId;
//    return userInfo;
//}

//  长时间按在某条Cell上的动作
- (BOOL)messageViewController:(EaseMessageViewController *)viewController canLongPressRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = [self.dataArray objectAtIndex:indexPath.row];
    
    if ([object conformsToProtocol:NSProtocolFromString(@"IMessageModel")]) {
        id <IMessageModel> messageModel = object;
        NSDictionary *ext = messageModel.message.ext;
        
        //  如果是红包，则只显示删除按钮
        if ([ext[MESSAGE_ATTR_IS_RED_PACKET_MESSAGE] boolValue]) {
            EaseMessageCell *cell = (EaseMessageCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell becomeFirstResponder];
            self.menuIndexPath = indexPath;
            [self showMenuViewController:cell.bubbleView andIndexPath:indexPath messageType:EMMessageBodyTypeCmd];
            
            return NO;
        }else if ([ext[MESSAGE_ATTR_REV_IS_RED_PACKET_MESSAGE] boolValue]) {
            
            return NO;
        }
    }
    
    return [super messageViewController:viewController canLongPressRowAtIndexPath:indexPath];
}


#pragma mrak - 自定义红包的Cell

- (UITableViewCell *)messageViewController:(UITableView *)tableView
                       cellForMessageModel:(id<IMessageModel>)messageModel
{
    NSDictionary *ext = messageModel.message.ext;
    
    /**
     *  红包相关的展示
     */
    if ([ext[MESSAGE_ATTR_IS_RED_PACKET_MESSAGE] boolValue]) {
        EaseRedBagCell *cell = [tableView dequeueReusableCellWithIdentifier:[EaseRedBagCell cellIdentifierWithModel:messageModel]];
        
        if (!cell) {
            cell = [[EaseRedBagCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[EaseRedBagCell cellIdentifierWithModel:messageModel] model:messageModel];
            cell.delegate = self;
        }
        
        cell.model = messageModel;
        
        return cell;
        
    }else if ([ext[MESSAGE_ATTR_REV_IS_RED_PACKET_MESSAGE] boolValue]){
        RedpacketMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([RedpacketMessageCell class])];
        cell.model = messageModel;
        
        return cell;
    }
    return nil;
}

- (CGFloat)messageViewController:(EaseMessageViewController *)viewController
           heightForMessageModel:(id<IMessageModel>)messageModel
                   withCellWidth:(CGFloat)cellWidth
{
    NSDictionary *ext = messageModel.message.ext;
    
    if ([ext[MESSAGE_ATTR_IS_RED_PACKET_MESSAGE] boolValue])    {
        return [EaseRedBagCell cellHeightWithModel:messageModel];
    }else if ([ext[MESSAGE_ATTR_REV_IS_RED_PACKET_MESSAGE] boolValue]) {
        return 36;
    }
    
    return 0.0f;
}

#pragma mark - DataSource
//  未读消息回执
- (BOOL)messageViewController:(EaseMessageViewController *)viewController
shouldSendHasReadAckForMessage:(EMMessage *)message
                         read:(BOOL)read
{
    NSDictionary *ext = message.ext;
    
    if ([ext[MESSAGE_ATTR_IS_RED_PACKET_MESSAGE] boolValue] || [ext[MESSAGE_ATTR_REV_IS_RED_PACKET_MESSAGE] boolValue]) {
        return NO;
    }
    
    return [super shouldSendHasReadAckForMessage:message read:read];
}

#pragma mark - 发送红包消息
- (void)messageViewController:(EaseMessageViewController *)viewController didSelectMoreView:(EaseChatBarMoreView *)moreView AtIndex:(NSInteger)index
{
    moreView.userInteractionEnabled = NO;
    if (self.conversation.type == EMConversationTypeChat) {
        // 点对点红包
        if (index == 5) {
            
#warning XXW发红包入口-单个红包
            JDRPSendRedPacketsEntity *privateModel = [[JDRPSendRedPacketsEntity alloc] init];
            privateModel.targetUserId = self.conversation.conversationId;
            
            [[JDRedPacketsSDK sharedInstance] sendRedPackets:JDRPRedpacketTypeSingle redpkgEntity:privateModel completionBlock:^(NSDictionary *resultDic) {
                [self sendRedPacketMessage:[JDRPFormatUtil changeSendInfoToMessage:resultDic]];
            }];
        }
    }else{
        //群内指向红包
#warning XXW发红包入口-群红包
        NSArray *groupArray = [EMGroup groupWithId:self.conversation.conversationId].occupants;

        JDRPSendRedPacketsEntity *groupModel = [[JDRPSendRedPacketsEntity alloc] init];
        groupModel.groupId = [EMGroup groupWithId:self.conversation.conversationId].groupId;
        groupModel.groupNum = [groupArray count];

        [JDRedPacketsSDK sharedInstance].delegate = self;
        [[JDRedPacketsSDK sharedInstance] sendRedPackets:JDRPRedpacketTypeGroup redpkgEntity:groupModel completionBlock:^(NSDictionary *resultDic) {
            [self sendRedPacketMessage:[JDRPFormatUtil changeSendInfoToMessage:resultDic]];
        }];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        moreView.userInteractionEnabled = YES;
    });
    
}

//  MARK: 发送红包消息
- (void)sendRedPacketMessage:(NSDictionary *)dic
{
    NSString *message = [NSString stringWithFormat:@"[%@]%@", @"环信红包", dic[MESSAGE_ATTR_REDPKG_DESC]];
    
    [self sendTextMessage:message withExt:dic];
}

//  MARK: 发送红包被抢的消息
- (void)sendRedpacketHasBeenTaked:(NSDictionary *)dic senderUserId:(NSString *)senderUserId
{
    NSMutableDictionary *postDic = [NSMutableDictionary dictionaryWithDictionary:dic];

    NSString *currentUser = [EMClient sharedClient].currentUsername;
    NSString *conversationId = self.conversation.conversationId;
    
//    NSMutableDictionary *dic = [messageModel.redpacketMessageModelToDic mutableCopy];
//    //  领取通知消息不推送
//    [dic setValue:@(YES) forKey:@"em_ignore_notification"];

    UserProfileEntity *entity = [[UserProfileManager sharedInstance] getUserProfileByUsername:senderUserId];
    NSString *nickname = entity.nickname;
    nickname = nickname.length > 0 ? nickname : senderUserId;

    NSString *text = [NSString stringWithFormat:@"你领取了%@发的红包", nickname];
    
    if (self.conversation.type == EMConversationTypeChat) {
        [self sendTextMessage:text withExt:postDic];
        
    }else{
        if ([senderUserId isEqualToString:currentUser]) {
            text = @"你领取了自己的红包";
            
        }else {
            /**
             如果不是自己发的红包，则发送抢红包消息给对方
             */
            [[EMClient sharedClient].chatManager sendMessage:[self createCmdMessageWithModel:postDic sendUserId:senderUserId] progress:nil completion:nil];
        }
        
        /*
         NSString *willSendText = [EaseConvertToCommonEmoticonsHelper convertToCommonEmoticons:text];
         */
        EMTextMessageBody *textMessageBody = [[EMTextMessageBody alloc] initWithText:text];
        EMMessage *textMessage = [[EMMessage alloc] initWithConversationID:conversationId from:currentUser to:conversationId body:textMessageBody ext:postDic];
        textMessage.chatType = (EMChatType)self.conversation.type;
        textMessage.isRead = YES;
        
        /**
         *  刷新当前聊天界面
         */
        [self addMessageToDataSource:textMessage progress:nil];
        /**
         *  存入当前会话并存入数据库
         */
        [self.conversation appendMessage:textMessage error:nil];
    }
}

- (EMMessage *)createCmdMessageWithModel:(NSDictionary *)dic sendUserId:(NSString *)senderUserId
{
    NSString *currentUser = [EMClient sharedClient].currentUsername;
    EMCmdMessageBody *cmdChat = [[EMCmdMessageBody alloc] initWithAction:@"JDRPRedPacketKeyCmd"];
    EMMessage *message = [[EMMessage alloc] initWithConversationID:self.conversation.conversationId from:currentUser to:self.conversation.conversationId body:cmdChat ext:dic];
    message.chatType = (EMChatType)self.conversation.type;
    
    return message;
}

#pragma mark -
#pragma mark  红包被抢消息监控
-(void)didReceiveCmdMessages:(NSArray *)aCmdMessages
{
    /**
     *  处理红包被抢的消息
     */
    [self handleCmdMessages:aCmdMessages];
}

/**
 *  群红包，红包被抢的消息
 */
- (void)handleCmdMessages:(NSArray <EMMessage *> *)aCmdMessages
{
    for (EMMessage *message in aCmdMessages) {
        EMCmdMessageBody * body = (EMCmdMessageBody *)message.body;
        if ([body.action isEqualToString:@"JDRPRedPacketKeyCmd"]) {
            NSDictionary *dict = message.ext;
            NSString *senderID = [dict valueForKey:MESSAGE_ATTR_REV_SENDER_USERID];
            NSString *receiverID = [dict valueForKey:MESSAGE_ATTR_REV_RECEIVER_USERID];
            NSString *currentUserID = [EMClient sharedClient].currentUsername;
            
            if ([senderID isEqualToString:currentUserID]){
                /**
                 *  当前用户是红包发送者
                 */
                NSString *receiverName = [[UserProfileManager sharedInstance] getNickNameWithUsername:receiverID];

                if (receiverName.length == 0) {
                    receiverName = receiverID;
                }

                NSString *text = [NSString stringWithFormat:@"%@领取了你的红包",receiverName];
                /*
                 NSString *willSendText = [EaseConvertToCommonEmoticonsHelper convertToCommonEmoticons:text];
                 */
                EMTextMessageBody *body1 = [[EMTextMessageBody alloc] initWithText:text];
                EMMessage *textMessage = [[EMMessage alloc] initWithConversationID:self.conversation.conversationId from:message.from to:self.conversation.conversationId body:body1 ext:message.ext];
                textMessage.chatType = EMChatTypeGroupChat;
                textMessage.isRead = YES;
                
                /**
                 *  刷新当前聊天界面
                 */
                [self addMessageToDataSource:textMessage progress:nil];
                /**
                 *  存入当前会话并存入数据库
                 */
                [self.conversation appendMessage:textMessage error:nil];
            }
        }
    }
}

#pragma mark - EaseMessageCellDelegate 单击了Cell 事件

- (void)messageCellSelected:(id<IMessageModel>)model
{
    NSDictionary *dict = model.message.ext;
    
    if ([dict[MESSAGE_ATTR_IS_RED_PACKET_MESSAGE] boolValue]) {
#warning XXW抢红包入口
        [self.view endEditing:YES];
        UserProfileEntity *userEntity = [[UserProfileManager sharedInstance] getCurUserProfile];
        NSString *nickname = userEntity.nickname;
        nickname = nickname.length > 0 ? nickname : [EMClient sharedClient].currentUsername;
        
        //        [self.viewControl redpacketCellTouchedWithMessageModel:[self toRedpacketMessageModel:model]];
        JDRPGrabRedPacketEntity *entity = [[JDRPGrabRedPacketEntity alloc] init];
        entity.redpkgId = dict[MESSAGE_ATTR_REDPKG_ID];
        entity.senderUserId = dict[MESSAGE_ATTR_SENDER_USERID];
        entity.redpkgExtType = dict[MESSAGE_ATTR_REDPKG_TYPE];
        entity.platformUserName = nickname;
        entity.platformHeadImg = userEntity.imageUrl;
        [[JDRedPacketsSDK sharedInstance] grabRedPacket:entity completionBlock:^(NSDictionary *resultDic) {
            [self sendRedpacketHasBeenTaked:[JDRPFormatUtil changeGrabInfoToMessage:resultDic] senderUserId:entity.senderUserId];
        }];
    }
    else {
        [super messageCellSelected:model];
    }
}

//- (RedpacketMessageModel *)toRedpacketMessageModel:(id <IMessageModel>)model
//{
//    RedpacketMessageModel *messageModel = [RedpacketMessageModel redpacketMessageModelWithDic:model.message.ext];
//    BOOL isGroup = self.conversation.type == EMConversationTypeGroupChat;
//    if (isGroup) {
//        messageModel.redpacketSender = [self profileEntityWith:model.message.from];
//        messageModel.toRedpacketReceiver = [self profileEntityWith:messageModel.toRedpacketReceiver.userId];
//    }else
//    {
//        messageModel.redpacketSender = [self profileEntityWith:model.message.from];
//    }
//    return messageModel;
//}

#pragma mark - EMChooseViewDelegate

- (BOOL)viewController:(EMChooseViewController *)viewController didFinishSelectedSources:(NSArray *)selectedSources
{
    if ([selectedSources count]) {
        
        NSMutableArray *mArray = [[NSMutableArray alloc]init];
        
        for (NSString *userId in selectedSources) {
            UserProfileEntity *userEntity = [[UserProfileManager sharedInstance] getUserProfileByUsername:userId];
            NSString *nickname = userEntity.nickname;
            nickname = nickname.length > 0 ? nickname : userId;

            NSString *name = @"";
            NSString *avatar = @"";

            if (nickname) {
                name = nickname;
            }
            if (userEntity.imageUrl) {
                avatar = userEntity.imageUrl;
            }
            //创建一个用户模型 并赋值
            NSMutableDictionary *dic = @{}.mutableCopy;
            [dic setObject:userId forKey:@"userId"];
            [dic setObject:name forKey:@"userName"];
            [dic setObject:avatar forKey:@"avatar"];
            [mArray addObject:dic];
        }
        
        if (self.memberBlock) {
            self.memberBlock(mArray);
        }
    }
    else {
        if (self.memberBlock) {
            self.memberBlock(nil);
        }
    }
    return YES;
}

- (void)viewControllerDidSelectBack:(EMChooseViewController *)viewController
{
    if (self.memberBlock) {
        self.memberBlock(nil);
    }
}

@end
