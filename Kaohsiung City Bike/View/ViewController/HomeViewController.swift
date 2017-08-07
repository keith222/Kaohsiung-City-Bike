//
//  ViewController.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2015/10/28.
//  Copyright © 2015年 Yang Tun-Kai. All rights reserved.
//
//  站點更新至106-07-16

import UIKit
import MapKit
import SwifterSwift
import WatchConnectivity
import CoreLocation
import PKHUD

//for spotlight search
import CoreSpotlight
import MobileCoreServices

class HomeViewController: UIViewController {

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
    
    fileprivate let locationManager: CLLocationManager = CLLocationManager()
    fileprivate let customAnnotation: MKPointAnnotation = MKPointAnnotation()
    fileprivate var currentLocation: CLLocationCoordinate2D!
    fileprivate var selectedAnnotation: Annotation!
    fileprivate var annoArray: [Annotation]? = [Annotation]()
    fileprivate var currentA: MKAnnotation!
    fileprivate var locateCheck: Bool = true

    fileprivate var timer: Timer!
    fileprivate var stopWatch: Timer!
    fileprivate var count: Int = 0
    fileprivate var stationName: String!
    fileprivate var stationNO: String!
    
    fileprivate var watchSession: WCSession?
    
    fileprivate var longPress: UILongPressGestureRecognizer!
    fileprivate var shortPress: UITapGestureRecognizer!
    
    fileprivate var leftBarButton: UIBarButtonItem!
    fileprivate var rightBarButton: UIBarButtonItem!
    
    fileprivate var duration: Date?
    fileprivate var source: [HomeViewModel]?
    
    lazy var homeViewModel = {
        return HomeViewModel()
    }()
    
    fileprivate var xmlItems:[(staID:String,staName:String,ava:String,unava:String)]?
    
    fileprivate let reachability: Reachability = Reachability()!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Apple Watch
        if(WCSession.isSupported()){
            watchSession = WCSession.default()
            watchSession!.delegate = self
            watchSession!.activate()
        }
        
