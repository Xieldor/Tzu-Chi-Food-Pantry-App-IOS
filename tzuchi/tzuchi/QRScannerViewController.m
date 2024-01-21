//
//  QRViewController.m
//  tzuchi
//
//  Created by TIANFANG XIE on 1/15/24.
//

#import "QRScannerViewController.h"
#import "RegistrationViewController.h"
#import <OHMySQL/OHMySQL.h>

@interface QRScannerViewController ()
@end

@implementation QRScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor]; // 设置初始背景色
    
    // 创建提醒文字标签
    self.reminderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 160, self.view.bounds.size.width, 50)];
    self.reminderLabel.text = @"请将摄像头对准美国驾照背面二维码";
    self.reminderLabel.textColor = [UIColor whiteColor]; // 设置文字颜色为白色
    self.reminderLabel.backgroundColor = [UIColor clearColor]; // 设置背景色为透明
    self.reminderLabel.textAlignment = NSTextAlignmentCenter; // 设置文字居中对齐
    self.reminderLabel.font = [UIFont systemFontOfSize:16]; // 设置字体大小
    self.reminderLabel.hidden = YES; // 初始隐藏
    [self.view addSubview:self.reminderLabel];
    
    [self setupCaptureSession];
    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startScanning];
}

- (void)setupCaptureSession {
    self.captureSession = [[AVCaptureSession alloc] init];
    AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:nil];

    if ([self.captureSession canAddInput:input]) {
        [self.captureSession addInput:input];
    } else {
        NSLog(@"Failed to add input to capture session");
    }

    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    if ([self.captureSession canAddOutput:captureMetadataOutput]) {
        [self.captureSession addOutput:captureMetadataOutput];
        [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        [captureMetadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypePDF417Code]];
    } else {
        NSLog(@"Failed to add output to capture session");
    }

    self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [self.videoPreviewLayer setFrame:self.view.layer.bounds];
    [self.view.layer addSublayer:self.videoPreviewLayer];
}

- (void)setupUI {
    
    // 创建背景遮罩
    self.backgroundMaskView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.backgroundMaskView.backgroundColor = [UIColor blackColor];
    self.backgroundMaskView.hidden = NO;  // 设置为不隐藏，以测试其是否显示
    [self.view addSubview:self.backgroundMaskView];
    
    // 创建扫描框
    self.scanFrameView = [[UIView alloc] initWithFrame:CGRectMake(self.view.center.x - 150, self.view.center.y - 150, 300, 300)];
    self.scanFrameView.layer.borderColor = [UIColor greenColor].CGColor;
    self.scanFrameView.layer.borderWidth = 2.0;
    

    // 创建扫描线
    self.scanLineLayer = [CALayer layer];
    self.scanLineLayer.frame = CGRectMake(0, 0, self.scanFrameView.frame.size.width, 2);
    self.scanLineLayer.backgroundColor = [UIColor redColor].CGColor;
    

    // 创建显示扫描结果的文本视图

    CGFloat textViewHeight = 200;
    CGFloat textViewY = (self.view.bounds.size.height - textViewHeight) / 2 - 180; // 使用 bounds 而不是 frame
    self.scannedTextTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, textViewY, self.view.bounds.size.width - 40, textViewHeight)];
    self.scannedTextTextView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.9];
    self.scannedTextTextView.textColor = [UIColor blackColor];
    self.scannedTextTextView.editable = NO;
    self.scannedTextTextView.layer.cornerRadius = 10;
    self.scannedTextTextView.hidden = YES;
    
    
    // 添加返回扫描的按钮
    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backButton setTitle:@"Back" forState:UIControlStateNormal];
    self.backButton.frame = CGRectMake(20, 40, 60, 30);
    [self.backButton addTarget:self action:@selector(backToScan) forControlEvents:UIControlEventTouchUpInside];
    self.backButton.hidden = YES;
    [self.view addSubview:self.backButton];
    
    // 添加返回主界面的按钮
    self.homeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.homeButton setTitle:@"Home" forState:UIControlStateNormal];
    self.homeButton.frame = CGRectMake(self.view.frame.size.width - 80, 40, 60, 30);
    [self.homeButton addTarget:self action:@selector(backToHome) forControlEvents:UIControlEventTouchUpInside];
    self.homeButton.hidden = YES;
    [self.view addSubview:self.homeButton];
    
    // 确保 UI 组件位于视频预览层之上
    [self.view bringSubviewToFront:self.backgroundMaskView];
    [self.view addSubview:self.scanFrameView];
    [self.scanFrameView.layer addSublayer:self.scanLineLayer];
    [self.view addSubview:self.scannedTextTextView];
    
    // 创建取消扫描返回主菜单按钮
    self.cancelScanButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.cancelScanButton setTitle:@"取消扫描，返回主菜单" forState:UIControlStateNormal];
    [self.cancelScanButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.cancelScanButton.frame = CGRectMake(20, self.view.bounds.size.height - 100, self.view.bounds.size.width - 40, 50);
    [self.cancelScanButton addTarget:self action:@selector(backToHome) forControlEvents:UIControlEventTouchUpInside];
    self.cancelScanButton.backgroundColor = [UIColor redColor]; // 醒目的背景色
    self.cancelScanButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    self.cancelScanButton.layer.cornerRadius = 10;
    self.cancelScanButton.hidden = YES; // 初始隐藏
    [self.view addSubview:self.cancelScanButton];
    
    
    [self.view bringSubviewToFront:self.reminderLabel]; // 将标签添加到视图中
}

