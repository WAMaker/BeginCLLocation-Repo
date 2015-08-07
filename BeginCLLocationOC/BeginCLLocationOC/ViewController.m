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

#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self

static NSTimeInterval const kTimeDelay = 2.5;

@interface ViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView   *mapView;
@property (weak, nonatomic) IBOutlet UILabel     *resultLabel;
@property (weak, nonatomic) IBOutlet UITextField *addressField;
@property (weak, nonatomic) IBOutlet UITextField *latitudeField;
@property (weak, nonatomic) IBOutlet UITextField *longitudeField;

@property (strong, nonatomic) MBProgressHUD      *hud;
@property (strong, nonatomic) CLLocationManager  *locMgr;
@property (strong, nonatomic) CLGeocoder         *geocoder;

- (IBAction)startLocating;
- (IBAction)geocode;
- (IBAction)reverseGeocode;

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

- (CLGeocoder *)geocoder {
    if (!_geocoder) {
        _geocoder = [[CLGeocoder alloc] init];
    }
    return _geocoder;
}

- (MKMapView *)mapView {
    if (!_mapView) {
        MKMapView *mapView = [[MKMapView alloc] init];
        _mapView = mapView;
        
        _mapView.delegate = self;
    }
    
    return _mapView;
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 添加背景点击事件
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped)];
    recognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:recognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - IBAction

- (IBAction)startLocating {
    [self keyboardResign];
    [self locationAuthorizationJudge];
}

/**
 *  地理编码
 */
- (IBAction)geocode {
    [self keyboardResign];
    
    if (self.addressField.text.length == 0) {
        [self showCommonTip:@"请填写地址"];
        return;
    }
    
    [self showProcessHud:@"正在获取位置信息"];
    
    WS(weakSelf);
    [self.geocoder geocodeAddressString:self.addressField.text completionHandler:^(NSArray *placemarks, NSError *error) {
        [weakSelf.hud hide:YES];
        
        if (error) {
            [weakSelf showCommonTip:@"地理编码出错，或许你选的地方在冥王星"];
            NSLog(@"%@", error);
            return;
        }
        
        CLPlacemark *placemark = [placemarks firstObject];
        NSString *formatString = [NSString stringWithFormat:@"经度：%lf，纬度：%lf\n%@ %@ %@\n%@\n%@ %@", placemark.location.coordinate.latitude, placemark.location.coordinate.longitude, placemark.addressDictionary[@"City"], placemark.addressDictionary[@"Country"], placemark.addressDictionary[@"CountryCode"], [placemark.addressDictionary[@"FormattedAddressLines"] firstObject], placemark.addressDictionary[@"Name"], placemark.addressDictionary[@"State"]];
        weakSelf.resultLabel.text = formatString;
        [weakSelf showInMapWithCoordinate:CLLocationCoordinate2DMake(placemark.location.coordinate.latitude, placemark.location.coordinate.longitude)];
        
        for (CLPlacemark *pm in placemarks) {
            NSLog(@"经度：%lf，纬度：%lf\n%@ %@ %@\n%@\n%@ %@", pm.location.coordinate.latitude, pm.location.coordinate.longitude, pm.addressDictionary[@"City"], pm.addressDictionary[@"Country"], pm.addressDictionary[@"CountryCode"], [pm.addressDictionary[@"FormattedAddressLines"] firstObject], pm.addressDictionary[@"Name"], pm.addressDictionary[@"State"]);
        }
    }];
}

/**
 *  反地理编码
 */
