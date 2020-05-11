//
//  Station.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/25.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation

struct Station: Codable {
    
    let id: Int?
    let no: String?
    let name: String?
    let englishname: String?
    let latitude: Double?
    let longitude: Double?
    let address: String?
    let description: String?
}
