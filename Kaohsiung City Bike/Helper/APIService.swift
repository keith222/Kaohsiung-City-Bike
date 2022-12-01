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
    //url of station list
    static let stationSourceURL: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["stationSourceURL"]!
    //url of version
    static let versionSourceURL: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["versionSourceURL"]!
    //url of Youbike resgiter weabsite
    static let registerURL: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["RegisterURL"]!
    //url of token
    static let tokenURL: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["TokenURL"]!
    //client id of token
    static let clientID: String =
    (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["ClientID"]!
    //client key of token
    static let clientSecret: String = (Bundle.main.object(forInfoDictionaryKey: "APIService") as! Dictionary<String, String>)["ClientSecret"]!
    
    static func request(_ route: String, method: HTTPMethod, parameters: Parameters = [:], headers: HTTPHeaders = [:], completionHandler: ((_ data: Data)->Void)? = nil) {
        Alamofire.request(
            route,
            method: method,
            parameters: parameters,
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
