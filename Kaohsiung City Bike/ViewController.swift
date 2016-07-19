//
//  ViewController.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2015/10/28.
//  Copyright © 2015年 Yang Tun-Kai. All rights reserved.
//
//  站點更新至105-04-22

import UIKit
import MapKit
import WatchConnectivity
import CoreLocation

//for spotlight search
import CoreSpotlight
import MobileCoreServices

class ViewController: UIViewController,WCSessionDelegate,MKMapViewDelegate,CLLocationManagerDelegate,UISearchBarDelegate,UISearchControllerDelegate,UIAlertViewDelegate, sendData{

    @IBOutlet var mapView:MKMapView!
    @IBOutlet var travelTimeLabel: UILabel!
    @IBOutlet var bikeTravelTimeLabel: UILabel!
    @IBOutlet var infoView: UIView!
    @IBOutlet var staName: UILabel!
    @IBOutlet var avaNum: UILabel!
    @IBOutlet var parkNum: UILabel!
    @IBOutlet var resultButtonOutlet: UIButton!
    @IBOutlet var timeButtonOutlet: UIButton!
    
    @IBOutlet var customInfo: UIView!
    @IBOutlet var customWalkingTimeLabel: UILabel!
    @IBOutlet var customRidingTimeLabel: UILabel!
    
    
    @IBOutlet var spendInfo: UIView!
    @IBOutlet var timeSpend: UILabel!
    @IBOutlet var costSpend: UILabel!
    @IBOutlet var blurView: UIView!
    
    
    let locationManager = CLLocationManager()
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
    var type = 0
    var annoArray:NSMutableArray? = NSMutableArray()
    var staNum:NSInteger!
    var watchSession:WCSession?
    let customAnnotation:MKPointAnnotation = MKPointAnnotation()
    var longPress:UILongPressGestureRecognizer!
    var shortPress:UITapGestureRecognizer!
    var locateCheck: Bool = true
    
    
    private var xmlItems:[(staID:String,staName:String,ava:String,unava:String)]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //configureSearchBar()
        if(WCSession.isSupported()){
            watchSession = WCSession.defaultSession()
            watchSession!.delegate = self
            watchSession!.activateSession()
        }
        
