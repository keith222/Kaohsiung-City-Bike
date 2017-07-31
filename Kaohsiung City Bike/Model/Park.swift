//
//  Park.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/27.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import ObjectMapper

struct Park: Mappable {
    
    var id: Int!
    var no: String!
    var name: String!
    var available: Int!
    var park: Int!
    
    init?(map: Map) {}
    
    mutating func mapping(map: Map) {
        self.id <- map["id"]
        self.no <- map["no"]
        self.name <- map["name"]
        self.available <- map["available"]
        self.park <- map["park"]
    }
}