        //加入NotificationCenter Observer
        self.addNotificationObserver(name: NSNotification.Name(rawValue: "timeOut"), selector: #selector(self.timeOutAlert(_:)))
        
        guard self.reachability.isReachable else {
            UIAlertController(title: "提示", message: "網路連線異常。").show()
            return
        }
        
        
        //設定Delegate
        self.mapView.delegate = self
        self.locationManager.delegate = self
        
        self.setUpUI()
        self.checkData()
        self.requestLocationAuthorization()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        //畫面消失時停止更新位置（節省電量）
        locationManager.stopUpdatingLocation()
        //移除NotificationCenter
        self.removeNotificationsObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //畫面將要出現時啟動更新位置
        locationManager.startUpdatingLocation()
        self.addNotificationObserver(name: NSNotification.Name.UIApplicationDidBecomeActive, selector: #selector(self.startStopWatch))
        self.addNotificationObserver(name: NSNotification.Name.UIApplicationWillResignActive, selector: #selector(self.pauseStopWatch))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToStation"{
            let destination = segue.destination as! StationViewController
            destination.mDelegate = self
        }
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
                let stationNO = self.source?[selectedIndex!].no
                //將stationname送入senddata以被找出選擇的點
                didSelect(stationNO!)
            }
        }
    }
    
    private func checkData(){
        HUD.show(.labeledProgress(title: "", subtitle: NSLocalizedString("Update", comment: "")))
        self.homeViewModel.updateInfoVersion(handler: { [weak self] isUpdated in
            if isUpdated {
                self?.homeViewModel.updateStationInfo(handler: { completed in
                    if completed {
                        self?.setMap()
                    }
                })
            }else{
                self?.setMap()
            }
        })
        
    }
    
    private func requestLocationAuthorization() {
        //確認地理位置請求
        let status = CLLocationManager.authorizationStatus()
        if(status == .authorizedWhenInUse){
            mapView.showsUserLocation = true;
            mapView.userTrackingMode = .follow
            locationManager.startUpdatingLocation()
            //精準度設為100m且移動50公尺才更新位置
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.distanceFilter = CLLocationDistance(50)
        }else{
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private func setMap() {
        self.homeViewModel.fetchStationList(handler: { [weak self] stations in
            self?.source = stations.map{ value -> HomeViewModel in
                return HomeViewModel(data: value)
            }
            
            for element in (self?.source)! {
                let annotation = Annotation()
                annotation.title = (Locale.current.languageCode == "zh") ? element.name : element.englishname
                annotation.coordinate = CLLocationCoordinate2D(latitude: element.latitude , longitude: element.longitude)
                annotation.id = element.id
                annotation.no = element.no
                self?.annoArray?.append(annotation)
            }
            
            HUD.hide()
            self?.setupSearchableContent()
        })
    }
    
    private func setUpUI() {
        //將一些預設在螢幕外
        self.infoView.transform = CGAffineTransform(translationX: 0, y: -310)
        self.spendInfo.transform = CGAffineTransform(translationX: 0, y: -368)
        self.customInfo.transform = CGAffineTransform(translationX: 0, y: -200)
        self.resultButtonOutlet.transform = CGAffineTransform(translationX: 0, y: -368)
        self.timeButtonOutlet.transform = CGAffineTransform(translationX: 0, y: 800)
        self.blurView.backgroundColor = UIColor(patternImage: UIImage(named: "bg-record")!)
        
        //設定UIView,UIButton 邊線及陰影
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
        
        //添加手勢
        self.longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.addAnnotation(_:)))
        //長壓兩秒才有反應
        self.longPress.minimumPressDuration = 1.5
        self.mapView.addGestureRecognizer(longPress)
    }
    
    // spotlight search feature
    private func setupSearchableContent(){
        var searchableItems = [CSSearchableItem]()
        
        for (index, element) in self.source!.enumerated(){//將位置作成Searchable data
            let searchableItemAttributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
            searchableItemAttributeSet.title = element.name
            searchableItemAttributeSet.contentDescription = (Locale.current.languageCode == "zh") ? element.address : element.englishname
            searchableItemAttributeSet.thumbnailData = UIImagePNGRepresentation(UIImage(named:"bike-mark-fill")!)
            
            var keywords = [String]()
            keywords.append(element.name)
            keywords.append(element.address)
            keywords.append(element.englishname)
            searchableItemAttributeSet.keywords = keywords
            
            let searchableItem = CSSearchableItem(uniqueIdentifier: "Sparkrs.CityBike.SpotIt.\(String(describing: index))", domainIdentifier: "bike", attributeSet: searchableItemAttributeSet)
            searchableItems.append(searchableItem)
        }
        
        CSSearchableIndex.default().indexSearchableItems(searchableItems, completionHandler: {(error)->Void in
            if(error != nil){
                print(error?.localizedDescription ?? "")
            }
        })
    }
    
    @objc private func addAnnotation(_ gestureRecognizer: UIGestureRecognizer){
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
        self.shortPress = UITapGestureRecognizer(target: self, action: #selector(self.removeAnnotation(_:)))
        self.mapView.addGestureRecognizer(shortPress)
    }
    
    @objc private func removeAnnotation(_ gestureRecognizer: UIGestureRecognizer){
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
    
    fileprivate func checkIfInCity(location user: MKUserLocation){
        //不在範圍內跳出警示
        print("current location:\(user.coordinate.longitude);\(user.coordinate.latitude)")
        if((user.coordinate.longitude < 120.17 || user.coordinate.longitude > 120.43) || (user.coordinate.latitude > 22.91 || user.coordinate.latitude < 22.508)){
            locationManager.stopUpdatingLocation()
            
            UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("Range", comment: ""), defaultActionButtonTitle: NSLocalizedString("Widget_alert_ok", comment: "")).show()
        }
    }
    
    fileprivate func requestAgain(){
        //前往設定APP
        let alert = UIAlertController(title: NSLocalizedString("Title", comment: ""), message: NSLocalizedString("Content", comment: ""), preferredStyle: .alert)
        alert.addAction(title: NSLocalizedString("SetButton", comment: ""), style: .default, handler: { _ in
            let url = URL(string: UIApplicationOpenSettingsURLString)
            UIApplication.shared.openURL(url!)
        })
        alert.addAction(title: NSLocalizedString("OkButton", comment: ""), style: .default, handler: nil)
        alert.show()
    }
    
    func showRoute(_ currentAnnotation: MKAnnotation){
        let oldOverlays = self.mapView.overlays //記錄舊線條
        
        //設定路徑起始與目的地
        let directionRequest = MKDirectionsRequest()
        directionRequest.source = .forCurrentLocation()
        let destinationPlacemark = MKPlacemark(coordinate: currentAnnotation.coordinate, addressDictionary: nil)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .walking
        
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
            self.mapView.add(route.polyline, level: .aboveRoads)
            self.mapView.removeOverlays(oldOverlays)//移除位置更新後的舊線條
            
            let etaMin = (NSInteger(route.expectedTravelTime)/60) //預估步行時間
            
            if currentAnnotation.isEqual(self.customAnnotation){
                self.customWalkingTimeLabel.text = String(etaMin)
            }else{
                self.travelTimeLabel.text = String(etaMin)
            }
        }
        
        //計算腳踏車行車時間（以Automobile暫代，因Apple Map不提供Bike）
        let bikeRequest = MKDirectionsRequest()
        bikeRequest.source = .forCurrentLocation()
        let bikePlacemark = MKPlacemark(coordinate: currentAnnotation.coordinate, addressDictionary: nil)
        bikeRequest.destination = MKMapItem(placemark: bikePlacemark)
        bikeRequest.transportType = .automobile
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
    
    func bikeInfo(_ timer:Timer){
        self.homeViewModel.fetchStationInfo(handler: { [weak self] data in
            guard data.count > 0 else{ return }
            
            let source: [HomeViewModel] = data.map({value -> HomeViewModel in
                return HomeViewModel(data: value)
            })
            
            let index = source.index(where: {($0.name == self?.stationName) || ($0.no == self?.stationNO)})
            
            //傳送資料到 Apple Watch
            if WCSession.default().isReachable {
                let bikeSession = ["ava" : source[index!].available!, "unava": source[index!].park!]
                let session = WCSession.default()
                session.sendMessage(bikeSession, replyHandler: nil, errorHandler: nil)
            }
        
            DispatchQueue.main.async { _ in
                self?.avaNum.textColor = (source[index!].available < 10) ? UIColor(hexString: "#D54768") : UIColor(hexString: "#5D7778")
                self?.avaNum.text = "\(source[index!].available!)"
                    
                self?.parkNum.textColor = (source[index!].park < 10) ? UIColor(hexString: "#D54768") : UIColor(hexString: "#5D7778")
                self?.parkNum.text = "\(source[index!].park!)"
            }
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
    
    func timeOutAlert(_ notification:Notification){
        //連線逾時AlerView
        let message = (notification as NSNotification).userInfo!["message"] as! String
        UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: message, defaultActionButtonTitle: NSLocalizedString("Widget_alert_ok", comment: "")).show()
        timer.invalidate()
    }
    
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
            self.requestAgain()
        }
    }

    @IBAction func timeButton(_ sender: AnyObject) {
        if timeButtonOutlet.titleLabel?.text == NSLocalizedString("Time_Start", comment: ""){//一開始按下後
            self.timeButtonOutlet.setTitle("00:00:00", for: UIControlState())
            
            self.stopWatch = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.stopWatchTimer(_:)), userInfo: nil, repeats: true)
            self.timeButtonOutlet.backgroundColor = UIColor(red: 255/255, green: 102/255, blue: 153/255, alpha: 1)
            self.timeButtonOutlet.addBorder(10.0, thickness: 0, color: self.timeButtonOutlet.backgroundColor!)
            self.timeButtonOutlet.addShadow(UIColor(red: 174/255, green: 23/255, blue: 154/255, alpha: 1))
            
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

extension HomeViewController: SelectStation {
    
    func didSelect(_ stationNO: String) {
        self.stationNO = stationNO
        
        //將車站列表被點選的站點與地圖上的站點對照
        let filter = self.source?.filter({$0.no == stationNO}).first
        let result = self.mapView.annotations.filter({$0.title! == filter?.name})
        
        self.mapView.removeAnnotation(self.customAnnotation)
        
        //地圖上沒有站點則繪出，有則選擇
        if result.isEmpty{
            let newAnn = self.annoArray!.filter{ $0.no! == stationNO }.first!
            self.mapView.addAnnotation(newAnn)
            self.mapView.selectAnnotation(newAnn, animated: true)
        }else{
            self.mapView.selectAnnotation(result[0], animated: true)
        }
    }
}

extension HomeViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude , longitude: location.coordinate.longitude)
        self.currentLocation = center
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status{
        case .denied,.restricted:
            self.requestAgain()
        default:
            self.locationManager.startUpdatingLocation()
        }
    }
}

