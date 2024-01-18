//
//  PickupRegistrationViewController.m
//  tzuchi
//
//  Created by TIANFANG XIE on 1/17/24.
//

#import "PickupRegistrationViewController.h"
#import <OHMySQL/OHMySQL.h>

@implementation PickupRegistrationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor]; // 设置初始背景色
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
    } else {
        [self checkLicenseRegistration:licenseNumber];
        
    }
}

- (BOOL) isLicenseExpired:(NSString *)expiryDateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *expiryDate = [dateFormatter dateFromString:expiryDateString];
    NSDate *today = [NSDate date];
    return [expiryDate compare:today] == NSOrderedAscending;
}

- (void)handleExpiredLicense {
    // 在显示警告框前隐藏按钮
    self.cancelScanButton.hidden = YES;
    
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

- (void)checkLicenseRegistration:(NSString *)licenseNumber  {
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
        OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory SELECT:@"tzuchi" condition:[NSString stringWithFormat:@"license_number='%@'", licenseNumber]];
        
        // 执行查询
        NSError *error = nil;
        NSArray *response = [queryContext executeQueryRequestAndFetchResult:query error:&error];
        
        BOOL isRegistered = (response != nil && response.count > 0);
        
        // 断开数据库连接
        [coordinator disconnect];
        
        // 在主线程上执行回调
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!isRegistered) {
                [self showUnregisteredLicenseAlert];
            } else {
                // 驾照号码已在数据库中注册
                NSDictionary *licenseData = [response firstObject];
                NSString *lastTime = licenseData[@"last_time"]; // 假设字段名为 last_time
                if (![self isDate:lastTime equalToDate:[self currentDate]] || [lastTime isEqualToString:@"00000000"]) {
                    // 如果日期不等于今天或“00000000”，更新数据库并显示成功取菜
                    // 在显示警告框前隐藏按钮
                    self.cancelScanButton.hidden = YES;
                    [self updateLastTimeForLicense:licenseNumber];
                } else {
                    // 如果日期不是今天，显示已取菜的警告
                    // 在显示警告框前隐藏按钮
                    self.cancelScanButton.hidden = YES;
                    [self showAlertWithTitleRed:@"!!!!! 警告 !!!!!" message:@"!!! 本驾照今日已经取菜 !!!"];
                }
                }
            });
    });
}

- (void)showUnregisteredLicenseAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"驾照未注册"
                                                                   message:@"本驾照尚未注册"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *registerAction = [UIAlertAction actionWithTitle:@"返回注册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self backToHome];
    }];
    UIAlertAction *scanNextAction = [UIAlertAction actionWithTitle:@"扫描下一张" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self startScanning];
    }];
    [alert addAction:registerAction];
    [alert addAction:scanNextAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateLastTimeForLicense:(NSString *)licenseNumber {
    NSString *todayString = [self currentDate];
    NSDictionary *dataToInsert = @{
        @"last_time": todayString
    };
    // 执行后台线程数据库写入操
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
        
        OHMySQLQueryRequest *query = [OHMySQLQueryRequestFactory UPDATE:@"tzuchi" set:dataToInsert condition:[NSString stringWithFormat:@"license_number='%@'", licenseNumber]];
        // 执行查询
        [queryContext executeQueryRequest:query error:&error];
        
        // 断开数据库连接
        [coordinator disconnect];
        
        // 当数据库操作完成后，如果需要更新UI，回到主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            // 这里写任何需要在主线程执行的代码，比如关闭视图控制器
            if (!error) {
                [self showAlertWithTitle:@"取菜成功" message:@"谢谢"];
            } else {
                [self showAlertWithTitleRed:@"数据库连接失败" message:@"请重试"];
            }
            
        });
    });
}


- (NSString *)currentDate {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMddyyyy"];
    return [dateFormatter stringFromDate:[NSDate date]];
}

- (BOOL)isDate:(NSString *)dateString equalToDate:(NSString *)otherDateString {
    return [dateString isEqualToString:otherDateString];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    // 添加返回主菜单按钮
    UIAlertAction *returnToHomeAction = [UIAlertAction actionWithTitle:@"返回主菜单"
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * _Nonnull action) {
                                                                   [self backToHome];
                                                               }];
    [alert addAction:returnToHomeAction];

    // 添加继续扫描按钮
    UIAlertAction *continueScanningAction = [UIAlertAction actionWithTitle:@"继续扫描"
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * _Nonnull action) {
                                                                       [self startScanning];
                                                                   }];
    [alert addAction:continueScanningAction];

    // 显示对话框
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAlertWithTitleRed:(NSString *)title message:(NSString *)message {

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];

        // 添加返回主菜单按钮
        UIAlertAction *returnToHomeAction = [UIAlertAction actionWithTitle:@"无法取菜，返回主菜单"
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * _Nonnull action) {
                                                                       [self backToHome];
                                                                   }];
        [alert addAction:returnToHomeAction];


        // 显示对话框
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
