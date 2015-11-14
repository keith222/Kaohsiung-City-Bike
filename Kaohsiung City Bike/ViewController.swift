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
    @IBOutlet var staName: UILabel!
    @IBOutlet var avaNum: UILabel!
    @IBOutlet var parkNum: UILabel!
    @IBOutlet var timeButtonOutlet: UIButton!
    @IBOutlet var spendInfo: UIView!
    @IBOutlet var timeSpend: UILabel!
    @IBOutlet var costSpend: UILabel!
    @IBOutlet var lightBlur: UIVisualEffectView!
    
    
    let locationManager = CLLocationManager();
    var transportType = MKDirectionsTransportType.Walking //以步行方式導航
    var currentLocation: CLLocationCoordinate2D!
    var searchController: UISearchController!
    var leftBarButton: UIBarButtonItem!
    var rightBarButton: UIBarButtonItem!
    var currentA: MKAnnotation!
    let bikePlace = DataGet()
    var timer:NSTimer!
    var stopWatch:NSTimer!
    var count = 0
    var annoArray:NSMutableArray? = NSMutableArray()
    var staNum:NSInteger!
    
    private var xmlItems:[(staID:String,staName:String,ava:String,unava:String)]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //configureSearchBar()
        self.infoView.transform = CGAffineTransformMakeTranslation(0, -140)
        self.spendInfo.transform = CGAffineTransformMakeTranslation(0, -400)
        self.timeButtonOutlet.transform = CGAffineTransformMakeTranslation(0, 800)
        
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
        
        
        let stationData = bikePlace.bikeLocationJson()//抓腳踏車站點位置
        
        for element in stationData{//將位置作成annotation
            let annotation = MKPointAnnotation()
            annotation.title = element["StationName"] as? String
            annotation.coordinate = CLLocationCoordinate2D(latitude: (element["StationLat"] as! NSString).doubleValue as CLLocationDegrees , longitude: (element["StationLon"] as! NSString).doubleValue as CLLocationDegrees)
            mapView.showAnnotations([annotation], animated: true)
            annoArray?.addObject(annotation)
            
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
 
        let reuseId = "pin"
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
        
        self.staNum = self.annoArray?.indexOfObject(view.annotation!)
        
        //點下annotation後的動作
        mapView.removeOverlays(self.mapView.overlays)
        self.staName.text = (view.annotation?.title)!
        currentA = view.annotation
        showRoute(currentA)

        //啟動timer每一分鐘抓腳踏車資訊
        NSTimer.scheduledTimerWithTimeInterval(0, target: self, selector: "bikeInfo:", userInfo: nil, repeats: false)
        self.timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: "bikeInfo:", userInfo: nil, repeats: true)
        
        //infoview滑下及timeButton滑上動畫
        UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.infoView.transform = CGAffineTransformMakeTranslation(0,0)
            self.timeButtonOutlet.transform = CGAffineTransformMakeTranslation(0, 0)
        },completion: nil)
        
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        UIView.animateWithDuration(0.5, animations: {
            self.infoView.transform = CGAffineTransformMakeTranslation(0, -140)
            self.timeButtonOutlet.transform = CGAffineTransformMakeTranslation(0, 100)
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
            
            dispatch_async(dispatch_get_main_queue(), {
                if Int(self.xmlItems![self.staNum].ava)<10{
                    self.avaNum.textColor = UIColor(red: 232/255, green: 87/255, blue: 134/255, alpha: 1)
                }
                if Int(self.xmlItems![self.staNum].unava)<10{
                    self.parkNum.textColor = UIColor(red: 232/255, green: 87/255, blue: 134/255, alpha: 1)
                }
                self.avaNum.text = self.xmlItems![self.staNum].ava
                self.parkNum.text = self.xmlItems![self.staNum].unava
            })
        })

    }
    
    func stopWatchTimer(timer:NSTimer){
        count++
        let minute = (count/60)%60
        self.timeButtonOutlet.setTitle(String(format: "%02d:%02d",minute,count), forState: .Normal)
    }
    
    func showSpendInfo(){

        var minute = (count/60)%60//計算使用時間
        let timeInfo = "\(minute) min \(count) sec"
        self.timeSpend.text = timeInfo
        
        var cost = 0//計算花費
        switch minute{
            case 0...60: cost = 0 //不滿60分鐘免費
            case 61...90: cost = 10 //90分鐘 10元
            default: //90分後每30分20元
                minute -= 90
                if minute % 30 != 0{
                     minute = Int(minute/30)+1
                }else{
                    minute = Int(minute/30)
                }
                cost = 10 + (minute*20)
        }
        let costInfo = "NT$ \(cost)"
        self.costSpend.text = costInfo

        //spendInfo滑下動畫
        UIView.animateWithDuration(1.5, delay: 0.0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.spendInfo.transform = CGAffineTransformMakeTranslation(0,0)
            },completion: nil)
        
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

    @IBAction func timeButton(sender: AnyObject) {
        if timeButtonOutlet.titleLabel?.text == NSLocalizedString("Time_Start", comment: ""){//一開始按下後
            self.timeButtonOutlet.setTitle("00:00", forState: .Normal)
            self.stopWatch = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "stopWatchTimer:", userInfo: nil, repeats: true)
            self.timeButtonOutlet.backgroundColor = UIColor(red: 255/255, green: 102/255, blue: 153/255, alpha: 1)
            
        }else{//結束計時
            self.stopWatch.invalidate()
            self.stopWatch = nil
            self.timeButtonOutlet.setTitle(NSLocalizedString("Time_Start", comment: ""), forState: .Normal)
            self.timeButtonOutlet.backgroundColor = UIColor(red: 0, green: 1, blue: 128/255, alpha: 1)
            self.lightBlur.hidden = false
            showSpendInfo()
        }
        
    }
    @IBAction func doneButton(sender: AnyObject) {
        UIView.animateWithDuration(0.2, animations: {
            self.spendInfo.transform = CGAffineTransformMakeTranslation(0, -400)
        })
        self.lightBlur.hidden = true
        
    }
    
}