- (void)startScanning {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.captureSession startRunning];

        dispatch_async(dispatch_get_main_queue(), ^{
            // 确保扫描框和扫描线是可见的
            self.scanFrameView.hidden = NO;
            self.scanLineLayer.hidden = NO;

            // 重新开始扫描线动画
            [self startScanLineAnimation];
            self.cancelScanButton.hidden = NO;
            self.reminderLabel.hidden = NO;
        });
    });

    self.backButton.hidden = YES;
    self.homeButton.hidden = YES;
    self.backgroundMaskView.hidden = YES;
    self.scannedTextTextView.hidden = YES;
}
   
- (void)startScanLineAnimation {
    self.scanLineLayer.hidden = NO;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.y"];
    animation.fromValue = @(0);
    animation.toValue = @(self.scanFrameView.frame.size.height);
    animation.duration = 2.0;
    animation.repeatCount = HUGE_VALF;
    animation.autoreverses = YES;
    [self.scanLineLayer addAnimation:animation forKey:@"scanLineAnimation"];
}

- (void)parseAndDisplayScannedData:(NSString *)scannedData {
    NSMutableDictionary *parsedData = [NSMutableDictionary new];
    
    NSArray *lines = [scannedData componentsSeparatedByString:@"\n"];
    NSString *roomNumber = @"NONE"; // 默认值
    NSString *expiryDate = @"Invalid Date"; // 默认日期值
    NSString *licenseNumber = @"Unknown"; // 默认值
    for (NSString *line in lines) {
        if ([line hasPrefix:@"DAH"]) {
            // 检查是否包含 'APT'，然后获取其后的内容作为房间号
            NSRange aptRange = [line rangeOfString:@"APT"];
            if (aptRange.location != NSNotFound) {
                NSString *roomNumberWithSpaces = [line substringFromIndex:aptRange.location + aptRange.length];
                // 去除房间号前后的空格
                roomNumber = [roomNumberWithSpaces stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            }
            continue;
        }
        NSRange dbaRange = [line rangeOfString:@"DBA"];
        if (dbaRange.location != NSNotFound && line.length >= dbaRange.location + dbaRange.length + 8) {
                    // 提取紧随 "DBA" 后的八位数字
                    NSString *dateString = [line substringWithRange:NSMakeRange(dbaRange.location + dbaRange.length, 8)];
                    expiryDate = [self formatDate:dateString];
                continue;
        }
        
        NSRange daqRange = [line rangeOfString:@"DAQ"];
        if (daqRange.location != NSNotFound) {
                // 假设 'DAQ' 后面的文本是我们需要的驾照号码
                NSString *licensePart = [line substringFromIndex:daqRange.location + daqRange.length];
                // 可能需要进一步处理licensePart，比如去除空格或其他不需要的字符
                licenseNumber = [licensePart stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            continue; // 找到后就可以跳出循环
        }
            
        if (line.length > 3) {
            NSString *key = [line substringToIndex:3];
            NSString *value = [line substringFromIndex:3];
            parsedData[key] = value;
        }
    }
    
    NSString *lastName = parsedData[@"DCS"];
    NSString *firstName = parsedData[@"DAC"];
    NSString *middleName = parsedData[@"DAD"] ?: @"NONE";
    NSString *dateOfBirth = [self formatDate:parsedData[@"DBB"]];
    NSString *gender = [parsedData[@"DBC"] isEqualToString:@"1"] ? @"Male" : @"Female";
    NSString *address = parsedData[@"DAG"];
    NSString *city = parsedData[@"DAI"];
    NSString *state = parsedData[@"DAJ"];
    NSString *zipCode = parsedData[@"DAK"];
    
    NSString *displayString = [NSString stringWithFormat:@"Expiry Date: %@\nLast Name: %@\nFirst Name: %@\nMiddle Name: %@\nDate of Birth: %@\nGender: %@\nAddress: %@\nRoom Number: %@\nCity: %@\nState: %@\nZip Code: %@\nLicense Number: %@", expiryDate, lastName, firstName, middleName, dateOfBirth, gender, address, roomNumber, city, state, zipCode, licenseNumber];
    
    NSString *zipCodePrefix = [zipCode substringToIndex:5];
    
    // 停止扫描
    [self.captureSession stopRunning];
    [self.scanLineLayer removeAllAnimations];
    self.scanLineLayer.hidden = YES;
    self.scanFrameView.hidden = YES;
    self.backButton.hidden = NO;
    self.homeButton.hidden = NO;
    
    self.backgroundMaskView.hidden = NO;
    
    
    self.scannedTextTextView.text = displayString;
    self.scannedTextTextView.hidden = NO;
    
    [self.view bringSubviewToFront:self.scannedTextTextView];

    // 确保返回按钮在最前
    [self.view bringSubviewToFront:self.backButton];
    [self.view bringSubviewToFront:self.homeButton];
    
    if ([self isLicenseExpired:expiryDate]) {
        // Display expired message and options to scan another or return to main menu
        [self handleExpiredLicense];
    } else if ([zipCodePrefix compare:@"02110"] >= 0 && [zipCodePrefix compare:@"02129"] <= 0) {
        // 邮编在02110到02129范围内，执行原有逻辑
        [self checkLicenseRegistration:licenseNumber withCompletion:^(BOOL isRegistered, NSArray *responseData) {
            if (!isRegistered) {
                [self handleUnregisteredLicenseWithRoomNumber:roomNumber
                                                   expiryDate:expiryDate
                                                     lastName:lastName
                                                    firstName:firstName
                                                   middleName:middleName
                                                  dateOfBirth:dateOfBirth
                                                        gender:gender
                                                       address:address
                                                          city:city
                                                         state:state
                                                      zipCode:zipCode
                                                licenseNumber:licenseNumber];
            } else {
                
                // 驾照已注册的处理
                [self handleRegisteredLicenseWithRoomNumber:roomNumber
                                                 expiryDate:expiryDate
                                                   lastName:lastName
                                                  firstName:firstName
                                                 middleName:middleName
                                                dateOfBirth:dateOfBirth
                                                      gender:gender
                                                     address:address
                                                        city:city
                                                       state:state
                                                    zipCode:zipCode
                                              licenseNumber:licenseNumber
                                               responseData:responseData]; // 假设 response 包含数据库返回的数据

            }
        }];} else {
            // 邮编不在02110到02129范围内，显示提示框
            // 在显示警告框前隐藏按钮
            self.cancelScanButton.hidden = YES;
            self.reminderLabel.hidden = YES;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"邮编范围错误"
                                                                           message:@"驾照邮编不在02110到02129范围内。"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *scanNextAction = [UIAlertAction actionWithTitle:@"扫描下一张" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self startScanning];
            }];
            UIAlertAction *registerAnywayAction = [UIAlertAction actionWithTitle:@"仍然登记当前驾照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                // 继续原有逻辑
                [self checkLicenseRegistration:licenseNumber withCompletion:^(BOOL isRegistered, NSArray *responseData) {
                    if (!isRegistered) {
                        [self handleUnregisteredLicenseWithRoomNumber:roomNumber
                                                           expiryDate:expiryDate
                                                             lastName:lastName
                                                            firstName:firstName
                                                           middleName:middleName
                                                          dateOfBirth:dateOfBirth
                                                                gender:gender
                                                               address:address
                                                                  city:city
                                                                 state:state
                                                              zipCode:zipCode
                                                        licenseNumber:licenseNumber];
                    } else {
                        
                        // 驾照已注册的处理
                        [self handleRegisteredLicenseWithRoomNumber:roomNumber
                                                         expiryDate:expiryDate
                                                           lastName:lastName
                                                          firstName:firstName
                                                         middleName:middleName
                                                        dateOfBirth:dateOfBirth
                                                              gender:gender
                                                             address:address
                                                                city:city
                                                               state:state
                                                            zipCode:zipCode
                                                      licenseNumber:licenseNumber
                                                       responseData:responseData]; // 假设 response 包含数据库返回的数据

                    }
                }];
            }];
            [alert addAction:scanNextAction];
            [alert addAction:registerAnywayAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
}

- (BOOL)isLicenseExpired:(NSString *)expiryDateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *expiryDate = [dateFormatter dateFromString:expiryDateString];
    NSDate *today = [NSDate date];
    return [expiryDate compare:today] == NSOrderedAscending;
}

