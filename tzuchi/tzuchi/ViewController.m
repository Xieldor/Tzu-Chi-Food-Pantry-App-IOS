//
//  ViewController.m
//  tzuchi
//
//  Created by TIANFANG XIE on 1/15/24.
//


// ViewController.m

#import "ViewController.h"
#import "QRScannerViewController.h"
#import "ScanViewController.h"
#import <OHMySQL/OHMySQL.h>

@interface ViewController () <UIPickerViewDelegate, UIPickerViewDataSource>
@property (strong, nonatomic) UIPickerView *serverPicker;
@property (strong, nonatomic) NSArray *serverOptions;
@property (strong, nonatomic) UITextField *passwordField;
@property (strong, nonatomic) UILabel *connectionStatusLabel; // 用于显示连接状态的标签
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置整体背景颜色
    self.view.backgroundColor = [UIColor colorWithRed:0.85 green:0.95 blue:0.90 alpha:1.0];

    // 添加图标
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Image"]];
    CGFloat newWidth = 250; // 新的宽度
    CGFloat newHeight = logoImageView.frame.size.height * (newWidth / logoImageView.frame.size.width); // 保持原有的宽高比
    logoImageView.frame = CGRectMake((self.view.bounds.size.width - newWidth) / 2, 80, newWidth, newHeight);
    [self.view addSubview:logoImageView];

    // 添加标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 220, self.view.bounds.size.width - 40, 60)];
    titleLabel.text = @"慈济取菜登记";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:48]; // 更大的字体
    titleLabel.textColor = [UIColor redColor];
    [self.view addSubview:titleLabel];
    
    // 在下拉菜单上方添加提示文字
    UILabel *serverLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 300, self.view.bounds.size.width - 40, 40)];
    serverLabel.text = @"请选择服务器";
    serverLabel.font = [UIFont boldSystemFontOfSize:18]; // 更大的字体
    serverLabel.textColor = [UIColor brownColor];
    serverLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:serverLabel];

    // 添加下拉菜单
    self.serverOptions = @[@"波士顿服务器", @"台湾服务器", @"加州服务器"];
    [self.serverPicker reloadAllComponents];
    self.serverPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(20, 320, self.view.bounds.size.width - 40, 100)];
    self.serverPicker.delegate = self;
    self.serverPicker.dataSource = self;
    [self.view addSubview:self.serverPicker];
    

    // 添加输入框及其左侧文字
    UILabel *passwordLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 420, 180, 30)];
    passwordLabel.text = @"请输入服务器密码";
    passwordLabel.textColor = [UIColor brownColor];
    [self.view addSubview:passwordLabel];

    self.passwordField = [[UITextField alloc] initWithFrame:CGRectMake(210, 420, self.view.bounds.size.width - 230, 30)];
    self.passwordField.borderStyle = UITextBorderStyleRoundedRect;
    self.passwordField.backgroundColor = [UIColor grayColor];
    self.passwordField.secureTextEntry = YES; // 设置密码框隐藏输入内容
    [self.view addSubview:self.passwordField];
    
    CGFloat buttonWidth = (self.view.bounds.size.width - 40) / 2;
    CGFloat buttonHeight = 40;
    CGFloat buttonX = (self.view.bounds.size.width - buttonWidth) / 2;
    
    // 添加测试数据库连接按钮
    UIButton *testDbButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [testDbButton setTitle:@"测试数据库连接" forState:UIControlStateNormal];
    testDbButton.frame = CGRectMake(buttonX, 480, buttonWidth, buttonHeight);
    [testDbButton addTarget:self action:@selector(testDatabaseConnection) forControlEvents:UIControlEventTouchUpInside];
    [self styleButton:testDbButton withBackgroundColor:[UIColor colorWithRed:0.75 green:0.85 blue:0.80 alpha:1.0] textColor:[UIColor darkGrayColor]];
    [self.view addSubview:testDbButton];

    // 添加开始使用按钮
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [startButton setTitle:@"开始使用" forState:UIControlStateNormal];
    startButton.frame = CGRectMake(buttonX, 530, buttonWidth, buttonHeight);
    [startButton addTarget:self action:@selector(startUsingApp) forControlEvents:UIControlEventTouchUpInside];
    [self styleButton:startButton withBackgroundColor:[UIColor colorWithRed:0.55 green:0.65 blue:0.60 alpha:1.0] textColor:[UIColor redColor]];
    [self.view addSubview:startButton];
    
    // 添加退出程序按钮
    UIButton *exitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [exitButton setTitle:@"退出程序" forState:UIControlStateNormal];
    exitButton.frame = CGRectMake(buttonX, 580, buttonWidth, buttonHeight);
    [exitButton addTarget:self action:@selector(exitApplication) forControlEvents:UIControlEventTouchUpInside];
    [self styleButton:exitButton withBackgroundColor:[UIColor colorWithRed:0.55 green:0.65 blue:0.60 alpha:1.0] textColor:[UIColor darkGrayColor]];
    [self.view addSubview:exitButton];
    
    // 添加一个触摸事件来隐藏键盘
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.view addGestureRecognizer:tapGesture];
    
    // 添加版权信息
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height - 190, self.view.bounds.size.width - 40, 30)];
    versionLabel.text = @"版本号：1.1.0";
    versionLabel.font = [UIFont boldSystemFontOfSize:12];
    versionLabel.textColor = [UIColor purpleColor];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:versionLabel];

    UILabel *authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height - 160, self.view.bounds.size.width - 40, 30)];
    authorLabel.text = @"作者：T & Haixin";
    authorLabel.font = [UIFont boldSystemFontOfSize:12];
    authorLabel.textColor = [UIColor purpleColor];
    authorLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:authorLabel];

    // 添加“Supported by”文字
    UILabel *supportedByLabel = [[UILabel alloc] init];
    supportedByLabel.text = @"Supported by";
    supportedByLabel.textAlignment = NSTextAlignmentRight;
    supportedByLabel.font = [UIFont boldSystemFontOfSize:12];
    supportedByLabel.textColor = [UIColor purpleColor];
    CGFloat labelHeight = 30;
    CGFloat labelWidth = 120;
    CGFloat imageWidth = 100; // 根据实际图片尺寸调整
    CGFloat imageHeight = 30; // 根据实际图片尺寸调整
    CGFloat totalWidth = labelWidth + imageWidth;

    // 设置文本标签的位置
    supportedByLabel.frame = CGRectMake((self.view.bounds.size.width - totalWidth) / 2 - 10, self.view.bounds.size.height - 130, labelWidth, labelHeight);
    [self.view addSubview:supportedByLabel];

    // 添加支持的图片
    UIImageView *supportImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Ali"]];
    supportImageView.frame = CGRectMake(supportedByLabel.frame.origin.x + labelWidth + 10, self.view.bounds.size.height - 130, imageWidth, imageHeight);
    [self.view addSubview:supportImageView];
    
    // 初始化并添加用于显示连接状态的标签
    self.connectionStatusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.view.bounds.size.height - 80, self.view.bounds.size.width - 40, 30)];
    self.connectionStatusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.connectionStatusLabel];
}

