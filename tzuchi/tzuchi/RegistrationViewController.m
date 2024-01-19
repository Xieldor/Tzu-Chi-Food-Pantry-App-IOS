//
//  RegistrationViewController.m
//  tzuchi
//
//  Created by TIANFANG XIE on 1/16/24.
//

#import "RegistrationViewController.h"
#import <OHMySQL/OHMySQL.h>

@interface RegistrationViewController ()

@property (strong, nonatomic) UITextField *aptNumberTextField;
@property (strong, nonatomic) UITextField *elderlyCountTextField;
@property (strong, nonatomic) UITextField *adultCountTextField;
@property (strong, nonatomic) UITextField *childrenCountTextField;
@property (strong, nonatomic) UITextField *phoneNumberTextField; // 新增电话号码输入框
@property (strong, nonatomic) UISwitch *veteranSwitch;

@end

@implementation RegistrationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor]; // 设置背景颜色为黑色

    [self setupUI];
}

- (void)setupUI {
    CGFloat yPosition = 80; // 初始y位置
    CGFloat textFieldHeight = 40;
    CGFloat labelWidth = 150;
    CGFloat spacing = 10; // 标签和输入框之间的间隔
    CGFloat textFieldWidth = self.view.bounds.size.width - labelWidth - spacing - 40;
    CGFloat horizontalMargin = 20;
    CGFloat verticalMargin = 10;

    // 创建公寓号码标签和输入框
    [self createLabelWithText:@"公寓号码" frame:CGRectMake(horizontalMargin, yPosition, labelWidth, textFieldHeight)];
    self.aptNumberTextField = [self createTextFieldWithPlaceholder:@"请输入" frame:CGRectMake(horizontalMargin + labelWidth + spacing, yPosition, textFieldWidth, textFieldHeight)];
    self.aptNumberTextField.text = self.defaultAptNumber ?:self.roomNumber; // 设置默认值
    [self.view addSubview:self.aptNumberTextField];
    yPosition += textFieldHeight + verticalMargin;
    
    // 创建65岁以上老人人数标签和输入框
    [self createLabelWithText:@"65岁以上老人人数" frame:CGRectMake(horizontalMargin, yPosition, labelWidth, textFieldHeight)];
    self.elderlyCountTextField = [self createTextFieldWithPlaceholder:@"请输入" frame:CGRectMake(horizontalMargin + labelWidth + spacing, yPosition, textFieldWidth, textFieldHeight)];
    self.elderlyCountTextField.text = self.defaultElderlyCount ?:@"0";
    [self.view addSubview:self.elderlyCountTextField];
    yPosition += textFieldHeight + verticalMargin;
    
    // 创建65-17岁人数标签和输入框
    [self createLabelWithText:@"65-17岁人数" frame:CGRectMake(horizontalMargin, yPosition, labelWidth, textFieldHeight)];
    self.adultCountTextField = [self createTextFieldWithPlaceholder:@"请输入" frame:CGRectMake(horizontalMargin + labelWidth + spacing, yPosition, textFieldWidth, textFieldHeight)];
    self.adultCountTextField.text = self.defaultAdultCount ?:@"0";
    [self.view addSubview:self.adultCountTextField];
    yPosition += textFieldHeight + verticalMargin;
    
    // 创建17岁以下人数标签和输入框
    [self createLabelWithText:@"17岁以下人数" frame:CGRectMake(horizontalMargin, yPosition, labelWidth, textFieldHeight)];
    self.childrenCountTextField = [self createTextFieldWithPlaceholder:@"请输入" frame:CGRectMake(horizontalMargin + labelWidth + spacing, yPosition, textFieldWidth, textFieldHeight)];
    self.childrenCountTextField.text = self.defaultChildrenCount ?:@"0";
    [self.view addSubview:self.childrenCountTextField];
    yPosition += textFieldHeight + verticalMargin;
    
    // 创建电话号码标签和输入框
    [self createLabelWithText:@"电话号码" frame:CGRectMake(horizontalMargin, yPosition, labelWidth, textFieldHeight)];
    self.phoneNumberTextField = [self createTextFieldWithPlaceholder:@"请输入" frame:CGRectMake(horizontalMargin + labelWidth + spacing, yPosition, textFieldWidth, textFieldHeight)];
    self.phoneNumberTextField.text = self.defaultPhoneNumber ?: @"";
    [self.view addSubview:self.phoneNumberTextField];
    yPosition += textFieldHeight + verticalMargin;
    
    // 创建退役军人标签和开关
    [self createLabelWithText:@"退役军人:" frame:CGRectMake(horizontalMargin, yPosition, labelWidth, textFieldHeight)];
    self.veteranSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(horizontalMargin + labelWidth + 10, yPosition, 100, textFieldHeight)];
    self.veteranSwitch.on = [self.defaultVeteran isEqualToString:@"1"];
    [self.view addSubview:self.veteranSwitch];
    yPosition += textFieldHeight + verticalMargin;
    
    // 创建返回主菜单按钮
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [backButton setTitle:@"返回主菜单" forState:UIControlStateNormal];
    backButton.frame = CGRectMake(horizontalMargin, yPosition, self.view.bounds.size.width - 2 * horizontalMargin, textFieldHeight);
    [backButton addTarget:self action:@selector(backToHome) forControlEvents:UIControlEventTouchUpInside];
    backButton.tintColor = [UIColor whiteColor]; // 设置按钮文字颜色
    [self.view addSubview:backButton];
    yPosition += textFieldHeight + verticalMargin;
    
    // 创建提交按钮
    UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [submitButton setTitle:@"提交并继续扫描" forState:UIControlStateNormal];
    submitButton.frame = CGRectMake(horizontalMargin, yPosition, self.view.bounds.size.width - 2 * horizontalMargin, textFieldHeight);
    [submitButton addTarget:self action:@selector(submitAction) forControlEvents:UIControlEventTouchUpInside];
    submitButton.tintColor = [UIColor whiteColor]; // 设置按钮文字颜色
    [self.view addSubview:submitButton];
    
}

