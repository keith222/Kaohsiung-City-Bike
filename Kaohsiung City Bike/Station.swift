//
//  Station.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2015/11/4.
//  Copyright © 2015年 Yang Tun-Kai. All rights reserved.
//

import Foundation

class Station {
    var staID:NSInteger = 0
    var name:NSString = ""
    var lon:Double = 0.0
    var lat:Double = 0.0
    var desc:NSString = ""
    
    init(staID:NSInteger, name:NSString, lon:Double, lat:Double, desc:NSString){
        self.staID = staID
        self.name = name
        self.lat = lat
        self.lon = lon
        self.desc = desc
    }
}