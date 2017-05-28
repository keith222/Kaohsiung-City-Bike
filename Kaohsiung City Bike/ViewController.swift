//
//  ViewController.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2015/10/28.
//  Copyright © 2015年 Yang Tun-Kai. All rights reserved.
//
//  站點更新至106-05-28

import UIKit
import MapKit
import WatchConnectivity
import CoreLocation

//for spotlight search
import CoreSpotlight
import MobileCoreServices



class ViewController: UIViewController,WCSessionDelegate,MKMapViewDelegate,CLLocationManagerDelegate,UIAlertViewDelegate, sendData{


    @IBOutlet var mapView:MKMapView!
    @IBOutlet var travelTimeLabel: UILabel!
    @IBOutlet var bikeTravelTimeLabel: UILabel!
    @IBOutlet var infoView: UIView!
    @IBOutlet var staName: UILabel!
    @IBOutlet var avaNum: UILabel!
    @IBOutlet var parkNum: UILabel!
    @IBOutlet var resultButtonOutlet: UIButton!
    @IBOutlet var timeButtonOutlet: UIButton!
    @IBOutlet var locateButton: UIButton!

    @IBOutlet var customInfo: UIView!
    @IBOutlet var customWalkingTimeLabel: UILabel!
    @IBOutlet var customRidingTimeLabel: UILabel!
    
    @IBOutlet var spendInfo: UIView!
    @IBOutlet var timeSpend: UILabel!
    @IBOutlet var costSpend: UILabel!
    @IBOutlet var blurView: UIView!
    
    
    let locationManager = CLLocationManager()
    var transportType = MKDirectionsTransportType.walking //以步行方式導航
    var currentLocation: CLLocationCoordinate2D!
    var currentA: MKAnnotation!
    var selectedAnnotation:MKPointAnnotation!
    let customAnnotation:MKPointAnnotation = MKPointAnnotation()
    var locateCheck: Bool = true

    let bikePlace = DataGet()
    var timer:Timer!
    var stopWatch:Timer!
    var count = 0
    var annoArray:[MKAnnotation]? = [MKAnnotation]()
    var stationName:String!
    
    var watchSession:WCSession?
    
    var longPress:UILongPressGestureRecognizer!
    var shortPress:UITapGestureRecognizer!
    
    var leftBarButton: UIBarButtonItem!
    var rightBarButton: UIBarButtonItem!
    
    var duration: Date?
    
    fileprivate var xmlItems:[(staID:String,staName:String,ava:String,unava:String)]?
    
    let reachability = Reachability()!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //configureSearchBar()
        if(WCSession.isSupported()){
            watchSession = WCSession.default()
            watchSession!.delegate = self
            watchSession!.activate()
        }
        
