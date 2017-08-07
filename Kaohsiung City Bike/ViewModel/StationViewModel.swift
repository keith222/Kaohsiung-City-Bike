//
//  StationViewModel.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/25.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import ObjectMapper

class StationViewModel {
    
    var id: Int!
    var no: String!
    var name: String!
    var englishname: String!
    var latitude: Double!
    var longitude: Double!
    var address: String!
    var description: String!
    
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
    
    func fetchStationList(handler: @escaping (([Station]) -> ())){
//        let path: String = Bundle.main.path(forResource: "citybike", ofType: "json")!
        let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let path = doc.appendingPathComponent("version.json").path
        
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
}