- (IBAction)reverseGeocode {
    [self keyboardResign];
    
    if (self.latitudeField.text.length == 0 || self.longitudeField.text.length == 0) {
        [self showCommonTip:@"请填写经纬度"];
        return;
    }
    
    [self showProcessHud:@"正在获取位置信息"];
    
    CLLocationDegrees latitude = [self.latitudeField.text doubleValue];
    CLLocationDegrees longitude = [self.longitudeField.text doubleValue];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    
    WS(weakSelf);
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        [weakSelf.hud hide:YES];
        
        if (error) {
            [weakSelf showCommonTip:@"地理编码出错，或许你选的地方在冥王星"];
            NSLog(@"%@", error);
            return;
        }
        
        CLPlacemark *placemark = [placemarks firstObject];
        NSString *formatString = [NSString stringWithFormat:@"经度：%lf，纬度：%lf\n%@ %@ %@\n%@\n%@ %@", placemark.location.coordinate.latitude, placemark.location.coordinate.longitude, placemark.addressDictionary[@"City"], placemark.addressDictionary[@"Country"], placemark.addressDictionary[@"CountryCode"], [placemark.addressDictionary[@"FormattedAddressLines"] firstObject], placemark.addressDictionary[@"Name"], placemark.addressDictionary[@"State"]];
        weakSelf.resultLabel.text = formatString;
        [weakSelf showInMapWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
        
        for (CLPlacemark *pm in placemarks) {
            NSLog(@"经度：%lf，纬度：%lf\n%@ %@ %@\n%@\n%@ %@", pm.location.coordinate.latitude, pm.location.coordinate.longitude, pm.addressDictionary[@"City"], pm.addressDictionary[@"Country"], pm.addressDictionary[@"CountryCode"], [pm.addressDictionary[@"FormattedAddressLines"] firstObject], pm.addressDictionary[@"Name"], pm.addressDictionary[@"State"]);
        }
    }];
}

#pragma mark - Private

- (void)showCommonTip:(NSString *)tip {
    self.hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.hud.mode = MBProgressHUDModeText;
    self.hud.labelText = tip;
    self.hud.removeFromSuperViewOnHide = YES;
    [self.hud hide:YES afterDelay:kTimeDelay];
}

- (void)showProcessHud:(NSString *)msg {
    self.hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view  addSubview:self.hud];
    self.hud.removeFromSuperViewOnHide = YES;
    self.hud.mode = MBProgressHUDModeIndeterminate;
    self.hud.labelText = msg;
    [self.hud show:NO];
}

/**
 *  点击空白处收起键盘
 */
- (void)backgroundTapped {
    [self keyboardResign];
}

- (void)keyboardResign {
    [self.view endEditing:YES];
}

/**
 *  判断定位授权
 */
- (void)locationAuthorizationJudge {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    NSString *locationServicesEnabled = [CLLocationManager locationServicesEnabled] ? @"YES" : @"NO";
    NSLog(@"location services enabled = %@", locationServicesEnabled);
    
    if (status == kCLAuthorizationStatusDenied) { // 如果授权状态是拒绝就给用户提示
        [self showCommonTip:@"请前往设置-隐私-定位中打开定位服务"];
    } else if (status == kCLAuthorizationStatusNotDetermined) { // 如果授权状态还没有被决定就弹出提示框
        if ([self.locMgr respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self.locMgr requestWhenInUseAuthorization];
//            [self.locMgr requestAlwaysAuthorization];
        }
        
        // 也可以判断当前系统版本是否大于8.0
//        if ([[UIDevice currentDevice].systemVersion doubleValue] >= 8.0) {
//            [self.locMgr requestWhenInUseAuthorization];
//        }
    } else if (status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways) { // 如果授权状态可以使用就开始获取用户位置
        [self.locMgr startUpdatingLocation];
    }
}

/**
 *  计算两个坐标之间的直线距离;
 */
- (void)calculateStraightDistance {
    CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:30 longitude:123];
    CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:31 longitude:124];
    CLLocationDistance distances = [loc1 distanceFromLocation:loc2];
    NSLog(@"两点之间的直线距离是%lf", distances);
}

/**
 *  将位置信息显示到mapView上
 */
- (void)showInMapWithCoordinate:(CLLocationCoordinate2D)coordinate {
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, MKCoordinateSpanMake(0.025, 0.025));
    [self.mapView setRegion:region animated:YES];
    
    [self addAnnotation:coordinate];
}

/**
 *  添加大头针
 */
- (void)addAnnotation:(CLLocationCoordinate2D)coordinate {
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.title = @"here";
    annotation.coordinate = coordinate;
    [self.mapView addAnnotation:annotation];
}

#pragma mark - CLLocationManagerDelegate

/**
 *  只要定位到位置，就会调用，调用频率频繁
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    NSLog(@"我的位置是 - %@", location);
    [self showInMapWithCoordinate:location.coordinate];
    // 根据不同需要停止更新位置
    [self.locMgr stopUpdatingLocation];
}

@end