extension HomeViewController: MKMapViewDelegate {
    
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
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        //依據現在位置更新導引路線
        if currentA != nil {
            self.showRoute(currentA)
        }
        
        //判斷是否在高雄市內
        if locateCheck {
            locateCheck = false
            checkIfInCity(location: userLocation)
        }
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        if currentA != nil {
            let region = MKCoordinateRegion(center: self.currentA.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
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
            self.mapView.addAnnotations(existAnnotation!)
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
                if self.reachability.isReachable {
                    //啟動timer每五分鐘抓腳踏車資訊
                    Timer.scheduledTimer(timeInterval: 0, target: self, selector: #selector(self.bikeInfo(_:)), userInfo: nil, repeats: false)
                    self.timer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(self.bikeInfo(_:)), userInfo: nil, repeats: true)

                    //infoview滑下及timeButton滑上動畫
                    self.infoView.isHidden = false
                    self.timeButtonOutlet.isHidden = false
                    UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: UIViewAnimationOptions.curveEaseOut, animations: {
                        self.infoView.transform = CGAffineTransform(translationX: 0,y: 0)
                        self.timeButtonOutlet.transform = CGAffineTransform(translationX: 0, y: 0)
                    },completion: nil)
                }else{
                    UIAlertController(title: NSLocalizedString("Alert", comment: ""), message: NSLocalizedString("Error_Log", comment: ""), defaultActionButtonTitle: NSLocalizedString("Widget_alert_ok", comment: "")).show()
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
            
            let region = MKCoordinateRegion(center: view.annotation!.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
            
            if WCSession.default().isReachable == true {
                let locationSession = ["longitude" : annolong!, "latitude": annolati!, "stationName":title!!, "annoType": annoType] as [String : Any]
                let session = WCSession.default()
                session.sendMessage(locationSession as [String : AnyObject], replyHandler:nil, errorHandler: nil)
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
}

extension HomeViewController: WCSessionDelegate {
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    /** Called when all delegate callbacks for the previously selected watch has occurred. The session can be re-activated for the now selected watch using activateSession. */
    @available(iOS 9.3, *)
    public func sessionDidDeactivate(_ session: WCSession) {}
    
    /** Called when the session can no longer be used to modify or add any new transfers and, all interactive messages will be cancelled, but delegate callbacks for background transfers can still occur. This will happen when the selected watch is being changed. */
    @available(iOS 9.3, *)
    public func sessionDidBecomeInactive(_ session: WCSession) {}
}
