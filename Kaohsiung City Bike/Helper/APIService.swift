//
//  APIService.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2017/7/27.
//  Copyright © 2017年 Yang Tun-Kai. All rights reserved.
//

import Foundation
import Alamofire
import CommonCrypto

class APIService {
    
    //url of c-bike station info
    static let sourceURL: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["sourceURL"]!
    //url of c-bike station info english version
    static let engSourceURL: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["infoEngSourceURL"]!
    //url of station list
    static let stationSourceURL: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["stationSourceURL"]!
    //url of version
    static let versionSourceURL: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["versionSourceURL"]!
    
    static func request(_ route: String, headers: HTTPHeaders = [:], completionHandler: ((_ data: Data)->Void)? = nil) {
        Alamofire.request(
            route,
            method: .get,
            headers: headers
        ).responseData(completionHandler: { response in
            completionHandler!(response.data!)
        })
    }
    
    static func getServerTime() -> String {
        
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "EEE, dd MMM yyyy HH:mm:ww zzz"
        dateFormater.locale = Locale(identifier: "en_US")
        dateFormater.timeZone = TimeZone(secondsFromGMT: 0)
        
        return dateFormater.string(from: Date())
    }
}
