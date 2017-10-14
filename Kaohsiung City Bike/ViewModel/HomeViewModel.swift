//
//  HomeViewModel.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/26.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import ObjectMapper
import Kanna

class HomeViewModel {
    
    var id: Int!
    var no: String!
    var name: String!
    var englishname: String!
    var latitude: Double!
    var longitude: Double!
    var address: String!
    var description: String!
    
    var available: Int!
    var park: Int!
    
    init(){}
    
    init(data: Station){
        self.id = data.id
        self.no = data.no
        self.name = data.name
        self.englishname = data.englishname
        self.latitude = data.latitude
        self.longitude = data.longitude
        self.address = data.address
        self.description = data.description
    }
    
    init(data: Park){
        self.id = data.id
        self.no = data.no
        self.name = data.name
        self.available = data.available
        self.park = data.park
    }
    
    func fetchStationList(handler: @escaping (([Station]) -> ())){
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let path = doc.appendingPathComponent("citybike.json").path
        
        do {
            let jsonData: Data = try Data(contentsOf: URL(fileURLWithPath: path))
            let json = JSON(data: jsonData)
            let station = json.map({ (station: (String, value: SwiftyJSON.JSON)) -> Station in
                return Mapper<Station>().map(JSONObject: station.value.dictionaryObject)!
            })
            
            handler(station)
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func fetchStationInfo(handler: @escaping ([Park]) -> ()) {
        let url = (Locale.current.languageCode == "zh") ? APIService.sourceURL : APIService.engSourceURL
        APIService.request(url, completionHandler: { data in
            var parks: [Park] = []
            
            do {
                let doc = try XML(xml: data, encoding: .utf8)
                
                for node in doc.xpath("//Station") {
                    let id = Int((node.at_css("StationID")?.text)!)
                    let no = node.at_css("StationNO")?.text
                    let name = node.at_css("StationName")?.text
                    let available = Int((node.at_css("StationNums1")?.text)!)
                    let park = Int((node.at_css("StationNums2")?.text)!)
                    
                    parks.append(Park(JSON: ["id": id!, "no": no!, "name": name!, "available": available!, "park": park!])!)
         
                }
                
            } catch let error as NSError{
                print(error.localizedDescription)
            }
            
            handler(parks)
        })
    }
    
    func updateInfoVersion(handler: @escaping ((Bool)->())) {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let path = doc.appendingPathComponent("version.json")
        do{
            let jsonData: Data = try Data(contentsOf: path)
            let oldJson = JSON(data: jsonData)
            let url = APIService.versionSourceURL
            
            APIService.request(url, completionHandler: { data in
                let newJson = JSON(data: data)
                
                if oldJson["version"] != newJson["version"] {
                    do {
                        try! data.write(to: path)
                        handler(true)
                    }
                }else{
                    handler(false)
                }
            })
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func updateStationInfo(handler: @escaping ((Bool)->())) {
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
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
