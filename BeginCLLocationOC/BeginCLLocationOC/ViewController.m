//
//  ViewController.m
//  BeginCLLocationOC
//
//  Created by wamaker on 15/8/5.
//  Copyright (c) 2015年 wamaker. All rights reserved.
//

#import "ViewController.h"

#import "MBProgressHUD.h"

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

static NSTimeInterval const kTimeDelay = 2.5;

@interface ViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (strong, nonatomic) CLLocationManager *locMgr;
@property (strong, nonatomic) MBProgressHUD     *hud;

- (IBAction)startLocating;

@end

@implementation ViewController

- (CLLocationManager *)locMgr {
    if (!_locMgr) {
        _locMgr = [[CLLocationManager alloc] init];
        _locMgr.delegate = self;
        
        // 定位精度
        _locMgr.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        // 距离过滤器，当移动距离小于这个值时不会收到回调
//        _locMgr.distanceFilter = 50;
    }
    return _locMgr;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - IBAction

- (IBAction)startLocating {
    [self locationAuthorizationJudge];
}

#pragma mark - Private

- (void)showCommonTip:(NSString *)tip {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode = MBProgressHUDModeText;
    self.hud.labelText = tip;
    self.hud.removeFromSuperViewOnHide = YES;
    [self.hud hide:YES afterDelay:kTimeDelay];
}

/**
 *  判断定位授权
 */
- (void)locationAuthorizationJudge {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    NSString *locationServicesEnabled = [CLLocationManager locationServicesEnabled] ? @"YES" : @"NO";
    NSLog(@"location services enabled = %@", locationServicesEnabled);
    
    if (status == kCLAuthorizationStatusDenied) {
        [self showCommonTip:@"请前往设置-隐私-定位中打开定位服务"];
    } else if (status == kCLAuthorizationStatusNotDetermined) {
        if ([self.locMgr respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locMgr requestWhenInUseAuthorization];
//            [self.locMgr requestAlwaysAuthorization];
        }
        
        // 也可以判断当前系统版本是否大于8.0
//        if ([[UIDevice currentDevice].systemVersion doubleValue] >= 8.0) {
//            [self.locMgr requestWhenInUseAuthorization];
//        }
    } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locMgr startUpdatingLocation];
    }
}

#pragma mark - CLLocationManagerDelegate

/**
 *  只要定位到位置，就会调用，调用频率频繁
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"%@", locations);
    [self.locMgr stopUpdatingLocation];
}

#pragma mark - MKMapViewDelegate

@end
