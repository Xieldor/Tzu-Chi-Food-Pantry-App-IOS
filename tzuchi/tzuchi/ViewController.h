//
//  ViewController.h
//  tzuchi
//
//  Created by TIANFANG XIE on 1/15/24.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) NSDate *lastLoginAttemptDate;
@property (nonatomic, assign) NSInteger loginAttemptCount;

@end

