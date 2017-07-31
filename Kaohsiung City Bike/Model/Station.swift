//
//  Station.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/25.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import ObjectMapper

struct Station: Mappable {
    
    var id: Int!
    var no: String!
    var name: String!
    var englishname: String!
    var latitude: Double!
    var longitude: Double!
    var address: String!
    var description: String!
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        self.id <- map["id"]
        self.no <- map["no"]
        self.name <- map["name"]
        self.englishname <- map["englishname"]
        self.latitude <- map["latitude"]
        self.longitude <- map["longitude"]
        self.address <- map["address"]
        self.description <- map["description"]
    }
}