- (UITextField *)createTextFieldWithPlaceholder:(NSString *)placeholder frame:(CGRect)frame {
    UITextField *textField = [[UITextField alloc] initWithFrame:frame];
    textField.placeholder = placeholder;
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.backgroundColor = [UIColor whiteColor];
    textField.textColor = [UIColor blackColor];
    return textField;
}

- (void)createLabelWithText:(NSString *)text frame:(CGRect)frame {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = text;
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:label];
}

id valueOrNSNull(id value) {
    return value ? value : [NSNull null];
}

- (void)submitAction {
    // 准备地址字符串
    NSString *fullAddress = [NSString stringWithFormat:@"%@ %@ %@", self.address, valueOrNSNull(self.aptNumberTextField.text), self.city];

    // 在后台线程执行数据库查询
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 数据库连接和查询配置...
        // 这里插入使用OHMySQL写入数据到数据库的代码
        NSString *password = self.databasePassword;
        NSString *ip = self.databaseip;
        NSString *port = self.databaseport;
        NSString *username = self.databaseusername;
        NSString *dbName = self.databasedbName;
        OHMySQLUser *user = [[OHMySQLUser alloc] initWithUserName:username
                                                         password:password
                                                       serverName:ip
                                                           dbName:dbName
                                                             port:[port integerValue]
                                                           socket:nil];
        OHMySQLStoreCoordinator *coordinator = [[OHMySQLStoreCoordinator alloc] initWithUser:user];
        [coordinator connect];
        OHMySQLQueryContext *queryContext = [OHMySQLQueryContext new];
        queryContext.storeCoordinator = coordinator;
        NSError *error = nil;

        // 查询是否存在与当前地址相同但驾照号不同的记录
        NSString *queryStr = [NSString stringWithFormat:@"CONCAT(address_street, ' ', apt_number, ' ', address_city) = '%@' AND license_number != '%@'", fullAddress, self.licenseNumber];
        NSLog(@"Query: %@", queryStr);
        OHMySQLQueryRequest *queryRequest = [OHMySQLQueryRequestFactory SELECT:dbName condition:queryStr];
        NSArray *response = [queryContext executeQueryRequestAndFetchResult:queryRequest error:&error];

        // 如果查询到重复地址
        if (response && response.count > 0) {
            // 回到主线程显示对话框
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showDuplicateAddressAlert:response];
            });
        } else {
            // 如果没有重复地址或查询失败，继续执行添加或更新操作
            NSLog(@"Error executing query: %@", error);
            [self addOrUpdateRecord];
        }
    });
}