- (void)handleExpiredLicense {
    // 在显示警告框前隐藏按钮
    self.cancelScanButton.hidden = YES;
    self.reminderLabel.hidden = YES;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"驾照过期"
                                                                   message:@"当前驾照已经过期，无法使用."
                                                            preferredStyle:UIAlertControllerStyleAlert];

    // Action to scan another license
    UIAlertAction *scanAction = [UIAlertAction actionWithTitle:@"扫描下一张"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * _Nonnull action) {
                                                           [self startScanning];
                                                       }];
    [alert addAction:scanAction];

    // Action to return to the main menu
    UIAlertAction *returnAction = [UIAlertAction actionWithTitle:@"返回主菜单"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             [self backToHome];
                                                         }];
    [alert addAction:returnAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)checkLicenseRegistration:(NSString *)licenseNumber withCompletion:(void (^)(BOOL isRegistered, NSArray *responseData))completion {
    // 将数据库操作移至后台线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 配置数据库连接
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
        OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory SELECT:dbName condition:[NSString stringWithFormat:@"license_number='%@'", licenseNumber]];
        
        // 执行查询
        NSError *error = nil;
        NSArray *response = [queryContext executeQueryRequestAndFetchResult:query error:&error];
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"获取信息失败" message:[NSString stringWithFormat:@"远程服务器无响应，请检查您的网络设置。"] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil];
                [alert addAction:okAction];
                [self presentViewController:alert animated:YES completion:nil];
            });
        } else {
            
            BOOL isRegistered = (response != nil && response.count > 0);
            
            // 断开数据库连接
            [coordinator disconnect];
            
            // 在主线程上执行回调
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(isRegistered, response);
            });
        }
    });
}

