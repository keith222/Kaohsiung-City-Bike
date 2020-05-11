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
            annotation.coordinate = CLLocationCoordinate2D(latitude: station.latitude ?? 0 , longitude: station.longitude ?? 0)
            annotation.id = station.id
            annotation.no = station.no
            self.annotations.append(annotation)
        }
    }
    
    func getAnnotations() -> [Annotation] {
        return annotations
    }
    
    func getAnnotations(at index: Int) -> Annotation {
        return annotations[index]
    }
    
    func getAnnotations(by id: Int) -> Annotation? {
        return annotations.filter({$0.id == id}).first
    }
    
    func getAllStationData() -> [Station] {
        return stations
    }
    
    func getStationData(at index: Int) -> Station {
        return stations[index]
    }
    
    func getStationData(by id: Int) -> Station? {
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
    
    func fetchStationInfo(with stationIDs: [Int], handler: @escaping ([Park]?) -> ()) {
        var url = APIService.sourceURL
        for (index, element) in stationIDs.enumerated() {
            if index != stationIDs.count - 1 {
                url += "StationID%20eq%20'\(element)'%20or%20"
            } else {
                url += "StationID%20eq%20'\(element)'"
            }
        }
        
        let xdate:String = APIService.getServerTime();
        let signDate = "x-date: " + xdate;
        let base64HmacStr = signDate.hmac(algorithm: .SHA1, key: KeysHelper.l1key)
        let authorization: String = "hmac username=\""+KeysHelper.l1id+"\", algorithm=\"hmac-sha1\", headers=\"x-date\", signature=\""+base64HmacStr+"\""
        let headers: HTTPHeaders = ["x-date": xdate,
                                    "Authorization": authorization,
                                    "Accept-Encoding": "gzip"]
        
        APIService.request(url, headers: headers, completionHandler: { data in
            do {
                let park = try JSONDecoder().decode([Park].self, from: data)
                handler(park)
            } catch let error as NSError{
                print(error.localizedDescription)
                handler(nil)
            }
        })
    }
    
    func updateInfoVersion(handler: @escaping (()->())) {
        if let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let path = doc.appendingPathComponent("version.json")
            do{
                let jsonData: Data = try Data(contentsOf: path)
                let oldJson = try JSONDecoder().decode([String:Float].self, from: jsonData)
                let url = APIService.versionSourceURL
                
                APIService.request(url, completionHandler: { [weak self] data in
                    let newJson = try? JSONDecoder().decode([String:Float].self, from: data)
                    
                    if oldJson["version"] != newJson!["version"] {
                        do {
                            try data.write(to: path)
                            self?.updateStationInfo(handler: { result in
                                handler()
                            })
                            
                        } catch {
                            handler()
                        }
                    }else{
                        handler()
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
            
            let url = APIService.stationSourceURL
            APIService.request(url, completionHandler: { data in
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
