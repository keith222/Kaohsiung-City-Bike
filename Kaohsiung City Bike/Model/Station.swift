//
//  Station.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/25.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation

struct Station: Codable {
    
    let id: String
    let name: String
    let englishname: String
    let geohash: String
    let address: String
}
