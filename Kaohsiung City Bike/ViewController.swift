//
//  ViewController.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2015/10/28.
//  Copyright © 2015年 Yang Tun-Kai. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate,UISearchBarDelegate,UISearchControllerDelegate{

    @IBOutlet var mapView:MKMapView!
    
    
    let locationManager = CLLocationManager();
    var transportType = MKDirectionsTransportType.Walking //以步行方式導航
    var currentLocation: CLLocationCoordinate2D!
    var searchController: UISearchController!
    var leftBarButton: UIBarButtonItem!
    var rightBarButton: UIBarButtonItem!
    let bikePlace = DataGet()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureSearchBar()
        
        
        
        leftBarButton = navigationItem.leftBarButtonItem
        rightBarButton = navigationItem.rightBarButtonItem

        locationManager.requestWhenInUseAuthorization()//確認地理位置請求
        let status = CLLocationManager.authorizationStatus()

        if(status == CLAuthorizationStatus.AuthorizedWhenInUse){
            mapView.showsUserLocation = true;
        }
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.startUpdatingLocation()
        locationManager.distanceFilter = CLLocationDistance(50)
        
        
        let stationData = DataGet().bikeLocationJson()//抓腳踏車站點位置
        
        for element in stationData{//將位置作成annotation
            let annotation = MKPointAnnotation()
            annotation.title = element["StationName"] as? String
            annotation.coordinate = CLLocationCoordinate2D(latitude: (element["StationLat"] as! NSString).doubleValue as CLLocationDegrees , longitude: (element["StationLon"] as! NSString).doubleValue as CLLocationDegrees)
            mapView.showAnnotations([annotation], animated: true)
        }
    }
    
    func configureSearchBar(){
        //將UISearchBar放到Navigation的titleView上
        searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = true
        searchController.searchBar.autocapitalizationType = UITextAutocapitalizationType.None
        searchController.searchBar.keyboardType = UIKeyboardType.Default
        navigationItem.titleView = searchController.searchBar
        definesPresentationContext = true
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        navigationItem.leftBarButtonItem = leftBarButton
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude , longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003))
        mapView.setRegion(region, animated: false)
        currentLocation = center
    
    }
    
    override func viewDidDisappear(animated: Bool) {
        //畫面消失時停止更新位置（節省電量）
        locationManager.stopUpdatingLocation()
    }
    override func viewWillAppear(animated: Bool) {
        //畫面將要出現時啟動更新位置
        locationManager.startUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func locateMe(sender: AnyObject) {
        //定位按鈕function實作
        mapView.showsUserLocation = true
        mapView.delegate = self
        let region = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003))
        mapView.setRegion(region, animated: true)

    }

}

