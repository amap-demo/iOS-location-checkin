//
//  ViewController.m
//  CheckinDemo
//
//  Created by eidan on 2017/3/29.
//  Copyright © 2017年 Amap. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import "POITableViewCell.h"

#define AMAPLOC_DEG_TO_RAD      0.0174532925199432958f //0.017453292519943295769236907684886
#define AMAPLOC_EARTH_RADIUS    6378137.0f

@interface ViewController () <AMapLocationManagerDelegate, MAMapViewDelegate, AMapSearchDelegate>

@property (nonatomic, strong) AMapLocationManager *locationManager;
@property (nonatomic, strong) AMapSearchAPI *search;
@property (nonatomic, weak) IBOutlet MAMapView *mapView;

//data
@property (nonatomic, assign) CLLocationCoordinate2D currentGPSCoordinate;
@property (nonatomic, copy) NSArray<AMapPOI *> *POIDataArray;
@property (nonatomic, assign) int selectedIndex;

//xib views
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loadingView;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UIButton *startUpdateLocationBtn;
@property (nonatomic, weak) IBOutlet UIButton *checkinBtn;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //定位
    self.locationManager = [[AMapLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    //搜索
    self.search = [[AMapSearchAPI alloc] init];
    self.search.delegate = self;

    //地图
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = NO;
    self.mapView.rotateCameraEnabled = NO;
    self.mapView.rotateEnabled = NO;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"POITableViewCell" bundle:nil] forCellReuseIdentifier:POITableViewCellIdentifier];
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:view];
    
    [self resetViewAndData];
    
}

#pragma mark - Private Action

//重设界面和数据
- (void)resetViewAndData {
    self.loadingView.hidden = YES;
    self.currentGPSCoordinate = kCLLocationCoordinate2DInvalid;  //一开始要设置为非法值，等定位成功才设置有效值
    self.selectedIndex = -1;
    self.POIDataArray = nil;
    [self.tableView reloadData];
}

//开始定位
- (void)startLocation {
    
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    self.loadingView.hidden = NO;
    self.startUpdateLocationBtn.enabled = self.checkinBtn.enabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [self.locationManager requestLocationWithReGeocode:NO completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        
        weakSelf.loadingView.hidden = YES;
        weakSelf.startUpdateLocationBtn.enabled = weakSelf.checkinBtn.enabled = YES;
        
        if (error) {
            NSLog(@"定位错误:{%ld - %@};", (long)error.code, error.localizedDescription);
            return;
        }
        
        weakSelf.currentGPSCoordinate = location.coordinate;
        
        //添加定位点的大头针
        MAPointAnnotation *annotation = [[MAPointAnnotation alloc] init];
        annotation.coordinate = location.coordinate;
        [weakSelf.mapView addAnnotation:annotation];
        annotation.lockedToScreen = YES;
        annotation.lockedScreenPoint = CGPointMake(weakSelf.mapView.bounds.size.width / 2, weakSelf.mapView.bounds.size.height / 2) ;
        
        //添加500米的范围圈
        MACircle *circleOverlay = [MACircle circleWithCenterCoordinate:location.coordinate radius:500];
        [weakSelf.mapView addOverlay:circleOverlay];
        
        //设置地图
        [weakSelf.mapView setZoomLevel:15.5 animated:YES];
        [weakSelf.mapView selectAnnotation:annotation animated:YES];
        [weakSelf.mapView setCenterCoordinate:location.coordinate animated:NO];
        
        //搜索POI
        [weakSelf searchAllPOIAround:location.coordinate];
    }];
}

