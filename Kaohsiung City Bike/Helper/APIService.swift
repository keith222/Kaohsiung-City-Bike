//
//  APIService.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/27.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

class APIService {
    
    static let sourceURL: String = "http://www.c-bike.com.tw/xml/stationlistopendata.aspx"
    static let engSourceURL: String = "http://www.c-bike.com.tw/xml/StationListEnOpenData.aspx"
    
    static func request(_ route: String, completionHandler: ((_ data: Data)->Void)? = nil) {
        Alamofire.request(
            route,
            method: .get
        ).response(completionHandler: { response in
            completionHandler!(response.data!)
        })
    }
}