        //加入NotificationCenter Observer
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.timeOutAlert(_:)), name: "timeOut:", object: nil)
        
        //將一些預設在螢幕外
        self.infoView.transform = CGAffineTransformMakeTranslation(0, -310)
        self.spendInfo.transform = CGAffineTransformMakeTranslation(0, -368)
        self.customInfo.transform = CGAffineTransformMakeTranslation(0, -200)
        self.resultButtonOutlet.transform = CGAffineTransformMakeTranslation(0, -155)
        self.timeButtonOutlet.transform = CGAffineTransformMakeTranslation(0, 800)
        self.blurView.backgroundColor = UIColor(patternImage: UIImage(named: "bg-record")!)
        //leftBarButton = navigationItem.leftBarButtonItem
        //rightBarButton = navigationItem.rightBarButtonItem
        let StationTable = StationTableViewController()
        StationTable.mDelegate = self
        mapView.delegate = self
        locationManager.delegate = self
        
        //確認地理位置請求
        let status = CLLocationManager.authorizationStatus()
        if(status == CLAuthorizationStatus.AuthorizedWhenInUse){
            mapView.showsUserLocation = true;
            locationManager.startUpdatingLocation()
        }else{
            locationManager.requestWhenInUseAuthorization()
        }

        //精準度設為100m且移動50公尺才更新位置
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = CLLocationDistance(50)
        
        let stationData = bikePlace.bikeLocationJson()//抓腳踏車站點位置
        
        for element in stationData{//將位置作成annotation
            let annotation = MKPointAnnotation()
            annotation.title = element["StationName"] as? String
            annotation.coordinate = CLLocationCoordinate2D(latitude: (element["StationLat"] as! NSString).doubleValue as CLLocationDegrees , longitude: (element["StationLon"] as! NSString).doubleValue as CLLocationDegrees)
            annoArray?.addObject(annotation)
            mapView.showAnnotations([annotation], animated: true)
        }
        
        //添加手勢
        self.longPress = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.addAnnotation(_:)))
        //長壓兩秒才有反應
        self.longPress.minimumPressDuration = 1.5
        self.mapView.addGestureRecognizer(longPress)
        
        self.setupSearchableContent()
    
    }
    
    func sendData(stationName: String) {
        //將車站列表被點選的站點與地圖上的站點對照
        let result = self.mapView.annotations.filter{
            if let staName = $0.title{
                return staName == stationName
            }
            return false
        }
        self.mapView.selectAnnotation(result[0], animated: true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "segueToStation"{
            let destination = segue.destinationViewController as! StationTableViewController
            destination.mDelegate = self
        }
    }
    
    func addAnnotation(gestureRecognizer: UIGestureRecognizer){
        print("add customeAnnotation")
        
        //偵測開始即移除手勢以免多按
        if(gestureRecognizer.state == .Began){
            self.mapView.removeGestureRecognizer(gestureRecognizer)
        }
        
        //取得所點位置的座標
        let touchPoint: CGPoint! = gestureRecognizer.locationInView(self.mapView)
        let touchMapCoordinate: CLLocationCoordinate2D = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
        
        self.customAnnotation.title = NSLocalizedString("Destination", comment: "")
        self.customAnnotation.coordinate = touchMapCoordinate
        //顯示到customAnnotation的路線
        showRoute(customAnnotation)
        //把customAnnotation加到地圖上
        self.mapView.addAnnotation(customAnnotation)
        //設定customAnnotation已選狀態
        self.mapView.selectAnnotation(customAnnotation, animated: true)
        //加入點壓手勢
        self.shortPress = UITapGestureRecognizer(target: self, action: #selector(ViewController.removeAnnotation(_:)))
        self.mapView.addGestureRecognizer(shortPress)
        
    }
    
    func removeAnnotation(gestureRecognizer: UIGestureRecognizer){
        print("remove customeAnnotation")
        //移除路線、customAnnotation、手勢
        self.mapView.removeOverlays(self.mapView.overlays)
        self.mapView.removeAnnotation(customAnnotation)
        self.mapView.removeGestureRecognizer(gestureRecognizer)
        
        //CustomInfo 回到螢幕外
        UIView.animateWithDuration(0.5, animations: {
            self.customInfo.transform = CGAffineTransformMakeTranslation(0, -200)
        })
        
        self.mapView.addGestureRecognizer(self.longPress)
    }
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        
        if currentA != nil{
            showRoute(currentA)
        }
        if locateCheck{
            locateCheck = false
            checkIfInCity()
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
            anView!.centerOffset = CGPointMake(0, -anView!.frame.size.height/2)
        }else {
            anView!.annotation = annotation
            if(!(self.annoArray!.containsObject((anView?.annotation)!))){
                anView!.image = UIImage(named:"flagpin")
            }
        }
        return anView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        //分離出UserLocation Annotation及Custom Annotation
        if !(view.annotation is MKUserLocation){
            //規劃路徑
            currentA = view.annotation
            showRoute(currentA)
            var annoType = 0
            
            if !(view.annotation!.isEqual(self.customAnnotation)){
                self.staNum = self.annoArray?.indexOfObject(view.annotation!)
                //點下annotation後的動作
                mapView.removeOverlays(self.mapView.overlays)
                self.staName.text = (view.annotation?.title)!
                annoType = 1
                
                //偵測網路是否連線
                if Reachability.isConnectedToNetwork() == true {
                    //啟動timer每五分鐘抓腳踏車資訊
                    NSTimer.scheduledTimerWithTimeInterval(0, target: self, selector: #selector(ViewController.bikeInfo(_:)), userInfo: nil, repeats: false)
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(300, target: self, selector: #selector(ViewController.bikeInfo(_:)), userInfo: nil, repeats: true)
                
                    //infoview滑下及timeButton滑上動畫
                    UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                        self.infoView.transform = CGAffineTransformMakeTranslation(0,0)
                        self.timeButtonOutlet.transform = CGAffineTransformMakeTranslation(0, 0)
                        },completion: nil)
                }else{
                    let alert = UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("Error_Log", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }else{
                UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                    self.customInfo.transform = CGAffineTransformMakeTranslation(0,0)
                    self.timeButtonOutlet.transform = CGAffineTransformMakeTranslation(0, 0)
                    },completion: nil)
            }
            
            //儲存annotation位置以分享給watchapp
            let annolong = view.annotation?.coordinate.longitude
            let annolati = view.annotation?.coordinate.latitude
            let title = view.annotation?.title
            
            
            if WCSession.defaultSession().reachable == true {
                let locationSession = ["longitude" : annolong!, "latitude": annolati!, "stationName":title!!, "annoType": annoType]
                let session = WCSession.defaultSession()
                session.sendMessage(locationSession as! [String : AnyObject], replyHandler:nil, errorHandler: nil)
            }
        }
        
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {

        //分離出UserLocation Annotation
        if !(view.annotation is MKUserLocation) && !(view.annotation!.isEqual(self.customAnnotation)){
            UIView.animateWithDuration(0.5, animations: {
                self.infoView.transform = CGAffineTransformMakeTranslation(0, -200)
                self.timeButtonOutlet.transform = CGAffineTransformMakeTranslation(0, 100)
            })
            if(self.timer != nil){
                self.timer.invalidate()
                self.timer = nil
            }
        }
    }
    
    func showRoute(currentAnnotation: MKAnnotation){
        
        let overlays = self.mapView.overlays//移除位置更新後的舊線條
        mapView.removeOverlays(overlays)
        
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
            self.mapView.addOverlay(route.polyline, level: MKOverlayLevel.AboveRoads)
            let etaMin = (NSInteger(route.expectedTravelTime)/60) //預估步行時間
            
            if currentAnnotation.isEqual(self.customAnnotation){
                self.customWalkingTimeLabel.text = String(etaMin)
            }else{
                self.travelTimeLabel.text = String(etaMin)
            }
        }
        
        //計算腳踏車行車時間（以Automobile暫代，因Apple Map不提供 Bike）
        let bikeRequest = MKDirectionsRequest()
        bikeRequest.source = MKMapItem.mapItemForCurrentLocation()
        let bikePlacemark = MKPlacemark(coordinate: currentAnnotation.coordinate, addressDictionary: nil)
        bikeRequest.destination = MKMapItem(placemark: bikePlacemark)
        bikeRequest.transportType = MKDirectionsTransportType.Automobile
        let bikeDirections = MKDirections(request: bikeRequest)
        bikeDirections.calculateDirectionsWithCompletionHandler{
            response, error in
            guard let response = response else {
                //handle the error here
                print("Error: \(error?.localizedDescription)")
                return
            }
            let bikeTime = response.routes[0].expectedTravelTime
            if currentAnnotation.isEqual(self.customAnnotation){
                self.customRidingTimeLabel.text = String(NSInteger(bikeTime)/60)
            }else{
                self.bikeTravelTimeLabel.text = String(NSInteger(bikeTime)/60)
            }
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        //將路線畫至地圖
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(red: 0, green: 145/255, blue: 245/255, alpha: 0.7)
        renderer.lineWidth = 10.0
        
        return renderer
    }
    
    func bikeInfo(timer:NSTimer){
        let xmlParser = BikeParser()
    
        xmlParser.parserXml("http://www.c-bike.com.tw/xml/stationlistopendata.aspx", completionHandler: {(xmlItems:[(staID:String,staName:String,ava:String,unava:String)])->Void in
            self.xmlItems = xmlItems
            
            if WCSession.defaultSession().reachable == true {
                let bikeSession = ["ava" : xmlItems[self.staNum].ava, "unava": xmlItems[self.staNum].unava]
                let session = WCSession.defaultSession()
                session.sendMessage(bikeSession, replyHandler: nil, errorHandler: nil)
            }
    
            dispatch_async(dispatch_get_main_queue(), {
                if Int(self.xmlItems![self.staNum].ava)<10{
                    self.avaNum.textColor = UIColor(red: 232/255, green: 87/255, blue: 134/255, alpha: 1)
                }else{
                    self.avaNum.textColor = UIColor.blackColor()
                }
                if Int(self.xmlItems![self.staNum].unava)<10{
                    self.parkNum.textColor = UIColor(red: 232/255, green: 87/255, blue: 134/255, alpha: 1)
                }else{
                    self.parkNum.textColor = UIColor.blackColor()
                }
                self.avaNum.text = self.xmlItems![self.staNum].ava
                self.parkNum.text = self.xmlItems![self.staNum].unava
            })
        })

    }
    
    func stopWatchTimer(timer:NSTimer){
        count += 1
        let second = count%60
        let minute = (count/60)%60
        let hour = Int(count/3600)
        self.timeButtonOutlet.setTitle(String(format: "%02d:%02d:%02d",hour,minute,second), forState: .Normal)
    }
    
    func showSpendInfo(){
        let second = count%60
        let minute = (count/60)%60//計算使用時間
        var calMinute = Int(count/60)
        let hour = Int(count/3600)
        let timeInfo = String(format:"%02d:%02d:%02d",hour,minute,second)
        self.timeSpend.text = timeInfo
        
        var cost = 0//計算花費
        switch minute{
            case 0...60: cost = 0 //不滿60分鐘免費
            case 61...90: cost = 10 //90分鐘 10元
            default: //90分後每30分20元
                calMinute -= 90
                if calMinute % 30 != 0{
                     calMinute = Int(calMinute/30)+1
                }else{
                    calMinute = Int(calMinute/30)
                }
                cost = 10 + (calMinute*20)
        }
        let costInfo = "NT$ \(cost)"
        self.costSpend.text = costInfo

        //spendInfo滑下動畫
        self.spendInfo.hidden = false
        self.resultButtonOutlet.hidden = false
        UIView.animateWithDuration(1.0, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            self.spendInfo.transform = CGAffineTransformMakeTranslation(0,0)
            self.resultButtonOutlet.transform = CGAffineTransformMakeTranslation(0, 0)
            },completion: nil)
        
    }
    
    /*
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
    */
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude , longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: false)
        currentLocation = center
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status{
        case .Denied,.Restricted:
            requestAgain()
        default:
            break
        }
    }
    
    func checkIfInCity(){
        //不在範圍內跳出警示
        print("current location:\(currentLocation.longitude);\(currentLocation.latitude)")
        if((currentLocation.longitude < 120.17 || currentLocation.longitude > 120.43) || (currentLocation.latitude > 22.91 || currentLocation.latitude < 22.508)){
            locationManager.stopUpdatingLocation()
            let alert = UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("Range", comment: ""), preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func requestAgain(){
        //前往設定APP
        let alert = UIAlertController(title: NSLocalizedString("Title", comment: ""), message: NSLocalizedString("Content", comment: ""), preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("SetButton", comment: ""), style: .Default, handler: {
            action in
            let url = NSURL(string: UIApplicationOpenSettingsURLString)
            UIApplication.sharedApplication().openURL(url!)
        }))
        alert.addAction(UIAlertAction(title:  NSLocalizedString("OkButton", comment: ""), style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func timeOutAlert(notification:NSNotification){
        //連線逾時AlerView
        let message = notification.userInfo!["message"] as! String
        let alert = UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        timer.invalidate()
    }
    
    // spotlight search feature
    func setupSearchableContent(){
        let stationData = bikePlace.bikeLocationJson()//抓腳踏車站點位置
        var searchableItems = [CSSearchableItem]()
        
        for element in stationData{//將位置作成Searchable data
            
            let searchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
            searchableItemAttributeSet.title = element["StationName"] as? String
            searchableItemAttributeSet.contentDescription = element["StationAddress"] as? String
            searchableItemAttributeSet.thumbnailData = UIImagePNGRepresentation(UIImage(named:"available-widget")!)
            
            var keywords = [String]()
            keywords.append(element["StationName"] as! String)
            keywords.append(element["StationAddress"] as! String)
            searchableItemAttributeSet.keywords = keywords
            
            let index = stationData.indexOfObject(element)
            
            let searchableItem = CSSearchableItem(uniqueIdentifier: "Sparkrs.CityBike.SpotIt.\(index)", domainIdentifier: "bike", attributeSet: searchableItemAttributeSet)
            searchableItems.append(searchableItem)
        }
        
        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems(searchableItems, completionHandler: {(error)->Void in
            if(error != nil){
                print(error?.localizedDescription)
            }
        })
        
    }
    
    override func restoreUserActivityState(activity: NSUserActivity) {
        if activity.activityType == CSSearchableItemActionType{
            if let userInfo = activity.userInfo{
                //取得spotlight search裡的 identifier
                let selectedStation = userInfo[CSSearchableItemActivityIdentifier] as! String
                //將identifier切割取最後一位
                let selectedIndex = Int(selectedStation.componentsSeparatedByString(".").last!)
                let stationData = bikePlace.bikeLocationJson()
                let stationName = stationData[selectedIndex!]["StationName"] as! String
                //將stationname送入senddata以被找出選擇的點
                sendData(stationName)
            }
        }
    }

    override func viewDidDisappear(animated: Bool) {
        //畫面消失時停止更新位置（節省電量）
        locationManager.stopUpdatingLocation()
        //移除NotificationCenter
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "timeOut", object: nil)
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
        let status = CLLocationManager.authorizationStatus()
        if(status == .AuthorizedWhenInUse){
            if(currentLocation != nil){
                let region = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    
                mapView.setRegion(region, animated: true)
            }
        }else{
            //取得地理授權
            requestAgain()
        }
    }

    @IBAction func timeButton(sender: AnyObject) {
        if timeButtonOutlet.titleLabel?.text == NSLocalizedString("Time_Start", comment: ""){//一開始按下後
            self.timeButtonOutlet.setTitle("00:00:00", forState: .Normal)
            
            var bgTask = UIBackgroundTaskIdentifier()
            let app = UIApplication.sharedApplication()
            bgTask = app.beginBackgroundTaskWithExpirationHandler({ () -> Void in
                app.endBackgroundTask(bgTask)
            })
            
            
            self.stopWatch = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(ViewController.stopWatchTimer(_:)), userInfo: nil, repeats: true)
            self.timeButtonOutlet.backgroundColor = UIColor(red: 255/255, green: 102/255, blue: 153/255, alpha: 1)
            
            //設定Local Notification
            let localNotification = UILocalNotification()
            let pushDate = NSDate(timeIntervalSinceNow: 1200)
            localNotification.fireDate = pushDate
            localNotification.timeZone = NSTimeZone.defaultTimeZone()
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.alertBody = NSLocalizedString("Twenty_Minutes_Alert", comment: "")
            localNotification.alertTitle = NSLocalizedString("Time_Alert", comment: "")
            localNotification.category = "myCategory"
            UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
            
            let finalNotification = UILocalNotification()
            finalNotification.fireDate = NSDate(timeIntervalSinceNow: 1800)
            finalNotification.timeZone = NSTimeZone.defaultTimeZone()
            finalNotification.soundName = UILocalNotificationDefaultSoundName
            finalNotification.alertBody = NSLocalizedString("Thirty_Minutes_Alert", comment: "")
            finalNotification.alertTitle = NSLocalizedString("Time_Alert", comment: "")
            finalNotification.category = "myCategory"
            UIApplication.sharedApplication().scheduleLocalNotification(finalNotification)
            
        }else{//結束計時
            self.stopWatch.invalidate()
            self.stopWatch = nil
            self.timeButtonOutlet.setTitle(NSLocalizedString("Time_Start", comment: ""), forState: .Normal)
            self.timeButtonOutlet.backgroundColor = UIColor(red: 45/255, green: 222/255, blue: 149/255, alpha: 1)
            self.blurView.hidden = false
            UIApplication.sharedApplication().cancelAllLocalNotifications()
            showSpendInfo()
            self.count = 0;
        }
        
    }
    @IBAction func doneButton(sender: AnyObject) {
        let button = sender as! UIButton
        UIView.animateWithDuration(0.2, animations: {
            self.spendInfo.transform = CGAffineTransformMakeTranslation(0, -400)
            button.transform = CGAffineTransformMakeTranslation(0, -400)
        })
        self.blurView.hidden = true
        
    }
    
}