//搜索周边POI
- (void)searchAllPOIAround:(CLLocationCoordinate2D)coordinate {
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    request.sortrule = 0;
    request.offset = 50;
    request.location = [AMapGeoPoint locationWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    request.radius = 500;
    [self.search AMapPOIAroundSearch:request];
}

//计算两点之间的距离
- (double)distanceBetweenCoordinates:(CLLocationCoordinate2D )from and:(CLLocationCoordinate2D)to {
    
    double latitudeArc  = (from.latitude - to.latitude) * AMAPLOC_DEG_TO_RAD;
    double longitudeArc = (from.longitude - to.longitude) * AMAPLOC_DEG_TO_RAD;
    
    double latitudeH = sin(latitudeArc * 0.5);
    latitudeH *= latitudeH;
    double lontitudeH = sin(longitudeArc * 0.5);
    lontitudeH *= lontitudeH;
    
    double tmp = cos(from.latitude*AMAPLOC_DEG_TO_RAD) * cos(to.latitude*AMAPLOC_DEG_TO_RAD);
    return AMAPLOC_EARTH_RADIUS * 2.0 * asin(sqrt(latitudeH + tmp*lontitudeH));
}

#pragma mark - xib click

//开始定位
- (IBAction)startUpdateLocation:(id)sender {
    [self resetViewAndData];
    [self startLocation];
}

//签到
- (IBAction)checkin:(id)sender {
    if (CLLocationCoordinate2DIsValid(self.currentGPSCoordinate)) {  //定位成功了，就可以签到
        [self.mapView setZoomLevel:19 animated:YES];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"签到成功" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"位置在火星？~~签到失败" message:nil delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

#pragma -mark UITableView Delegate and DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.POIDataArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 62;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    POITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:POITableViewCellIdentifier forIndexPath:indexPath];
    cell.accessibilityIdentifier = [NSString stringWithFormat:@"POITableViewCell_%ld",(long)indexPath.row];  //for UITest
    
    AMapPOI *POI = self.POIDataArray[indexPath.row];
    
    cell.nameLabel.text = POI.name;
    cell.infoLabel.text = POI.address;
    cell.selectedImageView.hidden = indexPath.row == self.selectedIndex ? NO : YES;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    self.selectedIndex = (int)indexPath.row;
    [self.tableView reloadData];
    
    AMapPOI *POI = self.POIDataArray[indexPath.row];
    [self.mapView setCenterCoordinate:CLLocationCoordinate2DMake(POI.location.latitude, POI.location.longitude) animated:YES];
    [self.mapView setZoomLevel:19 animated:YES];
}

#pragma mark - AMapLocationManagerDelegate

- (void)amapLocationManager:(AMapLocationManager *)manager doRequireLocationAuth:(CLLocationManager*)locationManager {
    [locationManager requestAlwaysAuthorization];
}

#pragma mark - AMapSearchDelegate

- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response{
    self.POIDataArray = response.pois;
    [self.tableView reloadData];
}

#pragma mark - MAMapViewDelegate

- (void)mapViewRequireLocationAuth:(CLLocationManager *)locationManager {
    [locationManager requestAlwaysAuthorization];
}

- (void)mapView:(MAMapView *)mapView mapDidMoveByUser:(BOOL)wasUserAction {
    if (!wasUserAction) {
        return;
    }
    if (!CLLocationCoordinate2DIsValid(self.currentGPSCoordinate)) {  //非法的时候需返回
        return;
    }
    double dis = [self distanceBetweenCoordinates:mapView.centerCoordinate and:self.currentGPSCoordinate];
    if (dis > 500 ) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"调整距离不可超过500米" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self.mapView setZoomLevel:15.5 animated:YES];
    [self.mapView setCenterCoordinate:self.currentGPSCoordinate animated:YES];
}



- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation {
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *pointReuseIndetifier = @"pointReuseIndetifier";
        
        MAPinAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndetifier];
        if (annotationView == nil) {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndetifier];
        }
        
        annotationView.canShowCallout = NO;
        annotationView.animatesDrop = NO;
        annotationView.draggable = NO;
        
        return annotationView;
    }
    
    return nil;
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id <MAOverlay>)overlay {
    
    if ([overlay isKindOfClass:[MACircle class]]) {
        MACircleRenderer *circleRenderer = [[MACircleRenderer alloc] initWithCircle:overlay];
        circleRenderer.lineWidth = 2.0f;
        circleRenderer.strokeColor = [UIColor orangeColor];
        circleRenderer.fillColor = [UIColor clearColor];
        
        return circleRenderer;
    }
    
    return nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
