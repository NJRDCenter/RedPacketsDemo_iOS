//
//  JDRPContactViewController.h
//  ChatDemo-UI3.0
//
//  Created by yao on 2016/11/21.
//  Copyright © 2016年 yao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JDRPGroupListViewController.h"

typedef NS_ENUM(NSInteger,SelectedType)
{
    SelectedTypeUser = 0,       //!<个人
    SelectedTypeGroup           //!<群组
};

typedef void(^userHasSelectedBlock)(id something, SelectedType type);

@interface JDRPContactViewController : EaseUsersListViewController

@property (copy, nonatomic) userHasSelectedBlock selectedBlock;

@end