- (void)showDuplicateAddressAlert:(NSArray *)duplicates {
    NSMutableString *message = [NSMutableString stringWithString:@"以下驾照已经注册在同一地址:\n"];
    for (NSDictionary *duplicate in duplicates) {
        [message appendFormat:@"%@ %@\n", duplicate[@"first_name"], duplicate[@"last_name"]];
    }
    [message appendString:@"请选择操作："];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"地址冲突" message:message preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *addAction = [UIAlertAction actionWithTitle:@"直接添加/更新此驾照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self addOrUpdateRecord];
    }];

    UIAlertAction *deleteAndAddAction = [UIAlertAction actionWithTitle:@"删除其他所有重复用户，并添加/更新此驾照" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self deleteDuplicatesAndAddRecord:duplicates];
    }];

    [alert addAction:addAction];
    [alert addAction:deleteAndAddAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)addOrUpdateRecord {
    
    NSString *aptNumber = self.aptNumberTextField.text;
    NSString *elderlyCount = self.elderlyCountTextField.text;
    NSString *adultCount = self.adultCountTextField.text;
    NSString *childrenCount = self.childrenCountTextField.text;
    NSString *phoneNumber = self.phoneNumberTextField.text;
    BOOL isVeteran = self.veteranSwitch.isOn;
    
    // 执行后台线程数据库写入操作
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 准备要写入的数据
        NSDictionary *dataToInsert = @{
            @"license_number": valueOrNSNull(self.licenseNumber),
            @"first_name": valueOrNSNull(self.firstName),
            @"middle_name": valueOrNSNull(self.middleName),
            @"last_name": valueOrNSNull(self.lastName),
            @"gender": valueOrNSNull(self.gender),
            @"address_street": valueOrNSNull(self.address),
            @"apt_number": valueOrNSNull(aptNumber),
            @"address_city": valueOrNSNull(self.city),
            @"address_state": valueOrNSNull(self.state),
            @"address_zip": valueOrNSNull(self.zipCode),
            @"birthDate": valueOrNSNull(self.dateOfBirth),
            @"population_over_65": valueOrNSNull(elderlyCount),
            @"population_17_to_64": valueOrNSNull(adultCount),
            @"population_under_17": valueOrNSNull(childrenCount),
            @"veteran": isVeteran ? @"1" : @"0",
            @"phone_number": valueOrNSNull(phoneNumber),
            @"last_time": @"00000000" // 默认值，假设总是有一个值
        };
        
        NSDictionary *dataToUpdate = @{
            @"apt_number": valueOrNSNull(aptNumber),
            @"population_over_65": valueOrNSNull(elderlyCount),
            @"population_17_to_64": valueOrNSNull(adultCount),
            @"population_under_17": valueOrNSNull(childrenCount),
            @"veteran": isVeteran ? @"1" : @"0",
            @"phone_number": valueOrNSNull(phoneNumber),
        };
        
        // 这里插入使用OHMySQL写入数据到数据库的代码
        NSString *password = self.databasePassword;
        NSString *ip = self.databaseip;
        NSString *port = self.databaseport;
        NSString *username = self.databaseusername;
        NSString *dbName = self.databasedbName;
        OHMySQLUser *user = [[OHMySQLUser alloc] initWithUserName:username
                                                         password:password
                                                       serverName:ip
                                                           dbName:dbName
                                                             port:[port integerValue]
                                                           socket:nil];
        OHMySQLStoreCoordinator *coordinator = [[OHMySQLStoreCoordinator alloc] initWithUser:user];
        [coordinator connect];
        
        // 创建查询
        OHMySQLQueryContext *queryContext = [OHMySQLQueryContext new];
        queryContext.storeCoordinator = coordinator;
        NSError *error = nil;
        
        if (self.isUpdateOperation) {
            NSString *licenseNumber = self.licenseNumber;
            OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory UPDATE:dbName set:dataToUpdate condition:[NSString stringWithFormat:@"license_number='%@'", licenseNumber]];
            
            // 执行查询
            [queryContext executeQueryRequest:query error:&error];
        } else {
            OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory INSERT:dbName set:dataToInsert];
            
            // 执行查询
            [queryContext executeQueryRequest:query error:&error];
        }
        
        // 断开数据库连接
        [coordinator disconnect];
        
        // 当数据库操作完成后，如果需要更新UI，回到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            // 这里写任何需要在主线程执行的代码，比如关闭视图控制器
            if (!error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 创建一个标签来显示成功信息
                    UILabel *successLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 50)];
                    successLabel.center = self.view.center;
                    successLabel.backgroundColor = [UIColor blackColor];
                    successLabel.textColor = [UIColor whiteColor];
                    successLabel.textAlignment = NSTextAlignmentCenter;
                    successLabel.text = @"驾照录入/修改成功";
                    successLabel.alpha = 0;

                    [self.view addSubview:successLabel];

                    // 渐显标签
                    [UIView animateWithDuration:0.5 animations:^{
                        successLabel.alpha = 1;
                    } completion:^(BOOL finished) {
                        // 几秒后渐隐标签
                        [UIView animateWithDuration:0.5 delay:1.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                            successLabel.alpha = 0;
                        } completion:^(BOOL finished) {
                            [successLabel removeFromSuperview];
                            // 在标签渐隐完成后再关闭视图控制器
                            [self dismissViewControllerAnimated:YES completion:nil];
                        }];
                    }];
                });
            } else {
                // 如果有错误，也关闭视图控制器
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            
        });
    });
}

