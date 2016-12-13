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

#import <UIKit/UIKit.h>

@protocol JDRPGroupListSelectedDelegate <NSObject>

- (void)groupListViewControllerDidSelected:(EMGroup *)group;

@end

@interface JDRPGroupListViewController : UITableViewController

@property (nonatomic, weak) id<JDRPGroupListSelectedDelegate> delegate;

- (void)reloadDataSource;

@end
