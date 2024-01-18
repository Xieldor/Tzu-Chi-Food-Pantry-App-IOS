//
//  ScanViewController.m
//  tzuchi
//
//  Created by TIANFANG XIE on 1/16/24.
//

#import "ScanViewController.h"
#import "QRScannerViewController.h"
#import "PickupRegistrationViewController.h"

@implementation ScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor lightGrayColor]; // 设置背景颜色为浅灰色

    // 计算按钮的总高度（包括间隔）
    CGFloat totalButtonsHeight = 3 * 50 + 2 * 20; // 3个按钮，每个按钮高度50，2个间隔，每个间隔20

    // 计算第一个按钮的起始y坐标
    CGFloat firstButtonY = (self.view.bounds.size.height - totalButtonsHeight) / 2;

    // 创建并添加按钮
    UIButton *scanButton = [self createCustomButtonWithTitle:@"注册扫描" backgroundColor:[UIColor colorWithRed:0.95 green:0.76 blue:0.20 alpha:1.0] action:@selector(scanButtonTapped) yPosition:firstButtonY];
    [self.view addSubview:scanButton];
    
    UIButton *menuRegisterButton = [self createCustomButtonWithTitle:@"取菜登记" backgroundColor:[UIColor colorWithRed:0.22 green:0.33 blue:0.44 alpha:1.0] action:@selector(menuRegisterButtonTapped) yPosition:firstButtonY + 50 + 20];
    [self.view addSubview:menuRegisterButton];
    
    UIButton *backButton = [self createCustomButtonWithTitle:@"返回主界面" backgroundColor:[UIColor colorWithRed:0.36 green:0.54 blue:0.66 alpha:1.0] action:@selector(backAction) yPosition:firstButtonY + 2 * (50 + 20)];
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

@end
