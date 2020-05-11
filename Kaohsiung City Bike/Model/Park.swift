//
//  Park.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/27.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation

struct Park: Codable {
    
    let StationID: String
    let ServiceAvailable: Int
    let AvailableRentBikes: Int
    let AvailableReturnBikes: Int
}
