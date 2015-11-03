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


class ViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate{

    @IBOutlet var mapView:MKMapView!
    
    
    let locationManager = CLLocationManager();
    var transportType = MKDirectionsTransportType.Walking
    var currentLocation:CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.requestWhenInUseAuthorization();
        let status = CLLocationManager.authorizationStatus();
        if(status == CLAuthorizationStatus.AuthorizedWhenInUse){
            mapView.showsUserLocation = true;
        }
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.startUpdatingLocation()
        locationManager.distanceFilter = CLLocationDistance(100)
        
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last! as CLLocation
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude , longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003))
        mapView.setRegion(region, animated: false)
        currentLocation = center
    
    }
    
    override func viewDidDisappear(animated: Bool) {
        locationManager.stopUpdatingLocation()
    }
    override func viewWillAppear(animated: Bool) {
        locationManager.startUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func locateMe(sender: AnyObject) {
        mapView.showsUserLocation = true
        mapView.delegate = self
        let region = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003))
        mapView.setRegion(region, animated: true)

    }

}

