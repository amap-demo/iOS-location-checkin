//
//  ViewController.swift
//  CheckinDemo-swift
//
//  Created by eidan on 2017/3/30.
//  Copyright © 2017年 Amap. All rights reserved.
//

import UIKit

class ViewController: UIViewController ,AMapLocationManagerDelegate, MAMapViewDelegate, AMapSearchDelegate, UITableViewDelegate, UITableViewDataSource{
    
    let AMAPLOC_DEG_TO_RAD = 0.0174532925199432958
    let AMAPLOC_EARTH_RADIUS = 6378137.0
    
    let POITableViewCellIdentifier = "POITableViewCellIdentifier"
    
    var locationManager: AMapLocationManager!   //定位
    var search: AMapSearchAPI!                  //地图内的搜索API类
    @IBOutlet weak var mapView: MAMapView!      //地图
    
    //data
    var currentGPSCoordinate: CLLocationCoordinate2D?
    var POIDataArray = [AMapPOI]()
    var selectedIndex = -1
    
    //xib views
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startUpdateLocationBtn: UIButton!
    @IBOutlet weak var checkinBtn: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //定位
        self.locationManager = AMapLocationManager.init()
        self.locationManager.delegate = self
        
        //Search
        self.search = AMapSearchAPI.init()
        self.search.delegate = self
        
        //map
        self.mapView.delegate = self
        self.mapView.showsUserLocation = false
        self.mapView.isRotateCameraEnabled = false
        self.mapView.isRotateEnabled = false
        
        self.tableView.register(UINib.init(nibName: "POITableViewCellSwift", bundle: nil), forCellReuseIdentifier: POITableViewCellIdentifier)
        let view: UIView = UIView.init()
        view.backgroundColor = UIColor.clear
        self.tableView.tableFooterView = view
        
        //搜索POI
        self.resetViewAndData()
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    // MARK: - Private Action
    
    //重设界面和数据
    func resetViewAndData() {
        self.loadingView.isHidden = true
        self.currentGPSCoordinate = kCLLocationCoordinate2DInvalid
        self.selectedIndex = -1
        self.POIDataArray =  [AMapPOI]()
        self.tableView.reloadData()
    }
    
    //开始定位
    func startLocation() {
        self.mapView.removeOverlays(self.mapView.overlays)
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        self.loadingView.isHidden = false
        self.startUpdateLocationBtn.isEnabled = false
        self.checkinBtn.isEnabled = false
        
        self.locationManager.requestLocation(withReGeocode: false) { [weak self] (location: CLLocation?, regeocode: AMapLocationReGeocode?, error: Error?) in
            
            self?.loadingView.isHidden = true
            self?.startUpdateLocationBtn.isEnabled = true
            self?.checkinBtn.isEnabled = true
            
            if let error = error {
                
                let error = error as NSError
                print("locError:{\(error.code) - \(error.localizedDescription)};")
                
                return
            }
            
            self?.currentGPSCoordinate = location?.coordinate
            
            //添加定位点的大头针
            let annotation: MAPointAnnotation = MAPointAnnotation.init()
            annotation.coordinate = (location?.coordinate)!
            self?.mapView.addAnnotation(annotation)
            annotation.isLockedToScreen = true
            annotation.lockedScreenPoint = CGPoint.init(x: (self?.mapView.bounds.size.width)! / 2, y: (self?.mapView.bounds.size.height)! / 2)
            
            //添加500米的范围圈
            let circleOverlay: MACircle = MACircle.init(center: (location?.coordinate)!, radius: 500)
            self?.mapView.add(circleOverlay)
            
            //设置地图
            self?.mapView.setZoomLevel(15.5, animated: true)
            self?.mapView.selectAnnotation(annotation, animated: true)
            self?.mapView.centerCoordinate = (location?.coordinate)!
            
            self?.searchAllPOIAround(coordinate: (location?.coordinate)!)
            
        }
        
    }
    
    //搜索周边POI
    func searchAllPOIAround(coordinate: CLLocationCoordinate2D) {
        let request: AMapPOIAroundSearchRequest = AMapPOIAroundSearchRequest.init()
        request.sortrule = 0
        request.offset = 50
        request.location = AMapGeoPoint.location(withLatitude: CGFloat(coordinate.latitude), longitude: CGFloat(coordinate.longitude))
        request.radius = 500
        self.search.aMapPOIAroundSearch(request)
    }
    
