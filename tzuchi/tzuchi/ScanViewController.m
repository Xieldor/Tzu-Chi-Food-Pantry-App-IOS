//
//  ScanViewController.m
//  tzuchi
//
//  Created by TIANFANG XIE on 1/16/24.
//

#import "ScanViewController.h"
#import "QRScannerViewController.h"
#import "PickupRegistrationViewController.h"
#import <OHMySQL/OHMySQL.h>

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor lightGrayColor]; // 设置背景颜色为浅灰色

    // 计算按钮的总高度（包括间隔）
    CGFloat totalButtonsHeight = 4 * 50 + 3 * 20; // 3个按钮，每个按钮高度50，2个间隔，每个间隔20

    // 计算第一个按钮的起始y坐标
    CGFloat firstButtonY = (self.view.bounds.size.height - totalButtonsHeight) / 2;

    // 创建并添加按钮
    UIButton *scanButton = [self createCustomButtonWithTitle:@"注册扫描" backgroundColor:[UIColor colorWithRed:0.95 green:0.76 blue:0.20 alpha:1.0] action:@selector(scanButtonTapped) yPosition:firstButtonY];
    [self.view addSubview:scanButton];
    
    UIButton *menuRegisterButton = [self createCustomButtonWithTitle:@"取菜扫描" backgroundColor:[UIColor colorWithRed:0.47 green:0.67 blue:0.19 alpha:1.0]action:@selector(menuRegisterButtonTapped) yPosition:firstButtonY + 50 + 20];
    [self.view addSubview:menuRegisterButton];
    
    UIButton *countButton = [self createCustomButtonWithTitle:@"统计人数" backgroundColor:[UIColor colorWithRed:0.22 green:0.33 blue:0.44 alpha:1.0] action:@selector(countButtonTapped) yPosition:firstButtonY + 2 * (50 + 20)];
    [self.view addSubview:countButton];
    
    UIButton *backButton = [self createCustomButtonWithTitle:@"返回主界面" backgroundColor:[UIColor colorWithRed:0.36 green:0.54 blue:0.66 alpha:1.0] action:@selector(backAction) yPosition:firstButtonY + 3 * (50 + 20)];
    [self.view addSubview:backButton];
}

- (UIButton *)createCustomButtonWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor action:(SEL)action yPosition:(CGFloat)yPosition {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    
    [button setTitle:title forState:UIControlStateNormal];
    button.backgroundColor = backgroundColor; // 自定义背景颜色
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]; // 白色文字
    button.titleLabel.font = [UIFont boldSystemFontOfSize:18]; // 加粗字体
    button.layer.cornerRadius = 25; // 圆角
    button.layer.borderWidth = 2; // 边框宽度
    button.layer.borderColor = [UIColor whiteColor].CGColor; // 白色边框
    // 添加阴影
        button.layer.shadowColor = [UIColor blackColor].CGColor;
        button.layer.shadowOffset = CGSizeMake(0, 2);
        button.layer.shadowOpacity = 0.3;
        button.layer.shadowRadius = 4;
    button.frame = CGRectMake(50, yPosition, self.view.bounds.size.width - 100, 50);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];

    return button;
}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)menuRegisterButtonTapped {
    PickupRegistrationViewController *menuRegistrationVC = [[PickupRegistrationViewController alloc] init];
    menuRegistrationVC.databasePassword = self.databasePassword; // 传递密码
    menuRegistrationVC.databaseip = self.databaseip;
    menuRegistrationVC.databaseport = self.databaseport;
    menuRegistrationVC.databaseusername = self.databaseusername;
    menuRegistrationVC.databasedbName = self.databasedbName;
    menuRegistrationVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:menuRegistrationVC animated:YES completion:nil];
}

- (void)scanButtonTapped {
    QRScannerViewController *scannerVC = [[QRScannerViewController alloc] init];
    scannerVC.databasePassword = self.databasePassword; // 传递密码
    scannerVC.databaseip = self.databaseip;
    scannerVC.databaseport = self.databaseport;
    scannerVC.databaseusername = self.databaseusername;
    scannerVC.databasedbName = self.databasedbName;
    scannerVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:scannerVC animated:YES completion:nil];
}

- (void)countButtonTapped {
    NSString *todayString = [self currentDate];
    NSString *password = self.databasePassword;
    NSString *ip = self.databaseip;
    NSString *port = self.databaseport;
    NSString *username = self.databaseusername;
    NSString *dbName = self.databasedbName;

    // 创建数据库用户
    OHMySQLUser *user = [[OHMySQLUser alloc] initWithUserName:username
                                                     password:password
                                                   serverName:ip
                                                       dbName:dbName
                                                         port:[port integerValue]
                                                       socket:nil];

    // 创建存储协调器并连接
    OHMySQLStoreCoordinator *coordinator = [[OHMySQLStoreCoordinator alloc] initWithUser:user];
    [coordinator connect];

    // 创建查询上下文
    OHMySQLQueryContext *queryContext = [OHMySQLQueryContext new];
    queryContext.storeCoordinator = coordinator;

    // 创建查询请求
    NSString *queryStr = [NSString stringWithFormat:@"last_time='%@'", todayString];
    OHMySQLQueryRequest *queryRequest = [OHMySQLQueryRequestFactory SELECT:dbName condition:queryStr];

    // 执行查询
    NSError *error = nil;
    NSArray *response = [queryContext executeQueryRequestAndFetchResult:queryRequest error:&error];

    // 断开数据库连接
    [coordinator disconnect];

    // 获取查询结果

    if (response && response.count >= 0) {
        // 在主线程中显示结果
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"取菜人数" message:[NSString stringWithFormat:@"今天的取菜人数总共是：%ld 人", response.count] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"获取信息失败" message:[NSString stringWithFormat:@"远程服务器无响应，请检查您的网络设置。"] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        });
    }
}

- (NSString *)currentDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMddyyyy"];
    return [dateFormatter stringFromDate:[NSDate date]];
}

@end
