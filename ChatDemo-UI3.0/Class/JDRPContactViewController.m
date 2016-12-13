//
//  JDRPContactViewController.m
//  ChatDemo-UI3.0
//
//  Created by yao on 2016/11/21.
//  Copyright © 2016年 yao. All rights reserved.
//

#import "JDRPContactViewController.h"
#import "EMSearchBar.h"
#import "EMSearchDisplayController.h"
#import "RealtimeSearchUtil.h"
#import "JDRPChatViewController.h"

//@implementation NSString (search)
//
////根据用户昵称进行搜索
//- (NSString*)showName
//{
//    return [UserCacheManager getNickById:self];
//}
//
//@end

@interface JDRPContactViewController ()<UISearchBarDelegate, UISearchDisplayDelegate, UIAlertViewDelegate, JDRPGroupListSelectedDelegate>
@property (strong, nonatomic) EaseUserModel *selectedUser;
@property (strong, nonatomic) EMGroup *selectedGroup;
@property (strong, nonatomic) NSMutableArray *sectionTitles;
@property (strong, nonatomic) NSMutableArray *contactsSource;
@property (strong, nonatomic) EMSearchBar *searchBar;
@property (strong, nonatomic) EMSearchDisplayController *searchController;

@end

@implementation JDRPContactViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.showRefreshHeader = YES;
    
    _contactsSource = [NSMutableArray array];
    _sectionTitles = [NSMutableArray array];
    
    [self searchController];
    self.searchBar.frame = CGRectMake(0, 0, self.view.frame.size.width, 44);
    [self.view addSubview:self.searchBar];
    
    self.tableView.frame = CGRectMake(0, self.searchBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.searchBar.frame.size.height);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}



#pragma mark - getter
- (UISearchBar *)searchBar
{
    if (_searchBar == nil) {
        _searchBar = [[EMSearchBar alloc] init];
        _searchBar.delegate = self;
        _searchBar.placeholder = NSLocalizedString(@"search", @"Search");
        _searchBar.backgroundColor = [UIColor colorWithRed:0.747 green:0.756 blue:0.751 alpha:1.000];
    }
    return _searchBar;
}