    //计算两点之间的距离
    func distanceBetweenCoordinates(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        
        let latitudeArc  = (from.latitude - to.latitude) * AMAPLOC_DEG_TO_RAD;
        let longitudeArc = (from.longitude - to.longitude) * AMAPLOC_DEG_TO_RAD;
        
        var latitudeH = sin(latitudeArc * 0.5);
        latitudeH *= latitudeH;
        var lontitudeH = sin(longitudeArc * 0.5);
        lontitudeH *= lontitudeH;
        
        let tmp = cos(from.latitude * AMAPLOC_DEG_TO_RAD) * cos(to.latitude * AMAPLOC_DEG_TO_RAD);
        return AMAPLOC_EARTH_RADIUS * 2.0 * asin(sqrt(latitudeH + tmp * lontitudeH));
    }
    
    // MARK: - xib btn click
    
    //开始定位
    @IBAction func startUpdateLocation(_ sender: Any) {
        self.resetViewAndData()
        self.startLocation()
    }
    
    //签到
    @IBAction func checkin(_ sender: UIButton) {
        if CLLocationCoordinate2DIsValid(self.currentGPSCoordinate!) {
            self.mapView.setZoomLevel(19.0, animated: true)
            let alertView: UIAlertView = UIAlertView.init(title: "签到成功", message: nil, delegate: nil, cancelButtonTitle: "确定")
            alertView.show()
        } else {
            let alertView: UIAlertView = UIAlertView.init(title: "位置在火星？~~签到失败", message: nil, delegate: nil, cancelButtonTitle: "确定")
            alertView.show()
        }
    }
    
    // MARK: - UITableView Delegate and DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.POIDataArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 62
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: POITableViewCellSwift = tableView.dequeueReusableCell(withIdentifier: POITableViewCellIdentifier, for: indexPath) as! POITableViewCellSwift
        
        let POI: AMapPOI = self.POIDataArray[indexPath.row];
        
        cell.nameLabel.text = POI.name
        cell.infoLabel.text = POI.address
        cell.selectedImageView.isHidden = indexPath.row == self.selectedIndex ? false : true;
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.selectedIndex = indexPath.row
        self.tableView.reloadData()
        
        let POI: AMapPOI = self.POIDataArray[indexPath.row]
        self.mapView.setCenter(CLLocationCoordinate2DMake(CLLocationDegrees(POI.location.latitude), CLLocationDegrees(POI.location.longitude)), animated: true)
        self.mapView.setZoomLevel(19.0, animated: true)
    }
    
    // MARK: - AMapLocationManagerDelegate
    
    func amapLocationManager(_ manager: AMapLocationManager!, doRequireLocationAuth locationManager: CLLocationManager!) {
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: - AMapSearchDelegate
    
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        self.POIDataArray = response.pois
        self.tableView.reloadData()
    }
    
    // MARK: - MapViewDelegate
    //  地图移动结束后调用此接口 wasUserAction 标识是否是用户动作
    func mapView(_ mapView: MAMapView!, mapDidMoveByUser wasUserAction: Bool) {
        if wasUserAction == false {
            return;
        }
        
        if CLLocationCoordinate2DIsValid(self.currentGPSCoordinate!) == false {
            return
        }
        
        let dis = self.distanceBetweenCoordinates(from: mapView.centerCoordinate, to: self.currentGPSCoordinate!)
        
        if dis > 500 {
            self.mapView.setZoomLevel(15.5, animated: true)
            self.mapView.setCenter(self.currentGPSCoordinate!, animated: true)
            let alertView: UIAlertView = UIAlertView.init(title: "调整距离不可超过500米", message: nil, delegate: nil, cancelButtonTitle: "确定")
            alertView.show()
        }
        
    }
    
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        
        if annotation is MAPointAnnotation {
            
            let pointReuseIndetifier: String = "pointReuseIndetifier"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier) as? MAPinAnnotationView
            
            if annotationView == nil {
                annotationView = MAPinAnnotationView.init(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
                
                annotationView?.canShowCallout = false
                annotationView?.isDraggable = false
                annotationView?.animatesDrop = false
            }
            
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        
        if overlay.isKind(of: MACircle.self) {
            let circleRenderer: MACircleRenderer = MACircleRenderer(circle: overlay as! MACircle!)
            circleRenderer.lineWidth = 2
            circleRenderer.strokeColor = UIColor.orange
            circleRenderer.fillColor = UIColor.clear
            return circleRenderer
        }
        return nil
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