- (void)deleteDuplicatesAndAddRecord:(NSArray *)duplicates {
    // 在后台线程执行删除操作
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 数据库连接配置...
        // 这里插入使用OHMySQL写入数据到数据库的代码
        NSString *password = self.databasePassword;
        NSString *ip = self.databaseip;
        NSString *port = self.databaseport;
        NSString *username = self.databaseusername;
        NSString *dbName = self.databasedbName;
        OHMySQLUser *user = [[OHMySQLUser alloc] initWithUserName:username
                                                         password:password
                                                       serverName:ip
                                                           dbName:dbName
                                                             port:[port integerValue]
                                                           socket:nil];
        OHMySQLStoreCoordinator *coordinator = [[OHMySQLStoreCoordinator alloc] initWithUser:user];
        [coordinator connect];
        
        // 创建查询
        OHMySQLQueryContext *queryContext = [OHMySQLQueryContext new];
        queryContext.storeCoordinator = coordinator;

        // 删除操作
        for (NSDictionary *duplicate in duplicates) {
            NSString *licenseNumberToDelete = duplicate[@"license_number"];
            NSString *deleteQueryStr = [NSString stringWithFormat:@"license_number = '%@'", licenseNumberToDelete];
            OHMySQLQueryRequest *deleteQuery = [OHMySQLQueryRequestFactory DELETE:dbName condition:deleteQueryStr];
            [queryContext executeQueryRequest:deleteQuery error:nil];
        }

        // 添加新记录
        [self addOrUpdateRecord];
    });
}

- (void)backToHome {
    // 这里可以添加一些清理工作，如果需要的话
    // 然后关闭视图控制器
    UIViewController *presentingController = self.presentingViewController;

        // 然后我们关闭 RegistrationViewController
        [self dismissViewControllerAnimated:NO completion:^{
            // 然后关闭 QRScannerViewController
            [presentingController dismissViewControllerAnimated:YES completion:nil];
        }];
}

    @end
