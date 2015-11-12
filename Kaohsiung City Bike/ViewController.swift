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
    @IBOutlet var travelTimeLabel: UILabel!
    @IBOutlet var infoView: UIView!
    
    
    let locationManager = CLLocationManager();
    var transportType = MKDirectionsTransportType.Walking //以步行方式導航
    var currentLocation: CLLocationCoordinate2D!
    var searchController: UISearchController!
    var leftBarButton: UIBarButtonItem!
    var rightBarButton: UIBarButtonItem!
    var currentA: MKAnnotation!
    let bikePlace = DataGet()
    var timer:NSTimer!
    
    private var xmlItems:[(staID:String,staName:String,ava:String,unava:String)]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureSearchBar()
        infoView.transform = CGAffineTransformMakeTranslation(0, -131)
        
        
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
        
        for element in stationData{//將位製作成annotation
            let annotation = MKPointAnnotation()
            annotation.title = element["StationName"] as? String
            annotation.coordinate = CLLocationCoordinate2D(latitude: (element["StationLat"] as! NSString).doubleValue as CLLocationDegrees , longitude: (element["StationLon"] as! NSString).doubleValue as CLLocationDegrees)
            mapView.showAnnotations([annotation], animated: true)
        }
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        if currentA != nil{
            showRoute(currentA)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is MKPointAnnotation) {
            return nil
        }
        
        let reuseId = "test"
        
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView!.image = UIImage(named:"bikePin")
            anView!.canShowCallout = true
        }
        else {
            anView!.annotation = annotation
        }
        
        return anView
       
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        //點下annotation後的動作
        self.mapView.removeOverlays(self.mapView.overlays)
        
        currentA = view.annotation
        showRoute(currentA)
        self.timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "bikeInfo:", userInfo: nil, repeats: true)
        //infoview滑下動畫
        UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.infoView.transform = CGAffineTransformMakeTranslation(0,0)
        },completion: nil)
        
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        UIView.animateWithDuration(0.2, animations: {
            self.infoView.transform = CGAffineTransformMakeTranslation(0, -130)
        })
        self.timer.invalidate()
        self.timer = nil
    }
    
    func showRoute(currentAnnotation: MKAnnotation){
        
        //設定路徑起始與目的地
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = MKMapItem.mapItemForCurrentLocation()
        let destinationPlacemark = MKPlacemark(coordinate: currentAnnotation.coordinate, addressDictionary: nil)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = MKDirectionsTransportType.Walking
        
        //方位計算
        let directions = MKDirections(request: directionRequest)
        directions.calculateDirectionsWithCompletionHandler{
            response, error in
            guard let response = response else {
                //handle the error here
                print("Error: \(error?.localizedDescription)")
                return
            }
            let route = response.routes[0] 
            self.mapView.addOverlay(route.polyline, level: MKOverlayLevel.AboveLabels)
            let etaMin = (NSInteger(route.expectedTravelTime)/60)%60 //預估步行時間
            self.travelTimeLabel.text = String(etaMin)

        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        //將路線畫至地圖
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(red: 53/255, green: 1, blue: 171/255, alpha: 0.7)
        renderer.lineWidth = 5.0
        
        return renderer
    }
    
    func bikeInfo(timer:NSTimer){
        let xmlParser = BikeParser()
        xmlParser.parserXml("http://www.c-bike.com.tw/xml/stationlistopendata.aspx", completionHandler: {(xmlItems:[(staID:String,staName:String,ava:String,unava:String)])->Void in
            self.xmlItems = xmlItems
            print(xmlItems)
        })
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
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: false)
        currentLocation = center
    
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let selectedLoc = view.annotation
        print("tsest")
         print("Annotation '\(selectedLoc!.title!)' has been selected")
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
        let region = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
        mapView.setRegion(region, animated: true)

    }

}

