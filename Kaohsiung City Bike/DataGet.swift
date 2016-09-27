//
//  DataGet.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2015/11/4.
//  Copyright © 2015年 Yang Tun-Kai. All rights reserved.
//

import Foundation

class DataGet :NSObject,XMLParserDelegate{
    
    func bikeLocationJson()->[[String: AnyObject]]{
        let path:NSString = Bundle.main.path(forResource: "citybike", ofType: "json")! as NSString
        let data:NSData = try! NSData(contentsOfFile: path as String, options: NSData.ReadingOptions.dataReadingMapped)
        let jsonResult = try! JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as! [[String: AnyObject]]
        return jsonResult
    }
}
