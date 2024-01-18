//
//  RegistrationViewController.h
//  tzuchi
//
//  Created by TIANFANG XIE on 1/16/24.
//

#import <UIKit/UIKit.h>

@interface RegistrationViewController : UIViewController

@property (strong, nonatomic) NSString *roomNumber;
@property (strong, nonatomic) NSString *expiryDate;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *middleName;
@property (strong, nonatomic) NSString *dateOfBirth;
@property (strong, nonatomic) NSString *gender;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) NSString *city;
@property (strong, nonatomic) NSString *state;
@property (strong, nonatomic) NSString *zipCode;
@property (strong, nonatomic) NSString *licenseNumber;
@property (strong, nonatomic) NSString *databasePassword;
@property (strong, nonatomic) NSString *databaseip;
@property (strong, nonatomic) NSString *databaseport;
@property (strong, nonatomic) NSString *databaseusername;
@property (strong, nonatomic) NSString *databasedbName;
@property (strong, nonatomic) NSString *defaultAptNumber;
@property (strong, nonatomic) NSString *defaultElderlyCount;
@property (strong, nonatomic) NSString *defaultAdultCount;
@property (strong, nonatomic) NSString *defaultChildrenCount;
@property (strong, nonatomic) NSString *defaultPhoneNumber;
@property (strong, nonatomic) NSString *defaultVeteran;
@property (nonatomic, assign) BOOL isUpdateOperation;

@end
