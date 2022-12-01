//
//  HomeViewModel.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/26.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import Alamofire
import CoreLocation

class HomeViewModel {
    
    private var stations: [Station] = []
    private var annotations: [Annotation] = []
    
    init(){
        initStations()
    }
    
    private func initStations() {
        stations = StationHelper.shared.stations
    }
    
    func setMapAnnotation() {
        for station in stations {
            let annotation = Annotation()
            annotation.title = (Locale.current.languageCode == "zh") ? station.name : station.englishname
            annotation.coordinate = CLLocationCoordinate2D(geohash: station.geohash)
            annotation.id = station.id
            self.annotations.append(annotation)
        }
    }
    
    func getAnnotations() -> [Annotation] {
        return annotations
    }
    
    func getAnnotations(at index: Int) -> Annotation {
        return annotations[index]
    }
    
    func getAnnotations(by id: String) -> Annotation? {
        return annotations.filter({$0.id == id}).first
    }
    
    func getAllStationData() -> [Station] {
        return stations
    }
    
    func getStationData(at index: Int) -> Station {
        return stations[index]
    }
    
    func getStationData(by id: String) -> Station? {
        return stations.filter({$0.id == id}).first
    }
    
    func fetchStationListForWidget() -> [Station] {
        if let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let path = doc.appendingPathComponent("citybike.json").path
            
            do {
                let jsonData: Data = try Data(contentsOf: URL(fileURLWithPath: path))
                let stations = try JSONDecoder().decode([Station].self, from: jsonData)
                return stations
                
            } catch let error {
                print(error.localizedDescription)
                return []
            }
        }
        
        return []
    }
    
    func checkToken(handler: (()->())? = nil) {
        
        guard let userDefaults = UserDefaults(suiteName: "group.kcb.todaywidget") else {
            fetchToken(handler: handler)
            return
        }
        
        let token = userDefaults.string(forKey: "token") ?? ""
        let time = userDefaults.double(forKey: "tokenTime")
        let now = Date().timeIntervalSince1970
        
        guard !token.isEmpty && (now - time) < 86400 else {
            fetchToken(handler: handler)
            return
        }
        
        handler?()
    }
    
    private func fetchToken(handler: (()->())? = nil) {
        let parameters = [
            "grant_type":"client_credentials",
            "client_id": APIService.clientID,
            "client_secret": APIService.clientSecret
        ]
               
        APIService.request(APIService.tokenURL, method: .post, parameters: parameters, completionHandler: { data in
            do {
                let token = try JSONDecoder().decode(Token.self, from: data)
                let timeInterval = Date().timeIntervalSince1970
                UserDefaults(suiteName: "group.kcb.todaywidget")?.setValue(token.accessToken, forKey: "token")
                UserDefaults(suiteName: "group.kcb.todaywidget")?.setValue(timeInterval, forKey: "tokenTime")
                handler?()
                
            } catch let error as NSError{
                print(error.localizedDescription)
            }
        })
        
    }
    
    func fetchStationInfo(with stationIDs: [String], handler: @escaping ([Park]?) -> ()) {
        guard let token = UserDefaults(suiteName: "group.kcb.todaywidget")?.string(forKey: "token"), !token.isEmpty else {
            handler(nil)
            return
        }
        
        let header = ["authorization": "Bearer " + token]
        var url = APIService.sourceURL
        for (index, element) in stationIDs.enumerated() {
            if index != stationIDs.count - 1 {
                url += "StationID%20eq%20'\(element)'%20or%20"
            } else {
                url += "StationID%20eq%20'\(element)'"
            }
        }

        APIService.request(url, method: .get, headers: header, completionHandler: { data in
            do {
                let park = try JSONDecoder().decode([Park].self, from: data)
                handler(park)
            } catch let error as NSError{
                print(error.localizedDescription)
                handler(nil)
            }
        })
    }
    
    func updateInfoVersion(handler: @escaping ((Double)->())) {
        if let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let path = doc.appendingPathComponent("version.json")
            do{
                let jsonData: Data = try Data(contentsOf: path)
                let oldJson = try JSONDecoder().decode([String: Double].self, from: jsonData)
                
                APIService.request(APIService.versionSourceURL, method: .get, completionHandler: { [weak self] data in
                    let newJson = try? JSONDecoder().decode([String: Double].self, from: data)
                    
                    if oldJson["version"] ?? 0.0 < newJson!["version"] ?? 0.0 {
                        do {
                            try data.write(to: path)
                            self?.updateStationInfo(handler: { _ in handler(oldJson["version"] ?? 0) })
                            
                        } catch {
                            handler(oldJson["version"] ?? 0)
                        }
                    }else{
                        handler(oldJson["version"] ?? 0)
                    }
                })
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    func updateStationInfo(handler: @escaping ((Bool)->())) {
        if let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let path = doc.appendingPathComponent("citybike.json")
            APIService.request(APIService.stationSourceURL, method: .get, completionHandler: { data in
                do {
                    try data.write(to: path)
                    handler(true)
                    
                } catch let error {
                    handler(false)
                    print(error.localizedDescription)
                }
            })
        }
    }
}