- (void)handleUnregisteredLicenseWithRoomNumber:(NSString *)roomNumber
                                     expiryDate:(NSString *)expiryDate
                                       lastName:(NSString *)lastName
                                      firstName:(NSString *)firstName
                                     middleName:(NSString *)middleName
                                    dateOfBirth:(NSString *)dateOfBirth
                                          gender:(NSString *)gender
                                         address:(NSString *)address
                                            city:(NSString *)city
                                           state:(NSString *)state
                                        zipCode:(NSString *)zipCode
                                  licenseNumber:(NSString *)licenseNumber {
    // 在显示警告框前隐藏按钮
    self.cancelScanButton.hidden = YES;
    self.reminderLabel.hidden = YES;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"驾照未注册"
                                                                   message:@"数据库无此驾照，是否进行注册？"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *registerAction = [UIAlertAction actionWithTitle:@"确认注册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 用户选择注册，展示 RegistrationViewController
        RegistrationViewController *registrationVC = [[RegistrationViewController alloc] init];
        registrationVC.roomNumber = roomNumber;
        registrationVC.expiryDate = expiryDate;
        registrationVC.lastName = lastName;
        registrationVC.firstName = firstName;
        registrationVC.middleName = middleName;
        registrationVC.dateOfBirth = dateOfBirth;
        registrationVC.gender = gender;
        registrationVC.address = address;
        registrationVC.city = city;
        registrationVC.state = state;
        registrationVC.zipCode = zipCode;
        registrationVC.licenseNumber = licenseNumber;
        registrationVC.databasePassword = self.databasePassword; // 传递密码
        registrationVC.databaseip = self.databaseip;
        registrationVC.databaseport = self.databaseport;
        registrationVC.databaseusername = self.databaseusername;
        registrationVC.databasedbName = self.databasedbName;
        registrationVC.isUpdateOperation = false;
        registrationVC.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:registrationVC animated:YES completion:nil];
    }];

    UIAlertAction *scanAction = [UIAlertAction actionWithTitle:@"取消并继续扫描" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 用户选择继续扫描，调用 startScanning 方法
        [self startScanning];
    }];
    
    UIAlertAction *homeAction = [UIAlertAction actionWithTitle:@"返回主菜单" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self backToHome];
        }];

    [alert addAction:registerAction];
    [alert addAction:scanAction];
    [alert addAction:homeAction];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handleRegisteredLicenseWithRoomNumber:(NSString *)roomNumber
                                   expiryDate:(NSString *)expiryDate
                                     lastName:(NSString *)lastName
                                    firstName:(NSString *)firstName
                                   middleName:(NSString *)middleName
                                  dateOfBirth:(NSString *)dateOfBirth
                                        gender:(NSString *)gender
                                       address:(NSString *)address
                                          city:(NSString *)city
                                         state:(NSString *)state
                                      zipCode:(NSString *)zipCode
                                licenseNumber:(NSString *)licenseNumber
                                 responseData:(NSArray *)responseData {
    // 在显示警告框前隐藏按钮
    self.cancelScanButton.hidden = YES;
    self.reminderLabel.hidden = YES;
    // 弹出对话框
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"驾照已注册"
                                                                   message:@"数据库中已有此驾照，是否更新数据？"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *updateAction = [UIAlertAction actionWithTitle:@"更新数据" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 更新数据
        RegistrationViewController *registrationVC = [[RegistrationViewController alloc] init];
        registrationVC.roomNumber = roomNumber;
        registrationVC.expiryDate = expiryDate;
        registrationVC.lastName = lastName;
        registrationVC.firstName = firstName;
        registrationVC.middleName = middleName;
        registrationVC.dateOfBirth = dateOfBirth;
        registrationVC.gender = gender;
        registrationVC.address = address;
        registrationVC.city = city;
        registrationVC.state = state;
        registrationVC.zipCode = zipCode;
        registrationVC.licenseNumber = licenseNumber;
        registrationVC.databasePassword = self.databasePassword; // 传递密码
        registrationVC.databaseip = self.databaseip;
        registrationVC.databaseport = self.databaseport;
        registrationVC.databaseusername = self.databaseusername;
        registrationVC.databasedbName = self.databasedbName;
        // 从响应中设置默认值
        NSDictionary *defaultValues = [responseData firstObject]; // 假设 responseData 是数组，其中包含一个字典
        registrationVC.defaultAptNumber = defaultValues[@"apt_number"];
        registrationVC.defaultElderlyCount = defaultValues[@"population_over_65"];
        registrationVC.defaultAdultCount = defaultValues[@"population_17_to_64"];
        registrationVC.defaultChildrenCount = defaultValues[@"population_under_17"];
        registrationVC.defaultPhoneNumber = defaultValues[@"phone_number"];
        registrationVC.defaultVeteran = defaultValues[@"veteran"];
        registrationVC.isUpdateOperation = YES;
        // ... 其他默认值的赋值 ...
        registrationVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [self presentViewController:registrationVC animated:YES completion:nil];
        }];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消并继续扫描" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // 用户选择继续扫描，调用 startScanning 方法
            [self startScanning];
        }];
    
        UIAlertAction *homeAction = [UIAlertAction actionWithTitle:@"返回主菜单" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self backToHome];
        }];

        [alert addAction:updateAction];
        [alert addAction:cancelAction];
        [alert addAction:homeAction];

        [self presentViewController:alert animated:YES completion:nil];
    }

- (NSString *)formatDate:(NSString *)rawDate {
    if (rawDate.length != 8) {
        return @"Invalid Date";
    }

    NSString *month = [rawDate substringToIndex:2];
    NSString *day = [rawDate substringWithRange:NSMakeRange(2, 2)];
    NSString *year = [rawDate substringFromIndex:4];

    return [NSString stringWithFormat:@"%@/%@/%@", month, day, year];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate method

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypePDF417Code]) {
            NSString *scannedText = [metadataObj stringValue];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self parseAndDisplayScannedData:scannedText];
            });
        }
    }
}

- (void)backToScan {
    self.scannedTextTextView.hidden = YES;
    self.scanFrameView.hidden = NO;
    self.scanLineLayer.hidden = NO;
    self.backButton.hidden = YES;
    self.homeButton.hidden = YES;

    [self startScanning];
}

- (void)backToHome {

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