        //加入NotificationCenter Observer
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.timeOutAlert(_:)), name: NSNotification.Name(rawValue: "timeOut:"), object: nil)
        
        //將一些預設在螢幕外
        self.infoView.transform = CGAffineTransform(translationX: 0, y: -310)
        self.spendInfo.transform = CGAffineTransform(translationX: 0, y: -368)
        self.customInfo.transform = CGAffineTransform(translationX: 0, y: -200)
        self.resultButtonOutlet.transform = CGAffineTransform(translationX: 0, y: -368)
        self.timeButtonOutlet.transform = CGAffineTransform(translationX: 0, y: 800)
        self.blurView.backgroundColor = UIColor(patternImage: UIImage(named: "bg-record")!)
        
        let StationTable = StationTableViewController()
        StationTable.mDelegate = self
        mapView.delegate = self
        locationManager.delegate = self
        
        //確認地理位置請求
        let status = CLLocationManager.authorizationStatus()
        if(status == CLAuthorizationStatus.authorizedWhenInUse){
            mapView.showsUserLocation = true;
            mapView.userTrackingMode = .follow
            locationManager.startUpdatingLocation()
            //精準度設為100m且移動50公尺才更新位置
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = CLLocationDistance(50)
        }else{
            locationManager.requestWhenInUseAuthorization()
        }
        
        let stationData = bikePlace.bikeLocationJson()//抓腳踏車站點位置
        
        for element in stationData{//將位置作成annotation
            let annotation = MKPointAnnotation()
            annotation.title = element["StationName"] as? String
            annotation.coordinate = CLLocationCoordinate2D(latitude: (element["StationLat"] as! NSString).doubleValue as CLLocationDegrees , longitude: (element["StationLon"] as! NSString).doubleValue as CLLocationDegrees)
            annoArray?.append(annotation)
        }
        
        //添加手勢
        self.longPress = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.addAnnotation(_:)))
        //長壓兩秒才有反應
        self.longPress.minimumPressDuration = 1.5
        self.mapView.addGestureRecognizer(longPress)
        
        self.setupSearchableContent()
        
        //設定UIView,UIButton 邊線及陰影
        self.locateButton.addBorder(5.0, thickness: 1.0, color: UIColor(red: 93/255, green: 110/255, blue: 120/255, alpha: 0.3))
        self.timeButtonOutlet.addBorder(10.0, thickness: 0, color: self.timeButtonOutlet.backgroundColor!)
        self.timeButtonOutlet.addShadow(UIColor(red: 23/255, green: 169/255, blue: 174/255, alpha: 1.0))
        self.resultButtonOutlet.addBorder(10.0, thickness: 0, color: self.resultButtonOutlet.backgroundColor!)
        self.resultButtonOutlet.addShadow(UIColor(red: 23/255, green: 169/255, blue: 174/255, alpha: 1.0))
        
        self.infoView.addBorder(5.0, thickness: 1.0, color: UIColor(red: 205/255, green: 224/255, blue: 222/255, alpha: 1.0))
        self.infoView.addShadow(UIColor(red: 23/255, green: 169/255, blue: 174/255, alpha: 1.0))
        self.customInfo.addBorder(5.0, thickness: 1.0, color: UIColor(red: 205/255, green: 224/255, blue: 222/255, alpha: 1.0))
        self.customInfo.addShadow(UIColor(red: 23/255, green: 169/255, blue: 174/255, alpha: 1.0))
        self.spendInfo.addBorder(5.0, thickness: 1.0, color: UIColor(red: 205/255, green: 224/255, blue: 222/255, alpha: 1.0))
        self.spendInfo.addShadow(UIColor(red: 23/255, green: 169/255, blue: 174/255, alpha: 1.0))
    }
    
    func sendData(_ stationName: String) {
        //將車站列表被點選的站點與地圖上的站點對照
        let result = self.mapView.annotations.filter{
            if let staName = $0.title{
                return staName == stationName
            }
            return false
        }
        
        self.mapView.removeAnnotation(self.customAnnotation)
        
        //地圖上沒有站點則繪出，有則選擇
        let location: CLLocationCoordinate2D?
        if result.isEmpty{
            let newAnn = self.annoArray!.filter{$0.title!! == stationName}.first!
            self.mapView.addAnnotation(newAnn)
            self.mapView.selectAnnotation(newAnn, animated: true)
            location = newAnn.coordinate
        }else{
            self.mapView.selectAnnotation(result[0], animated: true)
            location = result[0].coordinate
        }
        
        let region = MKCoordinateRegion(center: location!, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        self.mapView.setRegion(region, animated: true)
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToStation"{
            let destination = segue.destination as! StationTableViewController
            destination.mDelegate = self
        }
    }
    
    func addAnnotation(_ gestureRecognizer: UIGestureRecognizer){
        print("add customeAnnotation")
        
        //偵測開始即移除手勢以免多按
        if(gestureRecognizer.state == .began){
            self.mapView.removeGestureRecognizer(gestureRecognizer)
        }
        
        //取得所點位置的座標
        let touchPoint: CGPoint! = gestureRecognizer.location(in: self.mapView)
        let touchMapCoordinate: CLLocationCoordinate2D = self.mapView.convert(touchPoint, toCoordinateFrom: self.mapView)
        
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
    
    func removeAnnotation(_ gestureRecognizer: UIGestureRecognizer){
        print("remove customeAnnotation")
        //移除路線、customAnnotation、手勢
        self.mapView.removeOverlays(self.mapView.overlays)
        self.mapView.removeAnnotation(customAnnotation)
        self.mapView.removeGestureRecognizer(gestureRecognizer)
        
        //CustomInfo 回到螢幕外
        UIView.animate(withDuration: 0.5, animations: {
            self.customInfo.transform = CGAffineTransform(translationX: 0, y: -200)
        },completion:{(completion) -> Void in
            self.customInfo.isHidden = true
            self.parkNum.text = "--"
            self.avaNum.text = "--"
            self.travelTimeLabel.text = "--"
            self.bikeTravelTimeLabel.text = "--"
        })
        
        self.mapView.addGestureRecognizer(self.longPress)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if currentA != nil{
            showRoute(currentA)
        }
        if locateCheck{
            locateCheck = false
            checkIfInCity(location: userLocation)
        }
    }
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        print("view did finish render")
        //filter annotation in map rect
        let existAnnotation = annoArray?.filter({ (annotation) in
            MKMapRectContainsPoint(
                self.mapView.visibleMapRect, MKMapPointForCoordinate(annotation.coordinate)
            )
            &&
            !self.mapView.annotations.contains{$0.isEqual(annotation)}
        })
        if existAnnotation?.count != 0{
            self.mapView.addAnnotations(existAnnotation as! [MKPointAnnotation])
        }
        
        print("annotation count: \(self.mapView.annotations(in: self.mapView.visibleMapRect).count)")
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is MKPointAnnotation) {
            return nil
        }
        let reuseId = "pin"
        var anView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView!.canShowCallout = true
            //anView!.centerOffset = CGPointMake(0, -anView!.frame.size.height/2)
        }else {
            anView!.annotation = annotation
        }
        anView!.image = !(self.annoArray!.contains{$0.isEqual(anView!.annotation)}) ? UIImage(named:"flagpin") : UIImage(named:"bikePin")
        
        return anView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //分離出UserLocation Annotation及Custom Annotation
        if !(view.annotation is MKUserLocation){
            //規劃路徑
            currentA = view.annotation
            showRoute(currentA)
            var annoType = 0
            
            if !(view.annotation!.isEqual(self.customAnnotation)){
                self.stationName = (view.annotation?.title)!
                //點下annotation後的動作
                mapView.removeOverlays(self.mapView.overlays)
                self.staName.text = (view.annotation?.title)!
                annoType = 1
                
                //偵測網路是否連線
                if self.reachability.isReachable == true {
                    //啟動timer每五分鐘抓腳踏車資訊
                    Timer.scheduledTimer(timeInterval: 0, target: self, selector: #selector(ViewController.bikeInfo(_:)), userInfo: nil, repeats: false)
                    self.timer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(ViewController.bikeInfo(_:)), userInfo: nil, repeats: true)
                
                    //infoview滑下及timeButton滑上動畫
                    self.infoView.isHidden = false
                    self.timeButtonOutlet.isHidden = false
                    UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.curveEaseOut, animations: {
                        self.infoView.transform = CGAffineTransform(translationX: 0,y: 0)
                        self.timeButtonOutlet.transform = CGAffineTransform(translationX: 0, y: 0)
                        },completion: nil)
                }else{
                    let alert = UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("Error_Log", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }else{
                self.customInfo.isHidden = false
                UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.curveEaseOut, animations: {
                    self.customInfo.transform = CGAffineTransform(translationX: 0,y: 0)
                    self.timeButtonOutlet.transform = CGAffineTransform(translationX: 0, y: 0)
                    },completion: nil)
            }
            
            //儲存annotation位置以分享給watchapp
            let annolong = view.annotation?.coordinate.longitude
            let annolati = view.annotation?.coordinate.latitude
            let title = view.annotation?.title
            
            
            if WCSession.default().isReachable == true {
                let locationSession = ["longitude" : annolong!, "latitude": annolati!, "stationName":title!!, "annoType": annoType] as [String : Any]
                let session = WCSession.default()
                session.sendMessage(locationSession as [String : AnyObject], replyHandler:nil, errorHandler: nil)
            }
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        //分離出UserLocation Annotation
        if !(view.annotation is MKUserLocation){
            UIView.animate(withDuration: 0.5, animations: {
                self.infoView.transform = CGAffineTransform(translationX: 0, y: -310)
                self.timeButtonOutlet.transform = CGAffineTransform(translationX: 0, y: 100)
                
                if view.annotation!.isEqual(self.customAnnotation){
                    self.customInfo.transform = CGAffineTransform(translationX: 0, y: -200)
                }
            })
            if(self.timer != nil){
                self.timer.invalidate()
                self.timer = nil
            }
        }
    }
    
    func showRoute(_ currentAnnotation: MKAnnotation){
        
        let oldOverlays = self.mapView.overlays //記錄舊線條
        
        
        //設定路徑起始與目的地
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = MKMapItem.forCurrentLocation()
        let destinationPlacemark = MKPlacemark(coordinate: currentAnnotation.coordinate, addressDictionary: nil)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = MKDirectionsTransportType.walking
        
        //方位計算
        let directions = MKDirections(request: directionRequest)
        directions.calculate{ [unowned self]
            response, error in
            guard let response = response else {
                //handle the error here
                print("Error: \(String(describing: error?.localizedDescription))")
                return
            }
            let route = response.routes[0] 
            self.mapView.add(route.polyline, level: MKOverlayLevel.aboveRoads)
            self.mapView.removeOverlays(oldOverlays)//移除位置更新後的舊線條
            
            let etaMin = (NSInteger(route.expectedTravelTime)/60) //預估步行時間
            
            if currentAnnotation.isEqual(self.customAnnotation){
                self.customWalkingTimeLabel.text = String(etaMin)
            }else{
                self.travelTimeLabel.text = String(etaMin)
            }
        }
        
        //計算腳踏車行車時間（以Automobile暫代，因Apple Map不提供 Bike）
        let bikeRequest = MKDirectionsRequest()
        bikeRequest.source = MKMapItem.forCurrentLocation()
        let bikePlacemark = MKPlacemark(coordinate: currentAnnotation.coordinate, addressDictionary: nil)
        bikeRequest.destination = MKMapItem(placemark: bikePlacemark)
        bikeRequest.transportType = MKDirectionsTransportType.automobile
        let bikeDirections = MKDirections(request: bikeRequest)
        bikeDirections.calculate{
            response, error in
            guard let response = response else {
                //handle the error here
                print("Error: \(String(describing: error?.localizedDescription))")
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        //將路線畫至地圖
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(red: 40/255, green: 144/255, blue: 244/255, alpha: 1.0)
        renderer.lineWidth = 10.0
        
        return renderer
    }
    
    func bikeInfo(_ timer:Timer){
        let xmlParser = BikeParser()
    
        xmlParser.parserXml("http://www.c-bike.com.tw/xml/stationlistopendata.aspx", completionHandler: {(xmlItems:[(staID:String,staName:String,ava:String,unava:String)])->Void in
            self.xmlItems = xmlItems
            
            let index = self.xmlItems?.index(where: {
                return $0.staName == self.stationName
            })
            
            if WCSession.default().isReachable == true {
                let bikeSession = ["ava" : xmlItems[index!].ava, "unava": xmlItems[index!].unava]
                let session = WCSession.default()
                session.sendMessage(bikeSession, replyHandler: nil, errorHandler: nil)
            }
    
            DispatchQueue.main.async(execute: {
                if Int(self.xmlItems![index!].ava)! < 10{
                    self.avaNum.textColor = UIColor(red: 213/255, green: 71/255, blue: 104/255, alpha: 1)
                }else{
                    self.avaNum.textColor = UIColor(red: 93/255, green: 119/255, blue: 120/255, alpha: 1.0)
                }
                if Int(self.xmlItems![index!].unava)! < 10{
                    self.parkNum.textColor = UIColor(red: 213/255, green: 71/255, blue: 104/255, alpha: 1)
                }else{
                    self.parkNum.textColor = UIColor(red: 93/255, green: 119/255, blue: 120/255, alpha: 1.0)
                }
                self.avaNum.text = self.xmlItems![index!].ava
                self.parkNum.text = self.xmlItems![index!].unava
            })
        })

    }
    
    func stopWatchTimer(_ timer:Timer){
        count += 1
        let second = count%60
        let minute = (count/60)%60
        let hour = Int(count/3600)
        self.timeButtonOutlet.setTitle(String(format: "%02d:%02d:%02d",hour,minute,second), for: UIControlState())
    }
    
    func pauseStopWatch(){
        if(self.stopWatch != nil){
            self.stopWatch.invalidate()
            self.stopWatch = nil
            self.duration = Date()
        }
    }
    
    func startStopWatch(){
        if(self.duration != nil){
            let newSecond: TimeInterval = Date().timeIntervalSince(self.duration!)
            count = count + lround(newSecond)
            self.stopWatch = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.stopWatchTimer(_:)), userInfo: nil, repeats: true)
        }
    }
    
    func showSpendInfo(){
        let second = count%60
        let minute = (count/60)%60//計算使用時間
        var calMinute = Int(count/60)
        let hour = Int(count/3600)
        let timeInfo = String(format:"%02d:%02d:%02d",hour,minute,second)
        self.timeSpend.text = timeInfo
        
        var cost = 0//計算花費
        switch calMinute{
            case 0..<30: cost = 0 //不滿30分鐘免費
            case 30..<60: cost = 5
            case 60..<90: cost = 15 //90分鐘 10元 + 5元
            default: //90分後每30分20元
                calMinute -= 90
                if calMinute % 30 != 0{
                     calMinute = Int(calMinute/30)+1
                }else{
                    calMinute = Int(calMinute/30)
                }
                cost = 15 + (calMinute*20)
        }
        let costInfo = "NT$ \(cost)"
        self.costSpend.text = costInfo
        self.duration = nil
        
        //spendInfo滑下動畫
        self.spendInfo.isHidden = false
        self.resultButtonOutlet.isHidden = false
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.spendInfo.transform = CGAffineTransform(translationX: 0,y: 0)
            self.resultButtonOutlet.transform = CGAffineTransform(translationX: 0, y: 0)
        },completion: nil)
        
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude , longitude: location.coordinate.longitude)
        self.currentLocation = center
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status{
        case .denied,.restricted:
            requestAgain()
        default:
            break
        }
    }
    
    func checkIfInCity(location user: MKUserLocation){
        //不在範圍內跳出警示
        print("current location:\(user.coordinate.longitude);\(user.coordinate.latitude)")
        if((user.coordinate.longitude < 120.17 || user.coordinate.longitude > 120.43) || (user.coordinate.latitude > 22.91 || user.coordinate.latitude < 22.508)){
            locationManager.stopUpdatingLocation()
            let alert = UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("Range", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func requestAgain(){
        //前往設定APP
        let alert = UIAlertController(title: NSLocalizedString("Title", comment: ""), message: NSLocalizedString("Content", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("SetButton", comment: ""), style: .default, handler: {
            action in
            let url = URL(string: UIApplicationOpenSettingsURLString)
            UIApplication.shared.openURL(url!)
        }))
        alert.addAction(UIAlertAction(title:  NSLocalizedString("OkButton", comment: ""), style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func timeOutAlert(_ notification:Notification){
        //連線逾時AlerView
        let message = (notification as NSNotification).userInfo!["message"] as! String
        let alert = UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
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
            searchableItemAttributeSet.thumbnailData = UIImagePNGRepresentation(UIImage(named:"bike-mark-fill")!)
            
            var keywords = [String]()
            keywords.append(element["StationName"] as! String)
            keywords.append(element["StationAddress"] as! String)
            searchableItemAttributeSet.keywords = keywords
            
            let index = stationData.index(where: {
                return ($0["StationName"] as! String) == (element["StationName"] as! String)
            })
            
            let searchableItem = CSSearchableItem(uniqueIdentifier: "Sparkrs.CityBike.SpotIt.\(String(describing: index))", domainIdentifier: "bike", attributeSet: searchableItemAttributeSet)
            searchableItems.append(searchableItem)
        
            
            
        }
        
        CSSearchableIndex.default().indexSearchableItems(searchableItems, completionHandler: {(error)->Void in
            if(error != nil){
                print(error?.localizedDescription ?? "")
            }
        })
        
    }
    
    override func restoreUserActivityState(_ activity: NSUserActivity) {
        if activity.activityType == CSSearchableItemActionType{
            if let userInfo = activity.userInfo{
                //取得spotlight search裡的 identifier
                let selectedStation = userInfo[CSSearchableItemActivityIdentifier] as! String
                print(selectedStation)
                //將identifier切割取最後一位
                let selectedIndex = Int(selectedStation.components(separatedBy: ".").last!)
                print(selectedIndex ?? 0)
                let stationData = bikePlace.bikeLocationJson()
                print(stationData[selectedIndex!])
                let stationName = stationData[selectedIndex!]["StationName"] as! String
                //將stationname送入senddata以被找出選擇的點
                sendData(stationName)
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        //畫面消失時停止更新位置（節省電量）
        locationManager.stopUpdatingLocation()
        //移除NotificationCenter
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "timeOut"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        //畫面將要出現時啟動更新位置
        locationManager.startUpdatingLocation()
        NotificationCenter.default.addObserver(self, selector: #selector(self.startStopWatch), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.pauseStopWatch), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {}
    
    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
    
    
    @IBAction func locateMe(_ sender: AnyObject) {
        //定位按鈕function實作
        let status = CLLocationManager.authorizationStatus()
        if(status == .authorizedWhenInUse){
            if(self.currentLocation != nil){
                let region = MKCoordinateRegion(center: self.currentLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
                self.mapView.setRegion(region, animated: true)
            }
        }else{
            //取得地理授權
            requestAgain()
        }
    }

    @IBAction func timeButton(_ sender: AnyObject) {
        if timeButtonOutlet.titleLabel?.text == NSLocalizedString("Time_Start", comment: ""){//一開始按下後
            self.timeButtonOutlet.setTitle("00:00:00", for: UIControlState())
            
            self.stopWatch = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.stopWatchTimer(_:)), userInfo: nil, repeats: true)
            self.timeButtonOutlet.backgroundColor = UIColor(red: 255/255, green: 102/255, blue: 153/255, alpha: 1)
            self.timeButtonOutlet.addShadow(UIColor(red: 174/255, green: 23/255, blue: 154/255, alpha: 1))
            self.timeButtonOutlet.addBorder(10.0, thickness: 0, color: self.timeButtonOutlet.backgroundColor!)
            
            //設定Local Notification
            let localNotification = UILocalNotification()
            let pushDate = Date(timeIntervalSinceNow: 1200)
            localNotification.fireDate = pushDate
            localNotification.timeZone = TimeZone.current
            localNotification.soundName = UILocalNotificationDefaultSoundName
            localNotification.alertBody = NSLocalizedString("Twenty_Minutes_Alert", comment: "")
            localNotification.alertTitle = NSLocalizedString("Time_Alert", comment: "")
            localNotification.category = "myCategory"
            UIApplication.shared.scheduleLocalNotification(localNotification)
            
            let finalNotification = UILocalNotification()
            finalNotification.fireDate = Date(timeIntervalSinceNow: 1800)
            finalNotification.timeZone = TimeZone.current
            finalNotification.soundName = UILocalNotificationDefaultSoundName
            finalNotification.alertBody = NSLocalizedString("Thirty_Minutes_Alert", comment: "")
            finalNotification.alertTitle = NSLocalizedString("Time_Alert", comment: "")
            finalNotification.category = "myCategory"
            UIApplication.shared.scheduleLocalNotification(finalNotification)
            
        }else{//結束計時
            self.stopWatch.invalidate()
            self.stopWatch = nil
            self.timeButtonOutlet.setTitle(NSLocalizedString("Time_Start", comment: ""), for: UIControlState())
            self.timeButtonOutlet.backgroundColor = UIColor(red: 23/255, green: 169/255, blue: 174/255, alpha: 1)
            self.timeButtonOutlet.addBorder(10.0, thickness: 0, color: self.timeButtonOutlet.backgroundColor!)
            self.timeButtonOutlet.addShadow(UIColor(red: 23/255, green: 169/255, blue: 174/255, alpha: 1.0))
            
            self.blurView.isHidden = false
            UIApplication.shared.cancelAllLocalNotifications()
            showSpendInfo()
            self.count = 0
        }
        
    }
    @IBAction func doneButton(_ sender: AnyObject) {
        let button = sender as! UIButton
        UIView.animate(withDuration: 0.2, animations: {
            self.spendInfo.transform = CGAffineTransform(translationX: 0, y: -368)
            button.transform = CGAffineTransform(translationX: 0, y: -368)
        },completion: {(completion) -> Void in
            self.spendInfo.isHidden = true
            self.blurView.isHidden = true
            button.isHidden = true
        })
    }
    
}

extension UIView{
    
    func addBorder(_ radius:CGFloat,thickness:CGFloat,color:UIColor){
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.layer.borderWidth = thickness
        self.layer.borderColor = color.cgColor
    }
    
    func addShadow(_ color:UIColor){
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.layer.masksToBounds = false
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.31
    }
}

