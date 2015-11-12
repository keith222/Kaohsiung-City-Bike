//
//  DataGet.swift
//  Kaohsiung City Bike
//
//  Created by Yang Tun-Kai on 2015/11/4.
//  Copyright © 2015年 Yang Tun-Kai. All rights reserved.
//

import Foundation

class DataGet :NSObject,NSXMLParserDelegate{
    
    func bikeLocationJson()->NSMutableArray{
        let path:NSString = NSBundle.mainBundle().pathForResource("citybike", ofType: "json")!
        let data:NSData = try! NSData(contentsOfFile: path as String, options: NSDataReadingOptions.DataReadingMapped)
        let jsonResult = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSMutableArray
        
        return jsonResult
    }
}