- (EMSearchDisplayController *)searchController
{
    if (_searchController == nil) {
        _searchController = [[EMSearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
        _searchController.delegate = self;
        _searchController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        __weak JDRPContactViewController *weakSelf = self;
        [_searchController setCellForRowAtIndexPathCompletion:^UITableViewCell *(UITableView *tableView, NSIndexPath *indexPath) {
            static NSString *CellIdentifier = @"ContactListCell";
            BaseTableViewCell *cell = (BaseTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                cell = [[BaseTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            }
            
            NSString *buddy = [weakSelf.searchController.resultsSource objectAtIndex:indexPath.row];
            cell.imageView.image = [UIImage imageNamed:@"chatListCellHead.png"];
            cell.textLabel.text = buddy;
            cell.username = buddy;
            return cell;
        }];
        
        [_searchController setHeightForRowAtIndexPathCompletion:^CGFloat(UITableView *tableView, NSIndexPath *indexPath) {
            return 50;
        }];
        
        [_searchController setDidSelectRowAtIndexPathCompletion:^(UITableView *tableView, NSIndexPath *indexPath) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            NSString *buddy = [weakSelf.searchController.resultsSource objectAtIndex:indexPath.row];
            [weakSelf.searchController.searchBar endEditing:YES];
            JDRPChatViewController *chatVC = [[JDRPChatViewController alloc] initWithConversationChatter:buddy
                                                                                        conversationType:EMConversationTypeChat];
           // chatVC.title = [UserCacheManager getNickById:buddy];
            [weakSelf.navigationController pushViewController:chatVC animated:YES];
        }];
    }
    return _searchController;
}
         
#pragma mark - Table view data source

- (void)groupListViewControllerDidSelected:(EMGroup *)group
{
    self.selectedGroup = group;
    self.selectedUser = nil;
    NSString *str = [NSString stringWithFormat:@"确定发送给：%@",group.subject];
    UIAlertView * alt = [[UIAlertView alloc] initWithTitle:str
                                                   message:nil
                                                  delegate:self
                                         cancelButtonTitle:@"Cancel"
                                         otherButtonTitles:@"OK", nil];
    [alt show];
}
         
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        if(self.selectedBlock)
        {
            if (self.selectedUser)
            {
                self.selectedBlock(self.selectedUser,SelectedTypeUser);
            } else
            {
                self.selectedBlock(self.selectedGroup,SelectedTypeGroup);
            }
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.dataArray count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    }
    return [[self.dataArray objectAtIndex:(section - 1)] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        NSString *CellIdentifier = @"commonCell";
        EaseUserCell *cell = (EaseUserCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[EaseUserCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        cell.avatarView.image = [UIImage imageNamed:@"EaseUIResource.bundle/group"];
        cell.titleLabel.text = NSLocalizedString(@"title.group", @"Group");
        return cell;
    }
    else{
        NSString *CellIdentifier = [EaseUserCell cellIdentifierWithModel:nil];
        EaseUserCell *cell = (EaseUserCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[EaseUserCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        NSArray *userSection = [self.dataArray objectAtIndex:(indexPath.section - 1)];
        EaseUserModel *model = [userSection objectAtIndex:indexPath.row];
        // 头像和昵称
        UserProfileEntity *profile = [[UserProfileManager sharedInstance] getUserProfileByUsername:model.buddy];
        if (profile) {
            if (profile.nickname && profile.nickname.length > 0) {
                model.nickname = profile.nickname;
            } else {
                model.nickname = model.buddy;
            }
        } else {
            model.nickname = model.buddy;
        }
        model.avatarURLPath = profile.imageUrl;
        cell.indexPath = indexPath;
        cell.model = model;
        return cell;
    }}

#pragma mark - Table view delegate
         
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.sectionTitles;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 0;
    }
    else{
        return 22;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return nil;
    }
    UIView *contentView = [[UIView alloc] init];
    [contentView setBackgroundColor:[UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:1.0]];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, 22)];
    label.backgroundColor = [UIColor clearColor];
    [label setText:[self.sectionTitles objectAtIndex:(section - 1)]];
    [contentView addSubview:label];
    return contentView;
}

         
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    if (section == 0) {
        JDRPGroupListViewController *groupController = [[JDRPGroupListViewController alloc] initWithStyle:UITableViewStylePlain];
        groupController.delegate = self;
        [self.navigationController pushViewController:groupController animated:YES];
    }
    else
    {
        self.selectedGroup = nil;
        self.selectedUser = [[self.dataArray objectAtIndex:(section - 1)] objectAtIndex:row];
        NSString *str = [NSString stringWithFormat:@"确定发送给：%@",self.selectedUser.nickname];
        UIAlertView * alt = [[UIAlertView alloc] initWithTitle:str
                                                       message:nil
                                                      delegate:self
                                             cancelButtonTitle:@"Cancel"
                                             otherButtonTitles:@"OK", nil];
        [alt show];
    }
}

#pragma mark - UISearchBarDelegate
                                                          
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    __weak typeof(self) weakSelf = self;
    [[RealtimeSearchUtil currentUtil] realtimeSearchWithSource:self.contactsSource
                                                    searchText:(NSString *)searchText
                                       collationStringSelector:@selector(showName)
                                                   resultBlock:^(NSArray *results) {
                                                       if (results) {
                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                [weakSelf.searchController.resultsSource removeAllObjects];
                                                                [weakSelf.searchController.resultsSource addObjectsFromArray:results];
                                                                [weakSelf.searchController.searchResultsTableView reloadData];
                                                            });
                                                       }
    }];
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    [[RealtimeSearchUtil currentUtil] realtimeSearchStop];
    [searchBar resignFirstResponder];
    [searchBar setShowsCancelButton:NO animated:YES];
}
#pragma mark - private data
                                                          
