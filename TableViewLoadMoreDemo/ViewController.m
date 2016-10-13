//
//  ViewController.m
//  TableViewLoadMoreDemo
//
//  Created by JiongXing on 2016/10/13.
//  Copyright © 2016年 JiongXing. All rights reserved.
//

#import "ViewController.h"
#import <MJRefresh.h>

@interface ViewController ()

@property (nonatomic, assign) NSInteger page;
@property (nonatomic, strong) NSMutableArray<NSString *> *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // config
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:NSStringFromClass([UITableViewCell class])];
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(onHeaderRefresh)];
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(onFooterRefresh)];
    self.tableView.tableFooterView = [UIView new];
    
    // data
    [self.tableView.mj_header beginRefreshing];
}

#pragma mark - Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([UITableViewCell class])];
    cell.textLabel.text = self.dataSource[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Action
/// 顶部刷新
- (void)onHeaderRefresh {
    [self requestServerDataReset:YES];
}

/// 底部加载更多
- (void)onFooterRefresh {
    [self requestServerDataReset:NO];
}

#pragma mark - Data
/// 请求服务器数据，由本方法对页码进行管理
- (void)requestServerDataReset:(BOOL)reset {
    if (reset) {
        self.page = 1;
    }
    self.title = [NSString stringWithFormat:@"正在请求第%@页", @(self.page)];
    [self generateServerDataWithPage:self.page finish:^(NSMutableArray<NSString *> *data) {
        [self.tableView.mj_header endRefreshing];
        [self.tableView.mj_footer endRefreshing];
        
        if (reset) {
            [self.dataSource removeAllObjects];
        }
        
        if (data && data.count) {
            [self.dataSource addObjectsFromArray:data];
            self.title = [NSString stringWithFormat:@"第%@页：成功返回%@条", @(self.page), @(data.count)];
            self.page ++;
        }
        else {
            self.title = [NSString stringWithFormat:@"第%@页：请求失败或无数据", @(self.page)];
        }
        [self.tableView reloadData];
    }];
}

/// 生成模拟数据，page从0开始
- (void)generateServerDataWithPage:(NSInteger)page finish:(void (^)(NSMutableArray<NSString *> *data))finish {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 模拟处理用时
        sleep(1);
        
        // 模拟网络异常
        static NSInteger flag = 0;
        if (++flag % 2 == 0) {
            NSLog(@"网络异常!");
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(nil);
            });
            return;
        }
        
        // 正常返回数据
        NSInteger dataCount = 10;
        NSMutableArray *arr = [NSMutableArray array];
        for (NSInteger index = 1; index <= dataCount; index ++) {
            [arr addObject:[NSString stringWithFormat:@"第%@页，第%@条", @(page), @(index)]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            finish(arr);
        });
    });
}

- (NSMutableArray<NSString *> *)dataSource {
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
