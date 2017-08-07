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
    
    //url of c-bike station info
    static let sourceURL: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["infoSourceURL"]!
    //url of c-bike station info english version
    static let engSourceURL: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["infoEngSourceURL"]!
    //url of station list
    static let stationSourceURL: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["stationSourceURL"]!
    //url of version
    static let versionSourceURL: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["versionSourceURL"]!
    
    static func request(_ route: String, completionHandler: ((_ data: Data)->Void)? = nil) {
        Alamofire.request(
            route,
            method: .get
        ).response(completionHandler: { response in
            completionHandler!(response.data!)
        })
    }
}