- (void)_sortDataArray:(NSArray *)buddyList
{
    [self.dataArray removeAllObjects];
    [self.sectionTitles removeAllObjects];
    NSMutableArray *contactsSource = [NSMutableArray array];

    //从获取的数据中剔除黑名单中的好友
    NSArray *blockList = [[EMClient sharedClient].contactManager getBlackList];
    for (NSString *buddy in buddyList) {
        if (![blockList containsObject:buddy]) {
            [contactsSource addObject:buddy];
        }
    }
    
    //建立索引的核心, 返回27，是a－z和＃
    UILocalizedIndexedCollation *indexCollation = [UILocalizedIndexedCollation currentCollation];
    [self.sectionTitles addObjectsFromArray:[indexCollation sectionTitles]];
    
    NSInteger highSection = [self.sectionTitles count];
    NSMutableArray *sortedArray = [NSMutableArray arrayWithCapacity:highSection];
    for (int i = 0; i < highSection; i++) {
        NSMutableArray *sectionArray = [NSMutableArray arrayWithCapacity:1];
        [sortedArray addObject:sectionArray];
    }
    
    //按首字母分组
    for (NSString *buddy in contactsSource) {
        EaseUserModel *model = [[EaseUserModel alloc] initWithBuddy:buddy];
        if (model) {
            model.avatarImage = [UIImage imageNamed:@"chatListCellHead"];
            UserProfileEntity *profile = [[UserProfileManager sharedInstance] getUserProfileByUsername:model.buddy];
            if (profile) {
                if (profile.nickname && profile.nickname.length > 0) {
                    model.nickname = profile.nickname;
                } else {
                    model.nickname = model.buddy;
                }
            } else {
                model.nickname = model.buddy;
            }
            model.avatarURLPath = profile.imageUrl;
            NSString *firstLetter = [EaseChineseToPinyin pinyinFromChineseString:model.nickname];
            NSInteger section = [indexCollation sectionForObject:[firstLetter substringToIndex:1] collationStringSelector:@selector(uppercaseString)];
            NSMutableArray *array = [sortedArray objectAtIndex:section];
            [array addObject:model];
        }
    }
    
    //每个section内的数组排序
    for (int i = 0; i < [sortedArray count]; i++) {
        NSArray *array = [[sortedArray objectAtIndex:i] sortedArrayUsingComparator:^NSComparisonResult(EaseUserModel *obj1, EaseUserModel *obj2) {
            NSString *firstLetter1 = [EaseChineseToPinyin pinyinFromChineseString:obj1.buddy];
            firstLetter1 = [[firstLetter1 substringToIndex:1] uppercaseString];
            
            NSString *firstLetter2 = [EaseChineseToPinyin pinyinFromChineseString:obj2.buddy];
            firstLetter2 = [[firstLetter2 substringToIndex:1] uppercaseString];
            
            return [firstLetter1 caseInsensitiveCompare:firstLetter2];
        }];
        
        
        [sortedArray replaceObjectAtIndex:i withObject:[NSMutableArray arrayWithArray:array]];
    }
    
    //去掉空的section
    for (NSInteger i = [sortedArray count] - 1; i >= 0; i--) {
        NSArray *array = [sortedArray objectAtIndex:i];
        if ([array count] == 0) {
            [sortedArray removeObjectAtIndex:i];
            [self.sectionTitles removeObjectAtIndex:i];
        }
    }
    
    [self.dataArray addObjectsFromArray:sortedArray];
    [self.tableView reloadData];
}
                                                          
#pragma mark - data
                                                          
- (void)tableViewDidTriggerHeaderRefresh
{
    [self showHudInView:self.view hint:NSLocalizedString(@"loadData", @"Load data...")];
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = nil;
        NSArray *buddyList = [[EMClient sharedClient].contactManager getContactsFromServerWithError:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideHud];
        });
        if (!error) {
            [[EMClient sharedClient].contactManager getBlackListFromServerWithError:&error];
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.contactsSource removeAllObjects];
                    for (NSInteger i = (buddyList.count - 1); i >= 0; i--) {
                        NSString *username = [buddyList objectAtIndex:i];
                        [weakself.contactsSource addObject:username];
                    }
                    [weakself _sortDataArray:self.contactsSource];
                });
            }
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself showHint:NSLocalizedString(@"loadDataFailed", @"Load data failed.")];
                [weakself reloadDataSource];
            });
        }
        [weakself tableViewDidFinishTriggerHeader:YES reload:NO];
    });
}

#pragma mark - public
                                                          
- (void)reloadDataSource
{
    [self.dataArray removeAllObjects];
    [self.contactsSource removeAllObjects];

    NSArray *buddyList = [[EMClient sharedClient].contactManager getContacts];

    for (NSString *buddy in buddyList) {
        [self.contactsSource addObject:buddy];
    }
    [self _sortDataArray:self.contactsSource];

    [self.tableView reloadData];
}

- (void)reloadGroupView
{
}



@end
