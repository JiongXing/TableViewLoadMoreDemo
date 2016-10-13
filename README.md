# TableViewLoadMoreDemo
TableView列表加载时的页码管理问题

> 本文是写给刚入行的新同学看。

#问题描述
在处理列表分页时，对于页码的管理很容易出bug。一个常见的误区是：在请求发起的同时对页码作了递增操作，由此造成了如果请求过程中出现网络异常，或者无数据返回时，页码的这一次递增就是无效的。
如果不处理，再次进行上拉加载时，会继续对页码递增，此时会造成之前请求失败的那一页数据缺失。
如果说在发现请求异常时，把页码减回去，会容易让处理逻辑变得复杂，且一边递增一边递减，不可靠而且不推荐。
正确的做法时，只有在成功取到我们希望的那一页数据时，再把页码作递增，始终让页码是指向未来要加载的那一页。
#示例
这里借助MJRefresh为TableView添加了顶部刷新和底部刷新：
```objc
self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(onHeaderRefresh)];
self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(onFooterRefresh)];
```

无论是重新刷新还是加载更多，都不应该知道页码的存在，在它们的响应方法角度看，只关心是否需要重置列表数据
```objc
/// 顶部刷新
- (void)onHeaderRefresh {
    [self requestServerDataReset:YES];
}

/// 底部加载更多
- (void)onFooterRefresh {
    [self requestServerDataReset:NO];
}
```
在数据请求方法里，统一管理页码。只有两处对页码进行赋值，分别是重置列表时和成功取到一页数据时：
```objc
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
```
另外是模拟服务响应、返回数据的方法
```objc
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
```

![TableViewLoadMoreDemo](https://github.com/JiongXing/TableViewLoadMoreDemo/raw/master/screenshots/TableViewLoadMoreDemo.gif)
