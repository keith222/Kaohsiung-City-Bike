//
//  InterfaceController.swift
//  Kaohsiung CityBike WatchApp Extension
//
//  Created by Yang Tun-Kai on 2015/11/29.
//  Copyright © 2015年 Yang Tun-Kai. All rights reserved.
//

import WatchKit
import WatchConnectivity
import MapKit
import Foundation




class InterfaceController: WKInterfaceController,WCSessionDelegate {
    
    @IBOutlet var staNameLabel: WKInterfaceLabel!
    @IBOutlet var unavaLabel: WKInterfaceLabel!
    @IBOutlet var avaLabel: WKInterfaceLabel!
    @IBOutlet var stationMap: WKInterfaceMap!
    var watchSession:WCSession?

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if(WCSession.isSupported()){
            watchSession = WCSession.defaultSession()
            // Add self as a delegate of the session so we can handle messages
            watchSession!.delegate = self
            watchSession!.activateSession()
        }
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {

        let longitude = message["longitude"] as? Double
        let latitude = message["latitude"] as? Double
        let title = message["stationName"] as? String
        let ava = message["ava"] as? String
        let unava = message["unava"] as? String
        
        if(longitude != nil && latitude != nil && title != nil){
            let location = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            let coordinateSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            self.staNameLabel.setText(title)
            self.stationMap.removeAllAnnotations()
            self.stationMap.addAnnotation(location, withImageNamed: "bikepinwatch" ,centerOffset: CGPointMake(0, 0))
            self.stationMap.setRegion(MKCoordinateRegion(center: location, span: coordinateSpan))
        }
        if(ava != nil && unava != nil){
            avaLabel.setText(String(ava!))
            unavaLabel.setText(String(unava!))
            if Int(ava!)<10{
                self.avaLabel.setTextColor( UIColor(red: 232/255, green: 87/255, blue: 134/255, alpha: 1))
            }else{
                self.avaLabel.setTextColor(UIColor.whiteColor())
            }
            if Int(unava!)<10{
                self.unavaLabel.setTextColor(UIColor(red: 232/255, green: 87/255, blue: 134/255, alpha: 1))
            }else{
                self.unavaLabel.setTextColor(UIColor.whiteColor())
            }
        }

    }
}