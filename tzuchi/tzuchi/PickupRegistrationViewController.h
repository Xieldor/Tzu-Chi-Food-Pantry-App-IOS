//
//  PickupRegistrationViewController.h
//  tzuchi
//
//  Created by TIANFANG XIE on 1/17/24.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PickupRegistrationViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>

// 数据库连接属性（如果需要）
@property (strong, nonatomic) NSString *databasePassword;
@property (strong, nonatomic) NSString *databaseip;
@property (strong, nonatomic) NSString *databaseport;
@property (strong, nonatomic) NSString *databaseusername;
@property (strong, nonatomic) NSString *databasedbName;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (strong, nonatomic) UIView *backgroundMaskView;
@property (strong, nonatomic) UIView *scanFrameView;
@property (strong, nonatomic) CALayer *scanLineLayer;
@property (strong, nonatomic) UITextView *scannedTextTextView;
@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) UIButton *homeButton;
@property (strong, nonatomic) UIButton *cancelScanButton;
@property (strong, nonatomic) UILabel *reminderLabel;

@end
