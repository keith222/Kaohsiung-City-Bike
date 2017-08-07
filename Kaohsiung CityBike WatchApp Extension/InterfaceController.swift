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

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if(WCSession.isSupported()){
            watchSession = WCSession.default()
            // Add self as a delegate of the session so we can handle messages
            watchSession!.delegate = self
            watchSession!.activate()
        }
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(watchOS 2.2, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {

        let longitude = message["longitude"] as? Double
        let latitude = message["latitude"] as? Double
        let title = message["stationName"] as? String
        let ava = message["ava"] as? Int
        let unava = message["unava"] as? Int
        let annoType = message["annoType"] as? Int
        
        if(longitude != nil && latitude != nil && title != nil){
            let location = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
            let coordinateSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            self.staNameLabel.setText(title)
            self.stationMap.removeAllAnnotations()
            let imgName = (annoType == 0) ? "locate-pin-custom" : "locate-pin"
            self.stationMap.addAnnotation(location, withImageNamed: imgName ,centerOffset: CGPoint(x: 0, y: 0))
            self.stationMap.setRegion(MKCoordinateRegion(center: location, span: coordinateSpan))
        }
        if(ava != nil && unava != nil){
            print(ava)
            avaLabel.setText(String(ava!))
            unavaLabel.setText(String(unava!))
            if ava! < 10{
                self.avaLabel.setTextColor(UIColor(red: 213/255, green: 71/255, blue: 104/255, alpha: 1))
            }else{
                self.avaLabel.setTextColor(UIColor.white)
            }
            if unava! < 10{
                self.unavaLabel.setTextColor(UIColor(red: 213/255, green: 71/255, blue: 104/255, alpha: 1))
            }else{
                self.unavaLabel.setTextColor(UIColor.white)
            }
        }

    }
}