- (void)styleButton:(UIButton *)button withBackgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor {
    button.backgroundColor = backgroundColor;
    button.tintColor = textColor;
    button.layer.cornerRadius = 10;
    button.layer.masksToBounds = YES;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.serverOptions.count;
}

#pragma mark - UIPickerViewDelegate

// 为了改变字体大小和颜色
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *label = (UILabel *)view;
    if (!label) {
        label = [[UILabel alloc] init];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:12]; // 更小的字体
    }

    label.text = self.serverOptions[row];

    // 设置当前选中行的颜色
    if (row == [pickerView selectedRowInComponent:component]) {
        label.textColor = [UIColor blueColor]; // 选中项的颜色
    } else {
        label.textColor = [UIColor blackColor]; // 非选中项的颜色
    }

    return label;
}

// 当选择器滚动时更新视图
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    [pickerView reloadAllComponents];
}

- (void)startUsingApp {
    [self testDatabaseConnection];

    // 延迟执行，以便给数据库连接测试留出足够的时间
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // 这里检查连接状态
        if ([self.connectionStatusLabel.text isEqualToString:@"远程数据库连接成功，可以使用"]) {
            ScanViewController *scanVC = [[ScanViewController alloc] init];
            scanVC.databasePassword = self.passwordField.text;
            scanVC.databaseip = @"rm-rj9nf713uz07qt43qyo.mysql.rds.aliyuncs.com";
            scanVC.databaseport = @"3306";
            scanVC.databaseusername = @"haixin_guan";
            scanVC.databasedbName = @"tzuchi";
            scanVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:scanVC animated:YES completion:nil];
        } else {
            // 连接失败，显示错误提示
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" message:@"远程服务器无响应，请检查您的网络设置或者服务器登录密码。" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    });
}

#pragma mark - Actions

- (void)exitApplication {
    // 退出应用程序
    exit(0);
}

// 隐藏键盘的方法
- (void)hideKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Actions

- (void)testDatabaseConnection {
    // 检查是否选中了 "波士顿服务器"
    NSInteger selectedRow = [self.serverPicker selectedRowInComponent:0];
    NSString *selectedServer = self.serverOptions[selectedRow];
    if ([selectedServer isEqualToString:@"波士顿服务器"]) {
        // 获取密码输入框中的密码
        NSString *password = self.passwordField.text;
        NSString *ip = @"rm-rj9nf713uz07qt43qyo.mysql.rds.aliyuncs.com";
        NSString *port = @"3306";
        NSString *username = @"haixin_guan";
        NSString *dbName = @"tzuchi";
        NSString *socket = nil;
        
        // 配置数据库连接
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            OHMySQLUser *user = [[OHMySQLUser alloc] initWithUserName:username
                                                             password:password
                                                           serverName:ip
                                                               dbName:dbName
                                                                 port:[port integerValue]
                                                               socket:socket];
            
            OHMySQLStoreCoordinator *coordinator = [[OHMySQLStoreCoordinator alloc] initWithUser:user];
            [coordinator connect];
            
            BOOL isConnected = [coordinator isConnected];
            
            /// 回到主线程更新UI
            dispatch_async(dispatch_get_main_queue(), ^{
                if (isConnected) {
                    // 显示数据库连接成功的消息
                    [self showDatabaseConnectionSuccess];
                } else {
                    // 如果未选中 "波士顿服务器" 或连接失败
                    [self showDatabaseConnectionFailure];
                }
                [coordinator disconnect];
            });
        });
    } else {
        // 如果未选中 "波士顿服务器" 或连接失败
        [self showDatabaseConnectionFailure];
    }
}

- (void)showDatabaseConnectionSuccess {
    [self showMessage:@"远程数据库连接成功，可以使用" withColor:[UIColor redColor]];
}

- (void)showDatabaseConnectionFailure {
    [self showMessage:@"数据库连接失败" withColor:[UIColor redColor]];
}

- (void)showMessage:(NSString *)message withColor:(UIColor *)color {
    self.connectionStatusLabel.text = message;
    self.connectionStatusLabel.textColor = color;
    self.connectionStatusLabel.alpha = 1.0; // 确保标签是可见的

    // 5秒后淡出
    [UIView animateWithDuration:5.0 animations:^{
        self.connectionStatusLabel.alpha = 0.0;
    }];
}

@end
